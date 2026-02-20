# Data Models - backend

## Core Multi-tenant Tables
- `tenants`, `users`, `memberships`, `invites`, `devices`

## Domain Tables
- `clients`
- `employees`
- `service_types`
- `tasks`
- `finance_entries`
- `attachments`
- `conflict_logs`
- `audit_logs`
- `notifications`

## Shared Model Traits
- Tenant isolation through `tenant_id`.
- Incremental sync support through `updated_at` and soft deletes (`deleted_at` where applicable).
- Enum-driven domain constraints for role, task status, finance type/status/kind, currency, payment method, notification channel/status.

## Relationship Highlights
- `memberships(tenant_id,user_id)` binds users to tenant role.
- `tasks` references `employees`, `clients`, `service_types`.
- `finance_entries` references `clients`, `employees`; supports dispute and supersession fields.
- `attachments` associates uploaded objects to domain owner type/id.

## Sync-oriented Upsert Mapping
- `sync.ts` maps API payload fields to DB columns per entity config.
- Required fields are enforced per entity before upsert.
- Conflict events are persisted when server timestamps are newer.
