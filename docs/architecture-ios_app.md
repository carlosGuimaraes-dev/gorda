# Architecture - ios_app

## Executive Summary
Native SwiftUI app for AG Home Organizer operations. It is built as an offline-first system where UI actions mutate local state first, persist immediately, and queue pending changes for future backend synchronization.

## Technology Stack
- Swift + SwiftUI
- Core Data (SQLite)
- Keychain + CryptoKit for local security
- Apple frameworks: Charts, Contacts, UserNotifications, Intents, QuickLook

## Architecture Pattern
- Single app target.
- `OfflineStore` as central ObservableObject domain service.
- Feature views compose over the shared store via `@EnvironmentObject`.

## Data Architecture
- Codable domain models in `Models.swift`.
- Programmatic Core Data model in `Persistence.swift`.
- Encrypted snapshot fallback for resiliency.

## State and UX Model
- Role-dependent UI (Employee vs Manager).
- Finance/dashboard/schedule/client workflows coordinated in SwiftUI views.
- Preferences (language/currency/channels/dispute window) globally applied.

## Security and Privacy
- Session token and encryption key in Keychain.
- AES.GCM encryption for snapshot payloads.
- Optional Contacts/camera usage with permission-gated flows.

## Localization and Currency
- Localizable strings for en-US and es-ES.
- Currency constrained to USD/EUR with global manager-defined preference.

## Integration Surface
- Sync and notification backend endpoints mapped conceptually through store workflows.
- Current sync implementation is local stub awaiting full network client bridge.
