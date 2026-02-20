# Development Guide - ios_app

## Prerequisites
- Xcode 16+
- iOS simulator/device with recent iOS version

## Setup
1. Open the linked Xcode project that points to `ios/AppGestaoServicos` sources.
2. Ensure scheme uses the `AppGestaoServicos` app target.
3. Build and run on simulator/device.

## Architecture Notes
- Offline-first state in `OfflineStore`.
- Persistence in Core Data (`Persistence.swift`) with encrypted snapshot fallback.
- Localization files in `en.lproj` and `es.lproj`.

## Key Workflows
- Role-based login at app start (`Employee` / `Manager`).
- CRUD across clients, employees, tasks, finance, services.
- Invoice/payroll generation and local notifications.

## Testing Status
- No dedicated unit/UI test target is committed in this repository snapshot.
- Recommended next step: add focused tests around `OfflineStore` mutation and serialization rules.
