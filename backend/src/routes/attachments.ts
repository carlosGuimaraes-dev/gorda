import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query, queryOne } from "../db.js";
import crypto from "crypto";
import { createPresignedR2Url, isR2Configured, verifyR2ObjectExists } from "../services/r2.js";

const router = Router();
const uploadUrlTtlSeconds = 900;
const downloadUrlTtlSeconds = 600;

type AttachmentOwnerType = "finance_entry" | "task";

function isOwnerType(value: unknown): value is AttachmentOwnerType {
  return value === "finance_entry" || value === "task";
}

async function ownerExists(tenantId: string, ownerType: AttachmentOwnerType, ownerId: string): Promise<boolean> {
  const table = ownerType === "finance_entry" ? "finance_entries" : "tasks";
  const owner = await queryOne<{ id: string }>(
    `SELECT id FROM ${table} WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL`,
    [ownerId, tenantId]
  );
  return Boolean(owner);
}

router.post("/presign", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const ownerType = req.body?.ownerType;
  const ownerId = typeof req.body?.ownerId === "string" ? req.body.ownerId.trim() : "";
  const mimeType = typeof req.body?.mimeType === "string" ? req.body.mimeType.trim() : "";
  const size = Number(req.body?.size ?? 0);
  if (!isOwnerType(ownerType) || !ownerId || !mimeType || !Number.isFinite(size) || size <= 0) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "ownerType, ownerId, mimeType, size required" } });
    return;
  }
  if (!isR2Configured()) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }
  if (!(await ownerExists(tenantId, ownerType, ownerId))) {
    res.status(404).json({ error: { code: "OWNER_NOT_FOUND", message: "owner not found in tenant scope" } });
    return;
  }
  const attachmentId = crypto.randomUUID();
  const r2Key = `tenants/${tenantId}/attachments/${attachmentId}`;
  await queryOne(
    "INSERT INTO attachments (id, tenant_id, r2_key, mime_type, size, owner_type, owner_id) VALUES ($1, $2, $3, $4, $5, $6, $7)",
    [attachmentId, tenantId, r2Key, mimeType, size, ownerType, ownerId]
  );
  const uploadUrl = createPresignedR2Url("PUT", r2Key, uploadUrlTtlSeconds);
  res.json({ attachmentId, uploadUrl, r2Key, expiresInSeconds: uploadUrlTtlSeconds, method: "PUT" });
});

router.post("/complete", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const attachmentId = typeof req.body?.attachmentId === "string" ? req.body.attachmentId.trim() : "";
  const providedOwnerType = req.body?.ownerType;
  const providedOwnerId = typeof req.body?.ownerId === "string" ? req.body.ownerId.trim() : "";
  const providedR2Key = typeof req.body?.r2Key === "string" ? req.body.r2Key.trim() : "";

  if (!attachmentId) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "attachmentId is required" } });
    return;
  }
  if (!isR2Configured()) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }

  const attachment = await queryOne<{
    id: string;
    r2_key: string;
    owner_type: AttachmentOwnerType;
    owner_id: string;
  }>(
    "SELECT id, r2_key, owner_type, owner_id FROM attachments WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL",
    [attachmentId, tenantId]
  );
  if (!attachment) {
    res.status(404).json({ error: { code: "ATTACHMENT_NOT_FOUND", message: "Attachment not found for tenant" } });
    return;
  }

  if (providedR2Key && providedR2Key !== attachment.r2_key) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "r2Key does not match attachment" } });
    return;
  }

  const ownerType = isOwnerType(providedOwnerType) ? providedOwnerType : attachment.owner_type;
  const ownerId = providedOwnerId || attachment.owner_id;
  if (!(await ownerExists(tenantId, ownerType, ownerId))) {
    res.status(404).json({ error: { code: "OWNER_NOT_FOUND", message: "owner not found in tenant scope" } });
    return;
  }

  let objectExists = false;
  try {
    objectExists = await verifyR2ObjectExists(attachment.r2_key);
  } catch {
    res.status(502).json({ error: { code: "R2_UNREACHABLE", message: "Could not verify uploaded object in R2" } });
    return;
  }
  if (!objectExists) {
    res.status(400).json({ error: { code: "UPLOAD_INCOMPLETE", message: "Attachment object not found in R2" } });
    return;
  }

  await query(
    "UPDATE attachments SET owner_type = $1, owner_id = $2 WHERE id = $3 AND tenant_id = $4",
    [ownerType, ownerId, attachmentId, tenantId]
  );

  if (ownerType === "finance_entry") {
    await query(
      "UPDATE finance_entries SET receipt_attachment_id = $1, updated_at = now() WHERE id = $2 AND tenant_id = $3",
      [attachmentId, ownerId, tenantId]
    );
  }

  res.json({ ok: true, attachmentId, ownerType, ownerId });
});

router.get("/:id/presign", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  const attachmentId = req.params.id;
  if (!isR2Configured()) {
    res.status(503).json({ error: { code: "R2_NOT_CONFIGURED", message: "R2 env vars missing" } });
    return;
  }
  const attachment = await queryOne<{ id: string; r2_key: string }>(
    "SELECT id, r2_key FROM attachments WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL",
    [attachmentId, tenantId]
  );
  if (!attachment) {
    res.status(404).json({ error: { code: "ATTACHMENT_NOT_FOUND", message: "Attachment not found for tenant" } });
    return;
  }

  const downloadUrl = createPresignedR2Url("GET", attachment.r2_key, downloadUrlTtlSeconds);
  res.json({ downloadUrl, r2Key: attachment.r2_key, expiresInSeconds: downloadUrlTtlSeconds, method: "GET" });
});

export default router;
