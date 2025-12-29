import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query } from "../db.js";

const router = Router();

router.get("/", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const since = typeof req.query.since === "string" ? req.query.since : "1970-01-01T00:00:00Z";
  const rows = await query(
    "SELECT id, entity, entity_id, fields, summary, created_at FROM conflict_logs WHERE tenant_id = $1 AND created_at > $2 ORDER BY created_at DESC",
    [tenantId, since]
  );
  const conflicts = rows.map((row: any) => ({
    id: row.id,
    entity: row.entity,
    entityId: row.entity_id,
    fields: row.fields,
    summary: row.summary,
    createdAt: row.created_at
  }));
  res.json({ conflicts });
});

export default router;
