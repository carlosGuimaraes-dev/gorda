# Backend Architecture (Planned)

## Status
No backend is implemented yet. This document describes the intended backend responsibilities and integration points.

## Goals
- Provide multi-device sync for offline-first data.
- Preserve local-first UX with conflict visibility.
- Support Manager/Employee roles and auditability.
- Support multi-tenant accounts from v1.

## Core Services (Planned)
- Auth: Clerk (JWTs with Manager/Employee role claims).
- Sync: pull/push changes for offline queue.
- Data APIs: CRUD for Clients, Employees, Service Types, Tasks, Finance Entries.
- Conflict Log: store conflict records for visibility in the app.
- Attachments: receipts and invoice PDFs stored in Cloudflare R2.
- Notifications: WhatsApp/SMS/Email delivery handled by backend in v1.

## Data Model (High Level)
- Client
- Employee
- ServiceType
- ServiceTask (with clientId, employeeId)
- FinanceEntry (with clientId, employeeId, kind, status, currency)
- ConflictLogEntry (entity, fields, timestamps, resolution status)

## Multi-tenant Schema (Proposed)
Single shared schema with `tenant_id` on every domain table.

- tenants
  - id (uuid), name, created_at
- users
  - id (uuid), clerk_user_id, email, name, created_at
- memberships
  - tenant_id, user_id, role (manager/employee), status, created_at
- devices
  - id, tenant_id, user_id, platform, last_seen_at
- domain tables (all include tenant_id, created_at, updated_at, deleted_at)
  - clients, employees, service_types, tasks, finance_entries, teams
  - attachments (r2_key, mime_type, size, owner_type, owner_id)
  - conflict_logs (entity, entity_id, fields, summary, created_at)
  - audit_logs (entity, entity_id, action, summary, actor, created_at)

Notes:
- `deleted_at` enables soft delete for sync (op=delete).
- `updated_at` is the sync cursor. Client wins (LWW), conflicts still recorded.

## Sync Flow (Planned)
1. Client sends local pending changes with timestamps and device id.
2. Server validates and applies changes.
3. If conflict: store a conflict record and return a warning.
4. Client logs conflict locally and displays a badge in Settings.

## Conflict Policy
- Merge with local priority (client wins / last-write-wins), but conflict must be logged for review.
- Conflicts are visible to Manager.

## Auth & Tenant Selection
- Clerk JWT used for auth (Authorization: Bearer <jwt>).
- Backend resolves memberships by `clerk_user_id`.
- Client selects active tenant via `X-Tenant-Id` header (or a tenant selection endpoint).
- Role comes from membership (Manager/Employee).

## API Surface (v1 - Proposed)
### Tenants / Memberships
- GET /v1/tenants
- POST /v1/tenants (create tenant)
- POST /v1/tenants/:id/invite (invite user, Manager only)
- POST /v1/tenants/:id/activate (set active tenant for device/session)

### Sync
- POST /v1/sync/push
  - body: { deviceId, changes: [{ op, entity, entityId, clientUpdatedAt, payload }] }
- GET /v1/sync/pull?since=<timestamp>&limit=<n>
  - returns: { serverTime, changes: [{ op, entity, entityId, updatedAt, payload }], nextCursor }
- GET /v1/conflicts?since=<timestamp>
- GET /v1/audit?since=<timestamp>

### Domain CRUD (optional for admin tooling)
- /v1/clients, /v1/employees, /v1/service-types, /v1/tasks, /v1/finance-entries

### Attachments (R2)
- POST /v1/attachments/presign (upload)
- POST /v1/attachments/complete (link to finance entry)
- GET /v1/attachments/:id/presign (download)

### Notifications
- POST /v1/invoices/:id/send { channels: ["whatsapp","sms","email"] }

## Deployment Decisions (2025-12-29)
- Backend runtime: Node.js + TypeScript.
- Database: Postgres.
- Hosting: Vercel.
- Environments: Dev + Prod.
- User creation: Manager invite only.
- Multi-tenant: Enabled in v1.
- Consistency: Eventual (sync-first).
- R2 access: Signed URLs for all attachments.
- Notifications: Enabled in v1 (WhatsApp/SMS/Email).

## Security
- TLS required.
- Tokens stored in Keychain on device.
- Sensitive fields encrypted at rest on backend (contacts, notes, documents).

## Open Decisions
- Notification provider selection (WhatsApp via Meta, SMS, Email).

## References
- `docs/backend-api-contract.md` (payloads + examples)
- `docs/backend-schema.sql` (Postgres schema + indexes)
- `docs/backend-sprint-plan.md` (Auth/Sync/R2/Notifications rollout)
- `docs/backend-openapi.yaml` (OpenAPI v1)
