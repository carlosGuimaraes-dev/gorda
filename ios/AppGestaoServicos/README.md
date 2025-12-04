# Service Management App (SwiftUI)

Small SwiftUI prototype covering login, role-based dashboard (Employee/Manager), schedule, client management and basic finance, with offline support backed by Core Data (SQLite). Open `ios/AppGestaoServicos` in Xcode 15+ and run on an iOS 16+ simulator.

## Features
- Simple login with local session (Employee or Manager profile).
- Role-based dashboard:
  - Employee: workload summary and upcoming services for the current period (day/week/month).
  - Manager: task completion by team and basic financial cards (receivables/payables/net cash).
- Schedule (Agenda) per employee with daily/monthly view, status, time slots and inline editing.
- Client management with contact info, property details, access notes and preferred schedules.
- Finance view listing receivables and payables with status (pending/paid), method (Pix, card, cash) and creation of new entries.
- Offline support: local persistence via Core Data/SQLite plus a simple sync queue with “last write wins” conflict policy.
- Notifications: basic local/push notification preferences, and quick actions on service detail to notify client/team.

Wireframes are in [`Wireframes.md`](./Wireframes.md).  
The labeled backlog is in [`BACKLOG.md`](./BACKLOG.md).  
The data model used for Core Data is documented in [`DATA_MODEL.md`](./DATA_MODEL.md).

## How to test
1. Open `AppGestaoServicosApp.swift` in Xcode and run on a simulator.
2. On the login screen, enter any user/password, select Employee or Manager, and sign in.
3. As Employee, check the dashboard workload cards and upcoming services, then open the Schedule tab.
4. As Manager, check the dashboard team summary and finance cards, then open the Finance tab.
5. Create new clients and verify they appear in the Clients tab and client detail screen.
6. In the Schedule tab, create a new service, selecting client/employee/time/status, and confirm it appears in the list and detail.
