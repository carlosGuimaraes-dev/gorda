# Comprehensive Analysis - backend

## Architecture Summary
- Express REST API with global auth guard and tenant-aware route handlers.
- Route modules separated by domain: tenants, sync, attachments, notifications, conflicts, audit.

## Security and Access
- JWT verification via Clerk JWKS (`jose`).
- Tenant authorization via `X-Tenant-Id` + membership lookup.
- Manager-only endpoint gate for invite flow.

## Persistence and Sync
- Postgres access through lightweight query helpers in `db.ts`.
- `sync/push` implements upsert/delete semantics with conflict and audit logs.
- `sync/pull` emits ordered changes with cursor.

## Operational Concerns
- Security headers + request id middleware enabled.
- Notification send endpoint has in-memory rate limiter.
- Attachments endpoints currently expose placeholder URLs (integration gap to close).

## Config Surface
- Env vars for DB, Clerk, R2, Meta WhatsApp, Resend.
- `.env.example` documents required runtime keys.
