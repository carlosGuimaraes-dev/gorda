# Project Documentation Index

## Project Overview
- **Type:** monorepo with 2 parts
- **Primary Language:** Swift (iOS) + TypeScript (backend)
- **Architecture:** offline-first mobile client + tenant-scoped REST backend

## Quick Reference

### backend
- **Type:** backend
- **Tech Stack:** Node.js, TypeScript, Express, Postgres, Clerk
- **Root:** `backend/`

### ios_app
- **Type:** mobile
- **Tech Stack:** SwiftUI, Core Data, Keychain/CryptoKit, Charts/Contacts
- **Root:** `ios/AppGestaoServicos/`

## Generated Documentation
- [Project Overview](./project-overview.md)
- [Architecture - backend](./architecture-backend.md)
- [Architecture - ios_app](./architecture-ios_app.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Component Inventory - backend](./component-inventory-backend.md)
- [Component Inventory - ios_app](./component-inventory-ios_app.md)
- [Development Guide - backend](./development-guide-backend.md)
- [Development Guide - ios_app](./development-guide-ios_app.md)
- [Deployment Guide](./deployment-guide.md)
- [API Contracts - backend](./api-contracts-backend.md)
- [API Contracts - ios_app](./api-contracts-ios_app.md)
- [Data Models - backend](./data-models-backend.md)
- [Data Models - ios_app](./data-models-ios_app.md)
- [State Management - ios_app](./state-management-ios_app.md)
- [Asset Inventory - ios_app](./asset-inventory-ios_app.md)
- [Integration Architecture](./integration-architecture.md)
- [Comprehensive Analysis - backend](./comprehensive-analysis-backend.md)
- [Comprehensive Analysis - ios_app](./comprehensive-analysis-ios_app.md)
- [Project Parts Metadata (JSON)](./project-parts.json)

## Existing Documentation
- [Legacy Backend API Contract](./backend-api-contract.md)
- [Legacy Backend OpenAPI](./backend-openapi.yaml)
- [Legacy Backend Schema](./backend-schema.sql)
- [Legacy Backend Migrations](./backend-migrations.sql)
- [Legacy Backend Sprint Plan](./backend-sprint-plan.md)
- [Legacy Backend Integration Checklist](./backend-integration-checklist.md)
- [Legacy Backend Micro Backlog](./backend-micro-backlog.md)
- [Legacy Frontend Architecture](./architecture-frontend.md)
- [Legacy Root Data Model](./DATA_MODEL.md)
- [Legacy Wireframes](./Wireframes.md)

## Getting Started
1. Start with `project-overview.md` for context.
2. Read `architecture-ios_app.md` and `architecture-backend.md` for part boundaries.
3. Use `integration-architecture.md` before planning cross-part changes.
4. Use API + data model docs when implementing backend/mobile sync features.
5. Use this `index.md` as primary input for brownfield PRD creation.
