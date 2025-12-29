# Frontend Architecture (iOS)

## Overview
The iOS app is a single-target SwiftUI application focused on offline-first workflows for service management.

## Core Principles
- Offline-first: local writes always succeed; sync is queued for later.
- Simple architecture: OfflineStore as the data facade; Core Data for persistence.
- Role-based UI: Employee vs Manager with filtered views and actions.
- Global currency and language: set by Manager in Settings and applied across flows.

## High-Level Structure
- Entry: ios/AppGestaoServicos/AppGestaoServicosApp.swift
- Views: ios/AppGestaoServicos/Views.swift, EmployeesView.swift
- Models: ios/AppGestaoServicos/Models.swift
- Data/Offline: ios/AppGestaoServicos/OfflineStore.swift
- Persistence: ios/AppGestaoServicos/Persistence.swift
- Theme: ios/AppGestaoServicos/Theme.swift

## Data Flow
1. UI events call OfflineStore methods.
2. OfflineStore mutates in-memory arrays.
3. OfflineStore writes to Core Data and the JSON snapshot.
4. Pending changes are appended to a local queue for future sync.

## Storage
- Primary: Core Data (SQLite).
- Secondary: JSON snapshot for resilience.
- Keychain: session token and encryption key.

## Sync Strategy (Planned)
- Local-first with a pending changes queue.
- Conflict handling: local priority + conflict log in Settings.
- No backend required for basic operation.

## Security
- Keychain for session and encryption keys.
- Sensitive fields encrypted at rest in local storage.

## Localization
- Base language: en-US.
- Secondary: es-ES.
- Locale is set globally by Manager in Settings.

## Currency Rules
- Manager defines a global currency (USD/EUR).
- All new records use the global currency.
- Existing records are normalized to the global currency (no conversion).

## Dependencies
- Apple frameworks only: SwiftUI, Charts, Core Data, Contacts, UIKit bridges.
