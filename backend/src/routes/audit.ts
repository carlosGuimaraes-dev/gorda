import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query } from "../db.js";

const router = Router();

router.get("/", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const since = typeof req.query.since === "string" ? req.query.since : "1970-01-01T00:00:00Z";
  const rows = await query(
    "SELECT id, entity, entity_id, action, summary, actor, created_at FROM audit_logs WHERE tenant_id = $1 AND created_at > $2 ORDER BY created_at DESC",
    [tenantId, since]
  );
  const audit = rows.map((row: any) => ({
    id: row.id,
    entity: row.entity,
    entityId: row.entity_id,
    action: row.action,
    summary: row.summary,
    actor: row.actor,
    createdAt: row.created_at
  }));
  res.json({ audit });
});

export default router;
