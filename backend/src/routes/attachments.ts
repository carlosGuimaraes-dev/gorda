import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { queryOne } from "../db.js";
import { env } from "../env.js";
import crypto from "crypto";

const router = Router();

router.post("/presign", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const { ownerType, ownerId, mimeType, size } = req.body ?? {};
  if (!ownerType || !ownerId || !mimeType || !size) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "ownerType, ownerId, mimeType, size required" } });
    return;
  }
  if (!env.r2Endpoint || !env.r2AccessKeyId || !env.r2SecretAccessKey || !env.r2Bucket) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }
  const attachmentId = crypto.randomUUID();
  const r2Key = `tenants/${tenantId}/attachments/${attachmentId}`;
  await queryOne(
    "INSERT INTO attachments (id, tenant_id, r2_key, mime_type, size, owner_type, owner_id) VALUES ($1, $2, $3, $4, $5, $6, $7)",
    [attachmentId, tenantId, r2Key, mimeType, size, ownerType, ownerId]
  );
  res.json({ attachmentId, uploadUrl: "", r2Key });
});

router.post("/complete", requireTenant, async (req: TenantRequest, res) => {
  if (!env.r2Endpoint || !env.r2AccessKeyId || !env.r2SecretAccessKey || !env.r2Bucket) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }
  res.json({ ok: true });
});

router.get("/:id/presign", requireTenant, async (req: TenantRequest, res) => {
  if (!env.r2Endpoint || !env.r2AccessKeyId || !env.r2SecretAccessKey || !env.r2Bucket) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }
  res.json({ downloadUrl: "" });
});

export default router;
