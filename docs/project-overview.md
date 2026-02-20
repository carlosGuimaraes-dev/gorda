# Project Overview

## Project
AG Home Organizer International is a service-management platform combining a native iOS application and a TypeScript backend API.

## Repository Classification
- Type: monorepo (multi-part)
- Parts:
  - `backend` (tenant-aware REST API)
  - `ios_app` (SwiftUI offline-first app)

## High-level Objectives
- Role-based operational workflows for managers and employees.
- Offline-first execution with later synchronization.
- Financial management around invoices/payroll and dispute handling.
- Internationalization support (en-US/es-ES) and constrained currency model (USD/EUR).

## Tech Summary
- Backend: Node.js, TypeScript, Express, Postgres, Clerk
- iOS: SwiftUI, Core Data, Keychain/CryptoKit, Charts, Contacts

## Key Generated References
- `architecture-backend.md`
- `architecture-ios_app.md`
- `api-contracts-backend.md`
- `api-contracts-ios_app.md`
- `data-models-backend.md`
- `data-models-ios_app.md`
- `source-tree-analysis.md`
- `integration-architecture.md`
