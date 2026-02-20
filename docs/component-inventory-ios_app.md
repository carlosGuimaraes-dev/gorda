# Component Inventory - ios_app

## Navigation and App Shell
- `AppGestaoServicosApp`
- `HomeView`, `TabView` sections
- `SideMenuSheet` + menu controller

## Authentication and Onboarding
- `SplashView`
- `LoginView`

## Domain Feature Views
- Dashboard, Agenda, Clients, Finance, Settings modules in `Views.swift`
- Employee management in `EmployeesView.swift`

## Reusable UI Components
- `AppCard`
- `PrimaryButton` patterns (via app views)
- `ContactAvatarView`
- `CountryCodePicker`
- `StatusPill` and row components in finance/schedule/client screens

## UIKit Bridges
- `ActivityView` (`UIActivityViewController`)
- `ImagePickerView` (`UIImagePickerController`)
- `AgendaCalendar` (`UICalendarView`)
- `ContactPickerView` (`CNContactPickerViewController`)

## Charts
- Finance and dashboard charting via Apple `Charts` framework.
