# Backend Micro‑Backlog (per endpoint)

## Auth & Tenants
### GET /v1/tenants
- Validate Clerk JWT
- Lookup user by `clerk_user_id`; create if missing
- Return tenant list with role

### POST /v1/tenants
- Validate JWT
- Create tenant
- Create membership for creator as Manager
- Return tenant

### POST /v1/tenants/:id/invite
- Validate JWT + role=manager
- Create membership row with status=invited
- Send invite email (provider TBD)

### POST /v1/tenants/:id/activate
- Validate JWT
- Register device with tenant
- Update device.last_seen_at

## Sync
### POST /v1/sync/push
- Validate JWT + tenant
- Validate payload list
- For each change:
  - If delete: set deleted_at + updated_at
  - If upsert: LWW compare `updated_at` vs `clientUpdatedAt`
  - Record conflicts in `conflict_logs`
  - Write audit_log entries
- Return applied + conflicts

### GET /v1/sync/pull
- Validate JWT + tenant
- Return changes where updated_at > since
- Respect `limit` + nextCursor
- Include deletes (deleted_at != null)

### GET /v1/conflicts
- Validate JWT + tenant
- Return conflicts since timestamp

### GET /v1/audit
- Validate JWT + tenant
- Return audit entries since timestamp

## Attachments (R2)
### POST /v1/attachments/presign
- Validate JWT + tenant
- Create attachment row + r2Key
- Return signed upload URL + attachmentId

### POST /v1/attachments/complete
- Validate JWT + tenant
- Verify object exists in R2
- Link attachment to owner

### GET /v1/attachments/:id/presign
- Validate JWT + tenant
- Generate signed download URL

## Notifications
### POST /v1/invoices/:id/send
- Validate JWT + tenant
- Resolve client + channels (WhatsApp/Email)
- Generate PDF URL (from R2 or PDF service)
- Queue messages per channel
- Create notifications rows (queued)
- Return notificationIds

Notes:
- SMS/iMessage is device-only; backend does not send SMS.

## Shared / Cross‑cutting
- Middleware: Clerk JWT validation (JWKS cache)
- Multi‑tenant guard: `X-Tenant-Id` required
- Input validation: zod/joi
- Observability: request id + structured logs
- Rate limits for notifications
