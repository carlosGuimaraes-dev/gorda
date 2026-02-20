# Component Inventory - backend

## Core Components
- App composition: `app.ts`, `server.ts`
- Config: `env.ts`
- Database access: `db.ts`
- Auth provider adapter: `auth/clerk.ts`

## Middleware Components
- `requireAuth` (bearer token validation)
- `requireTenant` / `requireManager` (tenant-role access)
- `securityHeaders` and `requestId`

## Route Components
- `tenants.ts`
- `sync.ts`
- `attachments.ts`
- `notifications.ts`
- `conflicts.ts`
- `audit.ts`
