# Data Models - ios_app

## Swift Domain Models (`Models.swift`)
- `Client`
- `Employee`
- `ServiceType`
- `ServiceTask`
- `FinanceEntry`
- `UserSession`

## Persistence Model (`Persistence.swift`)
Core Data entities are created programmatically:
- `EmployeeEntity`
- `ClientEntity`
- `ServiceTypeEntity`
- `ServiceTaskEntity`
- `FinanceEntryEntity`

## Offline/Sync Support Models (`OfflineStore.swift`)
- `PendingChange` queue for deferred synchronization
- `ConflictLogEntry` for local conflict visibility
- `AuditLogEntry` for local action trace
- `NotificationPreferences`, `AppPreferences`

## Financial Model Notes
- Currency constrained to `USD`/`EUR`.
- Invoice/payroll/expense scenarios represented in `FinanceEntry.Kind`.
- Payroll details include period, hours, days, rates, and adjustment fields.

## Security-sensitive Fields
- Session and encryption key in Keychain.
- Snapshot payload encrypted using AES.GCM (`CryptoHelper`) before disk write.
