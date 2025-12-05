This repository powers the iOS app **AG Home Organizer International** (a service management app for Carlos and his team).\n+
\n+
Working style and constraints\n+
- Use **SwiftUI** as the primary UI framework and keep the architecture simple (single app target, no unnecessary frameworks).\n+
- The iOS code lives under `ios/AppGestaoServicos`. The AG Xcode project under `~/Documents/AG` uses **symlinks** to these files; always edit files in this repo, not inside `Documents/AG`.\n+
- Keep changes incremental and focused. Avoid big refactors or file splits unless explicitly requested.\n+
- Prefer clean, modern UI inspired by Apple / simple SaaS dashboards (white background, blue primary color, rounded cards).\n+
\n+
Functional expectations (high‑level)\n+
- App supports two roles: **Employee** and **Manager**, chosen at sign‑up/login, and all dashboards/flows respect the selected role.\n+
- Core modules: Login + splash, Dashboard, Schedule/Agenda, Clients, Finance, Settings, Employees.\n+
- Offline‑first storage: Core Data (SQLite) plus an in‑memory store `OfflineStore` with a pending changes queue.\n+
- Currencies: only **USD** and **EUR** (no BRL in v1).\n+
- Internationalization: base language in English; Spanish (es‑ES) as secondary; PT‑BR may come in a future version.\n+
\n+
Current UX patterns (to keep consistent)\n+
- Use `AppTheme` for colors and radius; avoid hard‑coding colors.\n+
- Lists in main tabs use **card‑style rows** (inset grouped lists, custom rows with avatars, phone, and payment status icons).\n+
- Forms use a **primary blue gradient button** fixed at the bottom (see `PrimaryButton` in `Views.swift`) instead of relying only on navigation‑bar “Save”.\n+
- Dashboard/Finance use the **Charts** framework for simple bar charts; keep graphs minimal and readable.\n+
\n+
Contacts and photos\n+
- Client and employee rows show an avatar loaded from **iOS Contacts** when possible (see `ContactAvatarView` and `ContactPhotoLoader`).\n+
- When adding an employee or client, the user can import basic data from Contacts; keep this flow optional and non‑blocking.\n+
\n+
Documentation and backlog\n+
- Keep `prd/ios-servicos-prd.md`, `ios/AppGestaoServicos/BACKLOG.md` and `ios/AppGestaoServicos/DATA_MODEL.md` in sync with implemented features and data model changes.\n+
- Whenever you add or complete a feature, update the backlog with a short bullet and mark it as ✅ when implemented.\n+
\n+
Testing & distribution\n+
- Target modern Xcode (>= 16) and recent iOS versions; the app is primarily for **internal use** (Carlos + employees) and will likely be distributed via TestFlight.\n+
- Do not introduce third‑party dependencies unless there is a strong reason and Carlos explicitly agrees.\n+
\n+
If you are unsure between multiple design options, prefer the one that keeps the UX simplest for field use (few taps, clear KPIs, and big touch targets).\n+

