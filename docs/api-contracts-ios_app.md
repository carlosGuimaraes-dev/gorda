# API Contracts - ios_app

## Current Integration Status
- iOS app is offline-first and currently does not ship a concrete URLSession API client.
- Sync behavior is staged in `OfflineStore.syncPendingChanges()` as a stub.

## Intended Backend Contracts (consumed conceptually)
- `POST /v1/sync/push`
- `GET /v1/sync/pull`
- `GET /v1/conflicts`
- `GET /v1/audit`
- `POST /v1/invoices/:id/send`

## Local Contract Surface
- `OfflineStore` methods operate as the internal API for the UI:
  - Auth/session: `login`, `logout`
  - Domain mutations: add/update/delete for clients, employees, tasks, finance, service types
  - Finance workflows: invoice generation, payroll generation, dispute/reissue
  - Sync façade: `syncPendingChanges` with pending queue semantics
