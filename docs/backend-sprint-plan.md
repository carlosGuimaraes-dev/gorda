# Backend Sprint Plan (Auth + Sync + R2 + Notifications)

## Execution Status (2026-02-20)
- Sprint 1: ✅ Concluído
- Sprint 2: 🟡 Parcial (backend pronto; integração iOS pendente)
- Sprint 3: ✅ Concluído (attachments com URLs assinadas e validação de upload no R2)
- Sprint 4: ✅ Concluído (envio via WhatsApp/Email implementado com atualização de status; requer credenciais provider)

## Sprint 1 — Auth + Tenant Foundation
**Goal:** Clerk auth integrated, tenant + membership model in place.
- Set up Vercel project + environment config
- Implement Clerk JWT verification (JWKS)
- Create tenant & membership endpoints
- Store users + memberships on first login
- Device registration endpoint

**Deliverables:**
- /v1/tenants, /v1/tenants/:id/invite, /v1/tenants/:id/activate
- DB tables: tenants, users, memberships, devices

## Sprint 2 — Sync Core (LWW)
**Goal:** Push/pull works for offline-first data.
- Implement /v1/sync/push (LWW, conflict log)
- Implement /v1/sync/pull (cursor, pagination)
- Conflict log endpoint
- Audit log endpoint
- Soft delete rules

**Deliverables:**
- /v1/sync/push, /v1/sync/pull, /v1/conflicts, /v1/audit
- DB tables: conflict_logs, audit_logs

## Sprint 3 — R2 Attachments
**Goal:** Signed uploads/downloads, attachment linkage.
- Presigned upload URL
- Complete/upload confirmation
- Presigned download URL

**Deliverables:**
- /v1/attachments/presign, /v1/attachments/complete, /v1/attachments/:id/presign
- DB table: attachments

## Sprint 4 — Notifications
**Goal:** Invoice sending via WhatsApp/SMS/Email.
- Provider selection + credentials config
- Send invoice endpoint
- Delivery status tracking

**Deliverables:**
- /v1/invoices/:id/send
- DB table: notifications

## Notes
- All endpoints require `Authorization: Bearer <clerk_jwt>` and `X-Tenant-Id`.
- Rate limit notification sends.
- Ensure all writes are tenant-scoped.
