import { Response, NextFunction } from "express";
import { AuthRequest } from "./auth.js";
import { queryOne } from "../db.js";

export type TenantRequest = AuthRequest & {
  tenant?: { id: string; role: "manager" | "employee"; userId: string };
};

export async function ensureUser(req: AuthRequest): Promise<{ id: string } | null> {
  if (!req.auth) return null;
  const existing = await queryOne<{ id: string }>(
    "SELECT id FROM users WHERE clerk_user_id = $1",
    [req.auth.clerkUserId]
  );
  if (existing) return existing;
  const created = await queryOne<{ id: string }>(
    "INSERT INTO users (clerk_user_id, email, name) VALUES ($1, $2, $3) RETURNING id",
    [req.auth.clerkUserId, req.auth.email ?? null, req.auth.name ?? null]
  );
  return created;
}

export async function requireTenant(req: TenantRequest, res: Response, next: NextFunction) {
  const tenantId = req.header("X-Tenant-Id") ?? "";
  if (!tenantId) {
    res.status(400).json({ error: { code: "MISSING_TENANT", message: "X-Tenant-Id required" } });
    return;
  }
  const user = await ensureUser(req);
  if (!user) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Missing user" } });
    return;
  }
  const membership = await queryOne<{ role: "manager" | "employee" }>(
    "SELECT role FROM memberships WHERE tenant_id = $1 AND user_id = $2 AND status = 'active'",
    [tenantId, user.id]
  );
  if (!membership) {
    res.status(403).json({ error: { code: "FORBIDDEN", message: "No access to tenant" } });
    return;
  }
  req.tenant = { id: tenantId, role: membership.role, userId: user.id };
  next();
}

export function requireManager(req: TenantRequest, res: Response, next: NextFunction) {
  if (req.tenant?.role !== "manager") {
    res.status(403).json({ error: { code: "FORBIDDEN", message: "Manager role required" } });
    return;
  }
  next();
}
