# Architecture - backend

## Executive Summary
Tenant-scoped Express API written in TypeScript. It provides authentication-protected endpoints for tenant membership, offline sync operations, conflict/audit visibility, attachments metadata, and invoice notification dispatch.

## Technology Stack
- TypeScript + Node.js (ES modules)
- Express 4
- Postgres (`pg`)
- Clerk JWT verification (`jose`)

## Architecture Pattern
- Layered route/middleware pattern:
  - `server.ts` boot
  - `app.ts` composition
  - middleware for auth/security/tenant
  - route modules by domain

## Data Architecture
- Multi-tenant schema with `tenant_id` on all domain tables.
- Sync-safe table design with `updated_at` and soft-deletes where relevant.
- Domain entities: clients, employees, service types, tasks, finance entries, attachments, conflict logs, audit logs.

## API Design
- `/v1/*` namespace with bearer auth gate.
- Domain route modules mounted under:
  - `/v1/tenants`
  - `/v1/sync`
  - `/v1/attachments`
  - `/v1/invoices`
  - `/v1/conflicts`
  - `/v1/audit`

## Security
- Clerk JWT verification via JWKS.
- Tenant authorization by membership lookup.
- Security headers + request correlation id middleware.

## Deployment and Operations
- Intended host: Vercel.
- Provider integrations: Postgres, R2, Meta WhatsApp, Resend.
- Health endpoint: `/health`.

## Testing Strategy
- Current codebase has no automated test suite committed.
- Recommended: integration tests for middleware/auth and sync route behavior.
