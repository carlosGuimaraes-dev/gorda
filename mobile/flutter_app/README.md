# AG Home Organizer - Flutter Migration

Flutter app that mirrors the SwiftUI app with strict parity-first strategy.

## Current scope

- Role-based app shell (`manager` and `employee`).
- Offline-first store (`OfflineStore`) with pending queue + sync stub.
- Semantic design tokens and base DS widgets in `lib/core/design/*`.
- i18n in `en-US` and `es-ES`.
- Finance advanced parity slice migrated:
  - `MonthlyClosingWizardPage`
  - `ReceiptsHubPage` + `QuickReceiptEntrySheet` (camera capture)
  - `EmissionReadyPage`
  - `InvoicesListPage` + `InvoiceFormPage` + `InvoiceDetailPage` (line items, dispute, reissue, PDF preview/share)
  - `PayrollListPage` + `PayrollFormPage` + `PayrollDetailPage`
  - `GenericFinanceDetailPage` + `ExpenseDetailPage`
  - `ReportsPage` (period filters + CSV/PDF export)
- Domain expansion mirrored from Swift:
  - `FinanceEntry` advanced fields (dispute, receipt, supersede, payroll breakdown, notes)
  - `AppPreferences`, `NotificationPreferences`, `CompanyProfile`
  - `ConflictLogEntry`, `AuditLogEntry`

## Approved Flutter dependencies used in this phase

- `image_picker`
- `share_plus`
- `pdf`
- `printing`

## Run (on supported environment)

```bash
cd mobile/flutter_app
flutter pub get
flutter run
```

## Validation note for this workspace

- This machine is macOS 12, while current Flutter/Dart toolchain in this project requires macOS 14+.
- Because of that, `dart format`, `dart analyze`, `flutter run` and tests could not be executed here.
