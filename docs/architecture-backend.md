# Backend Architecture (Planned)

## Status
No backend is implemented yet. This document describes the intended backend responsibilities and integration points.

## Goals
- Provide multi-device sync for offline-first data.
- Preserve local-first UX with conflict visibility.
- Support Manager/Employee roles and auditability.

## Core Services (Planned)
- Auth: session tokens and role claims (Manager/Employee).
- Sync: pull/push changes for offline queue.
- Data APIs: CRUD for Clients, Employees, Service Types, Tasks, Finance Entries.
- Conflict Log: store conflict records for visibility in the app.

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
- Merge with local priority (client wins), but conflict must be logged for review.
- Conflicts are visible to Manager.

## Security
- TLS required.
- Tokens stored in Keychain on device.
- Sensitive fields encrypted at rest on backend (contacts, notes, documents).

## Open Decisions
- Hosting (AWS vs managed services).
- Database (Postgres vs managed NoSQL).
- Auth provider (custom vs Cognito/Clerk).
- File storage for receipt images (S3-like).
