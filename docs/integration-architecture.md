# Integration Architecture

## Repository Type
- Multi-part monorepo with:
  - `backend` (REST API service)
  - `ios_app` (SwiftUI mobile client)

## Integration Points
1. `ios_app -> backend` (REST, planned/partial)
- Purpose: sync local queue and retrieve server changes.
- Backend endpoints: `/v1/sync/push`, `/v1/sync/pull`, `/v1/conflicts`, `/v1/audit`.
- Auth model: Clerk bearer token + `X-Tenant-Id`.

2. `ios_app -> backend` (invoice dispatch workflows)
- Purpose: send invoice notifications (WhatsApp/email).
- Endpoint: `/v1/invoices/:id/send`.

3. `backend -> external services`
- Postgres for persistence.
- Cloudflare R2 for attachment/object storage.
- Meta WhatsApp Cloud API and Resend for outbound communications.

## Data Flow Summary
- Local-first writes in iOS create pending changes.
- Sync bridge sends delta payloads to backend.
- Backend applies upserts/deletes, logs audit/conflicts, and exposes pull cursor.
- iOS consumes conflict/audit summaries for user visibility.
