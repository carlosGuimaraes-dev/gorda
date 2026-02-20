# API Contracts - backend

## Base
- Base prefix: `/v1`
- Auth: `Authorization: Bearer <clerk_jwt>`
- Tenant scope: `X-Tenant-Id` required for tenant-scoped endpoints
- Health check: `GET /health`

## Tenants
- `GET /v1/tenants`
  - Lists tenant memberships for authenticated user.
- `POST /v1/tenants`
  - Creates tenant and sets creator as manager.
- `POST /v1/tenants/:id/invite`
  - Manager-only invite creation.
- `POST /v1/tenants/:id/activate`
  - Registers/refreshes active device session.

## Sync
- `POST /v1/sync/push`
  - Applies upserts/deletes with local-priority conflict logging.
  - Entities: `client`, `employee`, `service_type`, `task`, `finance_entry`.
- `GET /v1/sync/pull?since=<iso>&limit=<n>`
  - Returns incremental changes and next cursor.

## Attachments
- `POST /v1/attachments/presign`
  - Creates attachment metadata and returns upload placeholder payload.
- `POST /v1/attachments/complete`
  - Finalizes upload association (currently placeholder behavior).
- `GET /v1/attachments/:id/presign`
  - Returns download placeholder payload.

## Notifications / Invoices
- `POST /v1/invoices/:id/send`
  - Channels accepted: `whatsapp`, `email`.
  - In-memory per-tenant rate limit: 10 sends per minute.

## Audit and Conflict Logs
- `GET /v1/conflicts?since=<iso>`
- `GET /v1/audit?since=<iso>`

## Error Model
- Standard envelope: `{ error: { code, message } }`
- Common status codes: `400`, `401`, `403`, `429`, `500`, `503`
