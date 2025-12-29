import { Router } from "express";
import { requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query } from "../db.js";
import crypto from "crypto";

const router = Router();
const rateLimitWindowMs = 60_000;
const rateLimitMax = 10;
const tenantSendTracker = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(tenantId: string): boolean {
  const now = Date.now();
  const entry = tenantSendTracker.get(tenantId);
  if (!entry || entry.resetAt < now) {
    tenantSendTracker.set(tenantId, { count: 1, resetAt: now + rateLimitWindowMs });
    return true;
  }
  if (entry.count >= rateLimitMax) {
    return false;
  }
  entry.count += 1;
  return true;
}

router.post("/:id/send", requireTenant, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  if (!checkRateLimit(tenantId)) {
    res.status(429).json({ error: { code: "RATE_LIMIT", message: "Too many send attempts" } });
    return;
  }
  const invoiceId = req.params.id;
  const channels = Array.isArray(req.body?.channels) ? req.body.channels : [];
  const filtered = channels.filter((channel: string) => channel === "whatsapp" || channel === "email");
  if (filtered.length === 0) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "channels must include whatsapp or email" } });
    return;
  }
  const notificationIds: string[] = [];
  for (const channel of filtered) {
    const id = crypto.randomUUID();
    notificationIds.push(id);
    await query(
      "INSERT INTO notifications (id, tenant_id, entity, entity_id, channel, status) VALUES ($1, $2, $3, $4, $5, $6)",
      [id, tenantId, "finance_entry", invoiceId, channel, "queued"]
    );
  }
  res.json({ status: "queued", notificationIds });
});

export default router;
