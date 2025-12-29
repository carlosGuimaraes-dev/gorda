import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query, queryOne } from "../db.js";

const router = Router();

type EntityConfig = {
  table: string;
  columns: Record<string, string>;
  required: string[];
};

const entityConfigs: Record<string, EntityConfig> = {
  client: {
    table: "clients",
    columns: {
      name: "name",
      contact: "contact",
      address: "address",
      propertyDetails: "property_details",
      phone: "phone",
      whatsappPhone: "whatsapp_phone",
      email: "email",
      accessNotes: "access_notes",
      preferredSchedule: "preferred_schedule"
    },
    required: ["name"]
  },
  employee: {
    table: "employees",
    columns: {
      name: "name",
      roleTitle: "role_title",
      team: "team",
      phone: "phone",
      hourlyRate: "hourly_rate",
      currency: "currency",
      extraEarningsDescription: "extra_earnings_description",
      documentsDescription: "documents_description"
    },
    required: ["name"]
  },
  service_type: {
    table: "service_types",
    columns: {
      name: "name",
      description: "description",
      basePrice: "base_price",
      currency: "currency"
    },
    required: ["name", "basePrice", "currency"]
  },
  task: {
    table: "tasks",
    columns: {
      title: "title",
      date: "date",
      startTime: "start_time",
      endTime: "end_time",
      status: "status",
      assignedEmployeeId: "assigned_employee_id",
      clientId: "client_id",
      clientName: "client_name",
      address: "address",
      notes: "notes",
      serviceTypeId: "service_type_id",
      checkInTime: "check_in_time",
      checkOutTime: "check_out_time"
    },
    required: ["title", "date", "status"]
  },
  finance_entry: {
    table: "finance_entries",
    columns: {
      title: "title",
      amount: "amount",
      type: "type",
      dueDate: "due_date",
      status: "status",
      method: "method",
      currency: "currency",
      clientId: "client_id",
      clientName: "client_name",
      employeeId: "employee_id",
      employeeName: "employee_name",
      kind: "kind",
      isDisputed: "is_disputed",
      disputeReason: "dispute_reason",
      receiptAttachmentId: "receipt_attachment_id"
    },
    required: ["title", "amount", "type", "dueDate", "status", "currency", "kind"]
  }
};

function getConfig(entity: string): EntityConfig | null {
  return entityConfigs[entity] ?? null;
}

function hasRequiredFields(payload: Record<string, unknown>, required: string[]): boolean {
  return required.every((field) => payload[field] !== undefined && payload[field] !== null && payload[field] !== "");
}

async function recordConflict(
  tenantId: string,
  entity: string,
  entityId: string,
  summary: string
) {
  await query(
    "INSERT INTO conflict_logs (tenant_id, entity, entity_id, fields, summary) VALUES ($1, $2, $3, $4, $5)",
    [tenantId, entity, entityId, [], summary]
  );
}

async function recordAudit(
  tenantId: string,
  entity: string,
  entityId: string,
  action: string,
  actor: string,
  summary: string
) {
  await query(
    "INSERT INTO audit_logs (tenant_id, entity, entity_id, action, summary, actor) VALUES ($1, $2, $3, $4, $5, $6)",
    [tenantId, entity, entityId, action, summary, actor]
  );
}

function buildUpsertSQL(config: EntityConfig) {
  const columnEntries = Object.entries(config.columns);
  const columnNames = columnEntries.map(([, db]) => db);
  const insertColumns = ["id", "tenant_id", ...columnNames, "updated_at", "deleted_at"];
  const updateAssignments = columnNames.map((col) => `${col} = EXCLUDED.${col}`);
  updateAssignments.push("updated_at = now()", "deleted_at = NULL");
  return {
    insertColumns,
    updateAssignments: updateAssignments.join(", ")
  };
}

