# Source Tree Analysis

## Repository View

```text
.
├── ios/
│   └── AppGestaoServicos/        # SwiftUI mobile app (ios_app part)
│       ├── AppGestaoServicosApp.swift  # App entry point
│       ├── Views.swift                # Main feature screens and navigation
│       ├── OfflineStore.swift         # Offline-first domain/store facade
│       ├── Models.swift               # Domain entities
│       ├── Persistence.swift          # Core Data model/container
│       ├── KeychainHelper.swift       # Secure storage for session/key
│       ├── CryptoHelper.swift         # AES.GCM snapshot encryption
│       ├── EmployeesView.swift        # Employee CRUD and related flows
│       ├── ContactAvatar.swift        # Contacts photo integration
│       ├── en.lproj/Localizable.strings
│       └── es.lproj/Localizable.strings
├── backend/                        # API backend (backend part)
│   ├── package.json               # Runtime/build scripts and dependencies
│   ├── tsconfig.json
│   ├── .env.example               # Required runtime environment variables
│   └── src/
│       ├── server.ts              # HTTP boot entry point
│       ├── app.ts                 # Express app wiring and route mounting
│       ├── env.ts                 # environment contract
│       ├── db.ts                  # Postgres query helpers
│       ├── auth/clerk.ts          # Clerk JWT verification
│       ├── middleware/            # auth/tenant/security middlewares
│       └── routes/                # tenants/sync/attachments/audit/conflicts/invoices
├── prd/
│   └── ios-servicos-prd.md        # Product requirements baseline
└── docs/                          # Existing and generated architecture/project docs
```

## Critical Folders Summary
- `ios/AppGestaoServicos/`: complete mobile feature implementation and persistence.
- `backend/src/routes/`: API contract behavior and domain endpoint surface.
- `backend/src/middleware/`: authorization and tenant isolation enforcement.
- `docs/`: schema, openapi, backlog, and generated documentation output target.

## Entry Points
- iOS: `ios/AppGestaoServicos/AppGestaoServicosApp.swift`
- Backend: `backend/src/server.ts` + `backend/src/app.ts`

## Multi-part Integration Paths
- iOS planned backend sync/integration path: `OfflineStore.syncPendingChanges()` → backend `/v1/sync/*`.
- Invoice send flows in iOS map to backend notification endpoint `/v1/invoices/:id/send`.
