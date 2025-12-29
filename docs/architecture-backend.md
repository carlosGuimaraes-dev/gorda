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

## Sync Flow (Planned)
1. Client sends local pending changes with timestamps and device id.
2. Server validates and applies changes.
3. If conflict: store a conflict record and return a warning.
4. Client logs conflict locally and displays a badge in Settings.

## Conflict Policy
- Merge with local priority (client wins / last-write-wins), but conflict must be logged for review.
- Conflicts are visible to Manager.

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
- Schema naming conventions for tenants (schema-per-tenant vs tenant_id).
- Notification provider selection (WhatsApp via Meta, SMS, Email).