router.post("/push", requireTenant, async (req: TenantRequest, res) => {
  const { changes } = req.body ?? {};
  if (!Array.isArray(changes)) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "changes must be an array" } });
    return;
  }
  const applied: string[] = [];
  const conflicts: Array<{ entity: string; entityId: string; summary: string }> = [];
  const tenantId = req.tenant!.id;
  const actor = req.auth?.name ?? req.auth?.clerkUserId ?? "system";

  for (const change of changes) {
    const op = change?.op;
    const entity = change?.entity;
    const entityId = change?.entityId;
    const clientUpdatedAt = change?.clientUpdatedAt;
    const payload = change?.payload ?? {};

    if (!op || !entity || !entityId || !clientUpdatedAt) {
      continue;
    }

    const config = getConfig(entity);
    if (!config) {
      continue;
    }

    const existing = await queryOne<{ updated_at: string }>(
      `SELECT updated_at FROM ${config.table} WHERE id = $1 AND tenant_id = $2`,
      [entityId, tenantId]
    );
    if (existing && new Date(existing.updated_at) > new Date(clientUpdatedAt)) {
      const summary = `Server updated after client timestamp; client overwrite applied.`;
      conflicts.push({ entity, entityId, summary });
      await recordConflict(tenantId, entity, entityId, summary);
    }

    if (op === "delete") {
      await query(
        `UPDATE ${config.table} SET deleted_at = now(), updated_at = now() WHERE id = $1 AND tenant_id = $2`,
        [entityId, tenantId]
      );
      await recordAudit(tenantId, entity, entityId, "deleted", actor, `Deleted ${entity}`);
      applied.push(entityId);
      continue;
    }

    if (!hasRequiredFields(payload, config.required)) {
      continue;
    }

    const { insertColumns, updateAssignments } = buildUpsertSQL(config);
    const values: unknown[] = [entityId, tenantId];
    for (const [apiField] of Object.entries(config.columns)) {
      values.push(payload[apiField] ?? null);
    }
    values.push(new Date().toISOString(), null);

    const placeholders = insertColumns.map((_, idx) => `$${idx + 1}`).join(", ");
    const sql = `INSERT INTO ${config.table} (${insertColumns.join(", ")}) VALUES (${placeholders})
      ON CONFLICT (id) DO UPDATE SET ${updateAssignments}`;
    await query(sql, values);
    await recordAudit(tenantId, entity, entityId, "upserted", actor, `Upserted ${entity}`);
    applied.push(entityId);
  }

  res.json({ serverTime: new Date().toISOString(), applied, conflicts });
});

router.get("/pull", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const since = typeof req.query.since === "string" ? req.query.since : "1970-01-01T00:00:00Z";
  const limit = Math.min(parseInt(String(req.query.limit ?? "500"), 10) || 500, 2000);

  const changes: Array<{
    op: "upsert" | "delete";
    entity: string;
    entityId: string;
    updatedAt: string;
    payload?: Record<string, unknown>;
  }> = [];

  for (const [entity, config] of Object.entries(entityConfigs)) {
    const rows = await query<Record<string, unknown>>(
      `SELECT * FROM ${config.table} WHERE tenant_id = $1 AND updated_at > $2 ORDER BY updated_at ASC LIMIT $3`,
      [tenantId, since, limit]
    );
    for (const row of rows) {
      const updatedAt = String(row.updated_at ?? new Date().toISOString());
      const deletedAt = row.deleted_at as string | null;
      if (deletedAt) {
        changes.push({ op: "delete", entity, entityId: String(row.id), updatedAt });
        continue;
      }
      const payload: Record<string, unknown> = {};
      for (const [apiField, dbField] of Object.entries(config.columns)) {
        payload[apiField] = row[dbField] ?? null;
      }
      changes.push({ op: "upsert", entity, entityId: String(row.id), updatedAt, payload });
    }
  }

  changes.sort((a, b) => new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime());
  const limited = changes.slice(0, limit);
  const nextCursor = limited.length > 0 ? limited[limited.length - 1].updatedAt : since;

  res.json({ serverTime: new Date().toISOString(), changes: limited, nextCursor });
});

export default router;
