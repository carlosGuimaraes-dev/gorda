# AG Home Organizer - Flutter Base

This module is the initial cross-platform migration target for the iOS SwiftUI app.

## Current scope

- Flutter app shell with role-based tabs (`manager` and `employee`)
- Core domain entities mirrored from Swift models:
  - `Client`
  - `Employee`
  - `ServiceTask`
  - `FinanceEntry`
  - `UserSession`
  - `PendingChange`
- Offline-first starter store (`OfflineStore`) using in-memory state + pending queue contract
- i18n starter for `en-US` and `es-ES`

## Migration strategy

1. Keep Swift app as source of truth while Flutter reaches parity.
2. Migrate domain rules first (offline queue and entity invariants).
3. Migrate modules in this order:
   - Auth + Session
   - Dashboard
   - Agenda
   - Clients
   - Finance
   - Settings + Employees/Teams/Services
4. Integrate real local persistence (SQLite/Drift) before backend sync.

## Run (after Flutter SDK installation)

```bash
cd mobile/flutter_app
flutter pub get
flutter run
```

## Notes

- This repository currently does not have Flutter SDK installed on the machine used for this migration step.
- Because of that, commands like `flutter pub get` and `flutter test` were not executed yet.
