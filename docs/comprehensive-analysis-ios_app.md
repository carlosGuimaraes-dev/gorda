# Comprehensive Analysis - ios_app

## Architecture Summary
- Single-target SwiftUI app focused on field operations.
- `OfflineStore` acts as state manager + domain service layer.
- Core Data model is generated in code and mirrored to Swift models.

## Domain Coverage
- Roles: Employee vs Manager UX filtering.
- Modules: dashboard, schedule, clients, finance, settings, employees/teams/services.
- Finance flows: invoice generation/reissue/dispute, payroll generation/manual confirmation.

## Offline-first and Sync
- Local mutations immediately persisted and queued.
- Conflict log and audit log maintained locally.
- Backend sync logic scaffolded for future integration.

## Security and Privacy
- Session and encryption key stored in Keychain.
- Snapshot data encrypted at rest with AES.GCM.
- Contact and camera integrations are optional and user-permission based.

## Internationalization and Currency
- English + Spanish localization files present.
- Global currency preference constrained to USD/EUR and propagated to domain entities.
