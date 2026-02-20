import { Router } from "express";
import { requireTenant, requireManager, ensureUser, TenantRequest } from "../middleware/tenant.js";
import { AuthRequest } from "../middleware/auth.js";
import { query, queryOne } from "../db.js";

const router = Router();

router.get("/", async (req, res) => {
  const authReq = req as AuthRequest;
  const user = await ensureUser(authReq);
  if (!user) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Missing user" } });
    return;
  }
  const tenants = await query<{ id: string; name: string; role: "manager" | "employee" }>(
    `SELECT t.id, t.name, m.role
     FROM memberships m
     JOIN tenants t ON t.id = m.tenant_id
     WHERE m.user_id = $1 AND m.status = 'active'
     ORDER BY t.created_at DESC`,
    [user.id]
  );
  res.json({ tenants });
});

router.post("/", async (req, res) => {
  const authReq = req as AuthRequest;
  const user = await ensureUser(authReq);
  if (!user) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Missing user" } });
    return;
  }
  const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
  if (!name) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "name is required" } });
    return;
  }
  const tenant = await queryOne<{ id: string; name: string }>(
    "INSERT INTO tenants (name) VALUES ($1) RETURNING id, name",
    [name]
  );
  if (!tenant) {
    res.status(500).json({ error: { code: "INTERNAL", message: "Failed to create tenant" } });
    return;
  }
  await queryOne(
    "INSERT INTO memberships (tenant_id, user_id, role, status) VALUES ($1, $2, 'manager', 'active')",
    [tenant.id, user.id]
  );
  res.json({ id: tenant.id, name: tenant.name, role: "manager" });
});

router.post("/:id/invite", requireTenant, requireManager, async (req: TenantRequest, res) => {
  const tenantId = req.params.id;
  if (tenantId !== req.tenant?.id) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "Tenant mismatch" } });
    return;
  }
  const email = typeof req.body?.email === "string" ? req.body.email.trim() : "";
  const role = req.body?.role === "manager" ? "manager" : "employee";
  if (!email) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "email is required" } });
    return;
  }
  const invite = await queryOne<{ id: string }>(
    "INSERT INTO invites (tenant_id, email, role, status, expires_at) VALUES ($1, $2, $3, 'pending', now() + interval '7 days') RETURNING id",
    [tenantId, email, role]
  );
  res.json({ inviteId: invite?.id ?? null, status: "sent" });
});

router.post("/:id/activate", requireTenant, async (req: TenantRequest, res) => {
  const authReq = req as AuthRequest;
  const user = await ensureUser(authReq);
  if (!user) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Missing user" } });
    return;
  }
  const tenantId = req.params.id;
  if (tenantId !== req.tenant?.id) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "Tenant mismatch" } });
    return;
  }
  const deviceId = typeof req.body?.deviceId === "string" ? req.body.deviceId : "";
  const platform = typeof req.body?.platform === "string" ? req.body.platform : "ios";
  if (!deviceId) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "deviceId is required" } });
    return;
  }
  await queryOne(
    "INSERT INTO devices (id, tenant_id, user_id, platform, last_seen_at) VALUES ($1, $2, $3, $4, now()) ON CONFLICT (id) DO UPDATE SET last_seen_at = now()",
    [deviceId, tenantId, user.id, platform]
  );
  res.json({ ok: true });
});

export default router;
