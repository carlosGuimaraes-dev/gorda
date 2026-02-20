import SwiftUI
import Charts
import UIKit
import QuickLook
#if canImport(Contacts)
import Contacts
#endif

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var user: String = ""
    @State private var password: String = ""
    @State private var role: UserSession.Role = .manager

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack {
                    Spacer(minLength: 40)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back")
                                .font(.title.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .accessibilityAddTraits(.isHeader)
                            Text("Sign in to manage your services")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }

                        VStack(spacing: 16) {
                            TextField("User", text: $user)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppTheme.fieldBackground)
                                .cornerRadius(AppTheme.cornerRadius)

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppTheme.fieldBackground)
                                .cornerRadius(AppTheme.cornerRadius)

                            Picker("Profile", selection: $role) {
                                Text("Employee").tag(UserSession.Role.employee)
                                Text("Manager").tag(UserSession.Role.manager)
                            }
                            .pickerStyle(.segmented)
                        }

                        Button(action: {
                            store.login(user: user, password: password, role: role)
                        }) {
                            Text("Sign in")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(AppTheme.primary)
                                .cornerRadius(AppTheme.cornerRadius)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                .accessibilityLabel("Sign in to Service Management")
                        }

                        if let lastSync = store.lastSync {
                            Text(String(format: NSLocalizedString("Last sync: %@", comment: ""), lastSync.formatted(date: .abbreviated, time: .shortened)))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 480)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius * 1.25)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: OfflineStore
    @StateObject private var menuController = MenuController()
    @State private var selectedTab: HomeTab = .dashboard
    @State private var menuDestination: SideDestination?

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onMenu: { menuController.isPresented = true })
                .tabItem { Label("Dashboard", systemImage: "gauge") }
                .tag(HomeTab.dashboard)
            AgendaView(onMenu: { menuController.isPresented = true })
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(HomeTab.schedule)
            ClientsView(onMenu: { menuController.isPresented = true })
                .tabItem { Label("Clients", systemImage: "person.2") }
                .tag(HomeTab.clients)
            FinanceView(onMenu: { menuController.isPresented = true })
                .tabItem { Label("Finance", systemImage: "creditcard") }
                .tag(HomeTab.finance)
            SettingsView(onMenu: { menuController.isPresented = true })
                .tabItem { Label("Settings", systemImage: "gear") }
                .badge(store.conflictLog.isEmpty ? nil : store.conflictLog.count)
                .tag(HomeTab.settings)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .environmentObject(menuController)
        .sheet(isPresented: $menuController.isPresented) {
            SideMenuSheet(
                onSelectDashboard: {
                    selectedTab = .dashboard
                    menuController.isPresented = false
                },
                onSelectSchedule: {
                    selectedTab = .schedule
                    menuController.isPresented = false
                },
                onSelectClients: {
                    selectedTab = .clients
                    menuController.isPresented = false
                },
                onSelectServices: {
                    menuDestination = .services
                    menuController.isPresented = false
                },
                onSelectEmployees: {
                    menuDestination = .employees
                    menuController.isPresented = false
                },
                onSelectTeams: {
                    menuDestination = .teams
                    menuController.isPresented = false
                },
                onSelectFinance: {
                    selectedTab = .finance
                    menuController.isPresented = false
                },
                onSelectSettings: {
                    selectedTab = .settings
                    menuController.isPresented = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $menuDestination) { destination in
            switch destination {
            case .services:
                ServicesView()
                    .environmentObject(store)
            case .employees:
                NavigationStack {
                    EmployeesView()
                }
                .environmentObject(store)
            case .teams:
                NavigationStack {
                    TeamsView()
                }
                .environmentObject(store)
            }
        }
        .onAppear {
            UIApplication.shared.applicationIconBadgeNumber = store.conflictLog.count
        }
        .onChange(of: store.conflictLog.count) { value in
            UIApplication.shared.applicationIconBadgeNumber = value
        }
    }
}

enum HomeTab: Hashable {
    case dashboard
    case schedule
    case clients
    case finance
    case settings
}

enum SideDestination: Identifiable {
    case services
    case employees
    case teams

    var id: Self { self }
}

final class MenuController: ObservableObject {
    @Published var isPresented: Bool = false
}

private struct MenuButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.horizontal.3")
                .font(.title2)
                .foregroundColor(AppTheme.primary)
        }
    }
}

private struct SideMenuSheet: View {
    let onSelectDashboard: () -> Void
    let onSelectSchedule: () -> Void
    let onSelectClients: () -> Void
    let onSelectServices: () -> Void
    let onSelectEmployees: () -> Void
    let onSelectTeams: () -> Void
    let onSelectFinance: () -> Void
    let onSelectSettings: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Navigation") {
                    menuRow(title: "Dashboard", systemImage: "gauge", action: onSelectDashboard)
                    menuRow(title: "Schedule", systemImage: "calendar", action: onSelectSchedule)
                    menuRow(title: "Clients", systemImage: "person.2", action: onSelectClients)
                    menuRow(title: "Finance", systemImage: "creditcard", action: onSelectFinance)
                    menuRow(title: "Settings", systemImage: "gearshape", action: onSelectSettings)
                }
                Section("Catalogs") {
                    menuRow(title: "Services", systemImage: "wrench.and.screwdriver", action: onSelectServices)
                    menuRow(title: "Employees", systemImage: "person.3", action: onSelectEmployees)
                    menuRow(title: "Teams", systemImage: "flag.2.crossed", action: onSelectTeams)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menu")
        }
    }

    private func menuRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    @State private var scope: TimeScope = .day
    let onMenu: (() -> Void)?

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    enum TimeScope: String, CaseIterable, Identifiable {
        case day
        case week
        case month

        var id: String { rawValue }

        var label: String {
            switch self {
            case .day: return "Day"
            case .week: return "Week"
            case .month: return "Month"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Picker("Scope", selection: $scope) {
                        ForEach(TimeScope.allCases) { value in
                            Text(value.label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if let session = store.session {
                        switch session.role {
                        case .employee:
                            EmployeeDashboardView(scope: scope)
                        case .manager:
                            ManagerDashboardView(scope: scope)
                        }
                    } else {
                        Text("No active session")
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
            }
        }
    }
}

private struct EmployeeDashboardView: View {
    @EnvironmentObject private var store: OfflineStore
    let scope: DashboardView.TimeScope

    private var employeeName: String? {
        store.session?.name
    }

    private var tasksForEmployeeAndScope: [ServiceTask] {
        guard let name = employeeName else { return [] }
        let calendar = Calendar.current
        let now = Date()

        return store.tasks.filter { task in
            guard task.assignedEmployee.name == name else { return false }
            switch scope {
            case .day:
                return calendar.isDate(task.date, inSameDayAs: now)
            case .week:
                return calendar.isDate(task.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(task.date, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var completedCount: Int {
        tasksForEmployeeAndScope.filter { $0.status == .completed }.count
    }

    private var inProgressCount: Int {
        tasksForEmployeeAndScope.filter { $0.status == .inProgress }.count
    }

    private var scheduledCount: Int {
        tasksForEmployeeAndScope.filter { $0.status == .scheduled }.count
    }

    private var totalWorkedHours: Double {
        tasksForEmployeeAndScope.compactMap { task in
            guard let checkIn = task.checkInTime, let checkOut = task.checkOutTime else { return nil }
            let interval = checkOut.timeIntervalSince(checkIn)
            return interval > 0 ? interval / 3600.0 : nil
        }.reduce(0, +)
    }

    private var estimatedEarnings: Double {
        guard
            let name = employeeName,
            let employee = store.employees.first(where: { $0.name == name }),
            let rate = employee.hourlyRate
        else { return 0 }
        return totalWorkedHours * rate
    }

    var body: some View {
        VStack(spacing: 12) {
            if let name = employeeName {
                Text(String(format: NSLocalizedString("Hello, %@", comment: ""), name))
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            GroupBox("Workload") {
                HStack {
                    VStack {
                        Text("Scheduled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(scheduledCount)")
                            .font(.title2.bold())
                    }
                    Spacer()
                    VStack {
                        Text("In progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(inProgressCount)")
                            .font(.title2.bold())
                    }
                    Spacer()
                    VStack {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(completedCount)")
                            .font(.title2.bold())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)

            GroupBox("Today") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Worked hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: NSLocalizedString("%.1f h", comment: ""), totalWorkedHours))
                            .font(.title3.bold())
                    }
                    Spacer()
                    if let name = employeeName,
                       let employee = store.employees.first(where: { $0.name == name }),
                       let currency = employee.currency {
                        VStack(alignment: .trailing) {
                            Text("Estimated earnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(currency.label) \(estimatedEarnings, specifier: "%.2f")")
                                .font(.title3.bold())
                        }
                    }
                }
                .padding()
            }
            .padding(.horizontal)

            if tasksForEmployeeAndScope.isEmpty {
                Text("No services in this period.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    Section("Next services") {
                        ForEach(tasksForEmployeeAndScope.prefix(5)) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).bold()
                                HStack(spacing: 8) {
                                    Text(task.date, style: .date)
                                    if let start = task.startTime {
                                        Text(start, style: .time)
                                    }
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                StatusBadge(status: task.status)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

private struct ManagerDashboardView: View {
    @EnvironmentObject private var store: OfflineStore
    let scope: DashboardView.TimeScope

    private var tasksForScope: [ServiceTask] {
        let calendar = Calendar.current
        let now = Date()
        return store.tasks.filter { task in
            switch scope {
            case .day:
                return calendar.isDate(task.date, inSameDayAs: now)
            case .week:
                return calendar.isDate(task.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(task.date, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var teamsSummary: [(team: String, total: Int, completed: Int)] {
        let grouped = Dictionary(grouping: tasksForScope) { $0.assignedEmployee.team }
        return grouped.map { key, value in
            let completed = value.filter { $0.status == .completed }.count
            return (team: key, total: value.count, completed: completed)
        }.sorted { $0.team < $1.team }
    }

    private var receivablesPending: Double {
        store.finance
            .filter { $0.type == .receivable && $0.status == .pending }
            .map(\.amount)
            .reduce(0, +)
    }

    private var payablesPending: Double {
        store.finance
            .filter { $0.type == .payable && $0.status == .pending }
            .map(\.amount)
            .reduce(0, +)
    }

    private var netCashFlow: Double {
        receivablesPending - payablesPending
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    private var statusSummary: [(status: ServiceTask.Status, count: Int)] {
        ServiceTask.Status.allCases.map { status in
            let count = tasksForScope.filter { $0.status == status }.count
            return (status, count)
        }.filter { $0.count > 0 }
    }

    private var financeOverview: [(label: String, value: Double)] {
        [
            ("Receivables", receivablesPending),
            ("Payables", payablesPending)
        ]
    }

    private func color(for status: ServiceTask.Status) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .canceled: return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Operations")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total tasks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(tasksForScope.count)")
                                    .font(.title2.bold())
                            }
                            Spacer()
                            let completed = tasksForScope.filter { $0.status == .completed }.count
                            VStack(alignment: .trailing) {
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(completed)")
                                    .font(.title2.bold())
                            }
                        }
                        if !statusSummary.isEmpty {
                            Chart {
                                ForEach(statusSummary, id: \.status) { item in
                                    BarMark(
                                        x: .value("Status", item.status.label),
                                        y: .value("Tasks", item.count)
                                    )
                                    .foregroundStyle(color(for: item.status))
                                }
                            }
                            .frame(height: 150)
                        }
                    }
                }
                .padding(.horizontal)

                if !teamsSummary.isEmpty {
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By team")
                                .font(.headline)
                            ForEach(teamsSummary, id: \.team) { summary in
                                HStack {
                                    Text(summary.team)
                                    Spacer()
                                    Text(String(format: NSLocalizedString("%d/%d completed", comment: ""), summary.completed, summary.total))
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Finance")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Receivables")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(currencyFormatter.string(from: NSNumber(value: receivablesPending)) ?? "-")
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Payables")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(currencyFormatter.string(from: NSNumber(value: payablesPending)) ?? "-")
                                    .bold()
                                    .foregroundColor(.red)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Net cash (pending)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: netCashFlow)) ?? "-")
                                .bold()
                                .foregroundColor(netCashFlow >= 0 ? .green : .red)
                        }

                        Chart {
                            ForEach(financeOverview, id: \.label) { item in
                                BarMark(
                                    x: .value("Category", item.label),
                                    y: .value("Amount", item.value)
                                )
                                .foregroundStyle(item.label == "Receivables" ? .green : .red)
                            }
                        }
                        .frame(height: 150)
                    }
                }
                .padding(.horizontal)

                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Monthly closing")
                            .font(.headline)
                        Text("Review pending issues and complete monthly emission in guided steps.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        NavigationLink {
                            MonthlyClosingWizardView()
                        } label: {
                            Label("Open closing wizard", systemImage: "list.number")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct AgendaView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    @State private var selectedDate = Date()
    @State private var showingForm = false
    @State private var scope: Scope = .day
    @State private var selectedTeam: String? = nil
    let onMenu: (() -> Void)?

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    private enum Scope: String, CaseIterable, Identifiable {
        case day
        case month

        var id: String { rawValue }

        var label: String {
            switch self {
            case .day: return "Day"
            case .month: return "Month"
            }
        }
    }

    private var isEmployee: Bool {
        store.session?.role == .employee
    }

    private var sessionEmployee: Employee? {
        guard isEmployee, let name = store.session?.name else { return nil }
        return store.employees.first { $0.name == name }
    }

    private var visibleTasks: [ServiceTask] {
        guard isEmployee else { return store.tasks }
        guard let sessionName = store.session?.name else { return [] }
        if let employeeId = sessionEmployee?.id {
            let sessionTeam = sessionEmployee?.team ?? ""
            return store.tasks.filter {
                let matchesEmployee = $0.assignedEmployee.id == employeeId || $0.assignedEmployee.name == sessionName
                let matchesTeam = sessionTeam.isEmpty || $0.assignedEmployee.team == sessionTeam
                return matchesEmployee && matchesTeam
            }
        }
        return store.tasks.filter { $0.assignedEmployee.name == sessionName }
    }

    private var teams: [String] {
        guard !isEmployee else { return [] }
        return Array(Set(store.employees.map { $0.team })).sorted()
    }

    private var tasksForSelectedScope: [ServiceTask] {
        let calendar = Calendar.current
        switch scope {
        case .day:
            return visibleTasks.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        case .month:
            return visibleTasks.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
        }
    }

    private var filteredTasks: [ServiceTask] {
        tasksForSelectedScope.filter { task in
            guard let team = selectedTeam, !team.isEmpty else { return true }
            return task.assignedEmployee.team == team
        }
    }

    private var groupedMonthlyTasks: [(date: Date, tasks: [ServiceTask])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredTasks) { task in
            calendar.startOfDay(for: task.date)
        }
        return groups.keys.sorted().map { date in
            let tasks = groups[date] ?? []
            return (date: date, tasks: tasks.sorted { ($0.startTime ?? $0.date) < ($1.startTime ?? $1.date) })
        }
    }

    private var datesWithTasks: Set<Date> {
        let calendar = Calendar.current
        let allTasks = visibleTasks
        let days = allTasks.map { calendar.startOfDay(for: $0.date) }
        return Set(days)
    }

    var body: some View {
        NavigationStack {
            VStack {
                AgendaCalendar(selectedDate: $selectedDate, eventDates: datesWithTasks)
                    .frame(maxHeight: 360)
                    .padding(.horizontal)
                Picker("Scope", selection: $scope) {
                    ForEach(Scope.allCases) { value in
                        Text(value.label).tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if !teams.isEmpty {
                    Picker("Team", selection: Binding(
                        get: { selectedTeam ?? "" },
                        set: { selectedTeam = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("All teams").tag("")
                        ForEach(teams, id: \.self) { team in
                            Text(team).tag(team)
                        }
                    }
                    .padding(.horizontal)
                }

                if scope == .day {
                    List {
                        ForEach(filteredTasks) { task in
                            NavigationLink(destination: ServiceDetailView(task: task)) {
                                taskRow(for: task)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    List {
                        ForEach(groupedMonthlyTasks, id: \.date) { group in
                            Section(header: Text(group.date, style: .date)) {
                                ForEach(group.tasks) { task in
                                    NavigationLink(destination: ServiceDetailView(task: task)) {
                                        taskRow(for: task)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingForm = true }) {
                        Label("New service", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new_service_button")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { store.syncPendingChanges() }) {
                        Label("Sync", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ServiceFormView(initialDate: selectedDate)
            }
        }
    }

    @ViewBuilder
    private func taskRow(for task: ServiceTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title).bold()
                Spacer()
                StatusBadge(status: task.status)
            }
            HStack(spacing: 8) {
                if let start = task.startTime { Text(start, style: .time) }
                if let end = task.endTime {
                    Text("-")
                    Text(end, style: .time)
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            Text(String(format: NSLocalizedString("Client: %@", comment: ""), task.clientName))
                .font(.subheadline)
            Text(task.address)
                .font(.footnote)
                .foregroundColor(.secondary)
            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum ClientStatusFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case inactive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .active: return NSLocalizedString("Active", comment: "")
        case .inactive: return NSLocalizedString("Inactive", comment: "")
        }
    }
}

private enum ClientPeriodFilter: String, CaseIterable, Identifiable {
    case all
    case currentMonth
    case last30Days

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return NSLocalizedString("All time", comment: "")
        case .currentMonth: return NSLocalizedString("Current month", comment: "")
        case .last30Days: return NSLocalizedString("Last 30 days", comment: "")
        }
    }
}

private enum ClientSortOrder: String, CaseIterable, Identifiable {
    case nameAsc
    case nameDesc
    case pendingReceivablesDesc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nameAsc: return NSLocalizedString("Name (A-Z)", comment: "")
        case .nameDesc: return NSLocalizedString("Name (Z-A)", comment: "")
        case .pendingReceivablesDesc: return NSLocalizedString("Pending receivables", comment: "")
        }
    }
}

struct ClientsView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    @State private var showingForm = false
    @State private var showingDeleteBlocked = false
    @State private var deleteBlockedMessage = ""
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var statusFilter: ClientStatusFilter = .all
    @State private var periodFilter: ClientPeriodFilter = .all
    @State private var sortOrder: ClientSortOrder = .nameAsc
    @State private var selectedTeamFilter = ""
    let onMenu: (() -> Void)?

    private var isManager: Bool {
        store.session?.role == .manager
    }

    private var teamOptions: [String] {
        Array(Set(store.tasks.map(\.assignedEmployee.team).filter { !$0.isEmpty })).sorted()
    }

    private var periodRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let now = Date()
        switch periodFilter {
        case .all:
            return nil
        case .currentMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)?.addingTimeInterval(-1) ?? now
            return start...end
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return start...now
        }
    }

    private var filteredClients: [Client] {
        var clients = store.clients.filter { client in
            let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch: Bool
            if normalizedQuery.isEmpty {
                matchesSearch = true
            } else {
                let haystack = [
                    client.name,
                    client.phone,
                    client.whatsappPhone,
                    client.email,
                    client.address
                ]
                .joined(separator: " ")
                .lowercased()
                matchesSearch = haystack.contains(normalizedQuery)
            }

            let clientTasks = tasksForClient(client)
            let matchesStatus: Bool
            switch statusFilter {
            case .all:
                matchesStatus = true
            case .active:
                matchesStatus = clientTasks.contains { $0.status != .canceled }
            case .inactive:
                matchesStatus = !clientTasks.contains { $0.status != .canceled }
            }

            let matchesPeriod: Bool
            if let range = periodRange {
                matchesPeriod = clientTasks.contains { range.contains($0.date) }
            } else {
                matchesPeriod = true
            }

            let matchesTeam: Bool
            if selectedTeamFilter.isEmpty {
                matchesTeam = true
            } else {
                matchesTeam = clientTasks.contains { $0.assignedEmployee.team == selectedTeamFilter }
            }

            return matchesSearch && matchesStatus && matchesPeriod && matchesTeam
        }

        switch sortOrder {
        case .nameAsc:
            clients.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            clients.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .pendingReceivablesDesc:
            clients.sort { pendingReceivables(for: $0) > pendingReceivables(for: $1) }
        }
        return clients
    }

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredClients.isEmpty {
                    Text("No clients match current filters.")
                        .foregroundColor(.secondary)
                } else if isManager {
                    ForEach(filteredClients) { client in
                        clientRow(for: client)
                    }
                    .onDelete { indexSet in
                        let items = indexSet.map { filteredClients[$0] }
                        let failed = items.filter { !store.deleteClient($0) }
                        if !failed.isEmpty {
                            deleteBlockedMessage = NSLocalizedString(
                                "This client has linked services or finance entries. Resolve them before deleting.",
                                comment: ""
                            )
                            showingDeleteBlocked = true
                        }
                    }
                } else {
                    ForEach(filteredClients) { client in
                        clientRow(for: client)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search client")
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if isManager {
                        Button(action: { showingForm = true }) {
                            Label("New", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ClientForm()
            }
            .sheet(isPresented: $showingFilters) {
                ClientFiltersSheet(
                    statusFilter: $statusFilter,
                    periodFilter: $periodFilter,
                    sortOrder: $sortOrder,
                    selectedTeam: $selectedTeamFilter,
                    teamOptions: teamOptions
                )
            }
            .alert(NSLocalizedString("Cannot delete", comment: ""), isPresented: $showingDeleteBlocked) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteBlockedMessage)
            }
        }
    }

    @ViewBuilder
    private func clientRow(for client: Client) -> some View {
        let hasPendingReceivables = pendingReceivables(for: client) > 0
        let primaryPhone = client.phone.isEmpty ? client.whatsappPhone : client.phone
        let clientIsActive = tasksForClient(client).contains { $0.status != .canceled }

        NavigationLink(destination: ClientDetailView(client: client)) {
            HStack(spacing: 12) {
                ContactAvatarView(name: client.name, phone: primaryPhone, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(client.name).bold()
                        Text(clientIsActive ? "Active" : "Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((clientIsActive ? Color.green : Color.gray).opacity(0.2))
                            .foregroundColor(clientIsActive ? .green : .secondary)
                            .cornerRadius(6)
                    }
                    if !client.phone.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            Text(client.phone)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    } else if !client.whatsappPhone.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "message.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            Text(client.whatsappPhone)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    } else if !client.email.isEmpty {
                        Text(client.email)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text(client.address)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                PaymentStatusIcon(hasPending: hasPendingReceivables)
            }
            .padding(10)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }

    private func tasksForClient(_ client: Client) -> [ServiceTask] {
        store.tasks.filter { task in
            if let clientId = task.clientId, clientId == client.id {
                return true
            }
            return task.clientName == client.name
        }
    }

    private func pendingReceivables(for client: Client) -> Double {
        store.finance
            .filter { entry in
                entry.type == .receivable &&
                entry.status == .pending &&
                (entry.clientId == client.id || entry.clientName == client.name)
            }
            .reduce(0) { $0 + $1.amount }
    }
}

private struct ClientFiltersSheet: View {
    @Binding var statusFilter: ClientStatusFilter
    @Binding var periodFilter: ClientPeriodFilter
    @Binding var sortOrder: ClientSortOrder
    @Binding var selectedTeam: String
    let teamOptions: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $statusFilter) {
                        ForEach(ClientStatusFilter.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Team") {
                    Picker("Team", selection: $selectedTeam) {
                        Text("All teams").tag("")
                        ForEach(teamOptions, id: \.self) { team in
                            Text(team).tag(team)
                        }
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $periodFilter) {
                        ForEach(ClientPeriodFilter.allCases) { period in
                            Text(period.label).tag(period)
                        }
                    }
                }

                Section("Sort by") {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(ClientSortOrder.allCases) { order in
                            Text(order.label).tag(order)
                        }
                    }
                }
            }
            .navigationTitle("Client Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") {
                        statusFilter = .all
                        periodFilter = .all
                        sortOrder = .nameAsc
                        selectedTeam = ""
                    }
                }
            }
        }
    }
}

struct FinanceView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    @State private var showingForm = false
    @State private var showingInvoiceGenerator = false
    @State private var showingPayrollGenerator = false
    let onMenu: (() -> Void)?

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    private var isManager: Bool {
        store.session?.role == .manager
    }

    private var employeePayrollEntries: [FinanceEntry] {
        guard store.session?.role == .employee else { return [] }
        let sessionName = store.session?.name
        let employeeId = sessionName.flatMap { name in
            store.employees.first(where: { $0.name == name })?.id
        }
        return store.finance.filter { entry in
            guard entry.kind == .payrollEmployee else { return false }
            if let employeeId, let entryEmployeeId = entry.employeeId {
                return entryEmployeeId == employeeId
            }
            if let sessionName, let entryName = entry.employeeName {
                return entryName == sessionName
            }
            return false
        }
        .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            List {
                if isManager {
                    Section("Closing flow") {
                        NavigationLink {
                            MonthlyClosingWizardView()
                        } label: {
                            Label("Closing wizard", systemImage: "list.number")
                        }
                        NavigationLink {
                            ReceiptsHubView()
                        } label: {
                            Label("Receipts hub", systemImage: "camera.viewfinder")
                        }
                        NavigationLink {
                            EmissionReadyView()
                        } label: {
                            Label("Ready to emit", systemImage: "paperplane")
                        }
                    }

                    Section("End of month") {
                        Button {
                            showingInvoiceGenerator = true
                        } label: {
                            Label("Generate client invoices", systemImage: "doc.text.fill")
                        }
                        Button {
                            showingPayrollGenerator = true
                        } label: {
                            Label("Generate payroll", systemImage: "person.badge.clock.fill")
                        }
                    }

                    Section("Invoices & Payroll") {
                        NavigationLink {
                            InvoicesListView()
                        } label: {
                            Label("Invoices", systemImage: "doc.text")
                        }
                        NavigationLink {
                            PayrollListView()
                        } label: {
                            Label("Payroll", systemImage: "person.2.badge.clock")
                        }
                    }

                    Section("Reports") {
                        NavigationLink {
                            ReportsView()
                        } label: {
                            Label("Monthly reports", systemImage: "chart.bar.xaxis")
                        }
                    }
                }
                if isManager {
                    Section(header: Text("Receivables")) {
                        ForEach(store.finance.filter { $0.type == .receivable }) { entry in
                            NavigationLink {
                                FinanceEntryDetailView(entry: entry)
                            } label: {
                                FinanceRow(entry: entry) { status, method in
                                    store.markFinanceEntry(entry, status: status, method: method)
                                }
                            }
                        }
                    }
                    Section(header: Text("Payables")) {
                        ForEach(store.finance.filter { $0.type == .payable }) { entry in
                            NavigationLink {
                                FinanceEntryDetailView(entry: entry)
                            } label: {
                                FinanceRow(entry: entry) { status, method in
                                    store.markFinanceEntry(entry, status: status, method: method)
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("Payroll")) {
                        if employeePayrollEntries.isEmpty {
                            Text("No payroll entries yet.")
                                .foregroundColor(.secondary)
                        }
                        ForEach(employeePayrollEntries) { entry in
                            NavigationLink {
                                FinanceEntryDetailView(entry: entry)
                            } label: {
                                FinanceRow(entry: entry) { status, method in
                                    store.markFinanceEntry(entry, status: status, method: method)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
                if isManager {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingForm = true }) {
                            Label("New", systemImage: "plus")
                        }
                        .accessibilityIdentifier("new_finance_button")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                FinanceFormView()
            }
            .sheet(isPresented: $showingInvoiceGenerator) {
                InvoiceGeneratorView()
            }
            .sheet(isPresented: $showingPayrollGenerator) {
                PayrollGeneratorView()
            }
        }
    }
}

private struct ReportItem: Identifiable {
    let id = UUID()
    let name: String
    let total: Double
    let count: Int
}

struct ReportsView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var scope: ReportScope = .month
    @State private var selectedMonth: Date = Date()
    @State private var selectedWeek: Date = Date()
    @State private var customStart: Date = Date()
    @State private var customEnd: Date = Date()
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

    private enum ReportScope: String, CaseIterable, Identifiable {
        case month
        case week
        case custom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .month: return NSLocalizedString("Month", comment: "")
            case .week: return NSLocalizedString("Week", comment: "")
            case .custom: return NSLocalizedString("Custom range", comment: "")
            }
        }
    }

    private var reportRange: ClosedRange<Date> {
        let calendar = Calendar.current
        switch scope {
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) ?? selectedMonth
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? selectedMonth
            let end = calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? selectedMonth
            return inclusiveRange(start: start, end: end)
        case .week:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: selectedWeek) {
                let end = interval.end.addingTimeInterval(-1)
                return inclusiveRange(start: interval.start, end: end)
            }
            return inclusiveRange(start: selectedWeek, end: selectedWeek)
        case .custom:
            let start = min(customStart, customEnd)
            let end = max(customStart, customEnd)
            return inclusiveRange(start: start, end: end)
        }
    }

    private var periodLabel: String {
        let formatter = DateFormatter()
        switch scope {
        case .month:
            formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return formatter.string(from: selectedMonth)
        case .week, .custom:
            formatter.dateStyle = .medium
            let start = formatter.string(from: reportRange.lowerBound)
            let end = formatter.string(from: reportRange.upperBound)
            return "\(start) - \(end)"
        }
    }

    private var entriesInRange: [FinanceEntry] {
        store.finance.filter { entry in
            reportRange.contains(entry.dueDate)
        }
    }

    private var receivablesInRange: [FinanceEntry] {
        entriesInRange.filter { $0.type == .receivable }
    }

    private var payablesInRange: [FinanceEntry] {
        entriesInRange.filter { $0.type == .payable }
    }

    private var currenciesInRange: [FinanceEntry.Currency] {
        let set = Set(entriesInRange.map(\.currency))
        return FinanceEntry.Currency.allCases.filter { set.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Period")
                            .font(.headline)
                        Picker("Period", selection: $scope) {
                            ForEach(ReportScope.allCases) { scope in
                                Text(scope.label).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        switch scope {
                        case .month:
                            DatePicker("Month", selection: $selectedMonth, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                        case .week:
                            DatePicker("Week", selection: $selectedWeek, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                        case .custom:
                            DatePicker("Start date", selection: $customStart, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                            DatePicker("End date", selection: $customEnd, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                        }
                        Text(periodLabel)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                if entriesInRange.isEmpty {
                    AppCard {
                        Text("No data for this period.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    ForEach(currenciesInRange, id: \.self) { currency in
                        let receivables = receivablesInRange.filter { $0.currency == currency }
                        let payables = payablesInRange.filter { $0.currency == currency }
                        let clientItems = summaryItems(for: receivables, name: { $0.clientName ?? NSLocalizedString("Unknown", comment: "") })
                        let employeeItems = summaryItems(for: payables, name: { $0.employeeName ?? NSLocalizedString("Unknown", comment: "") })
                        let totalReceivables = receivables.reduce(0) { $0 + $1.amount }
                        let totalPayables = payables.reduce(0) { $0 + $1.amount }
                        let net = totalReceivables - totalPayables
                        let summaryKey: String = {
                            switch scope {
                            case .month: return "Monthly summary (%@)"
                            case .week: return "Weekly summary (%@)"
                            case .custom: return "Summary (%@)"
                            }
                        }()

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(String(format: NSLocalizedString(summaryKey, comment: ""), currency.code))
                                    .font(.headline)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Receivables")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(currencyFormatter(for: currency).string(from: NSNumber(value: totalReceivables)) ?? "-")
                                            .bold()
                                            .foregroundColor(.green)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Payables")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(currencyFormatter(for: currency).string(from: NSNumber(value: totalPayables)) ?? "-")
                                            .bold()
                                            .foregroundColor(.red)
                                    }
                                }
                                Divider()
                                HStack {
                                    Text("Net")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(currencyFormatter(for: currency).string(from: NSNumber(value: net)) ?? "-")
                                        .bold()
                                        .foregroundColor(net >= 0 ? .green : .red)
                                }
                            }
                        }
                        .padding(.horizontal)

                        if !clientItems.isEmpty {
                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Top clients")
                                        .font(.headline)
                                    Chart {
                                        ForEach(clientItems.prefix(6)) { item in
                                            BarMark(
                                                x: .value("Client", item.name),
                                                y: .value("Amount", item.total)
                                            )
                                            .foregroundStyle(.green)
                                        }
                                    }
                                    .frame(height: 180)

                                    ForEach(clientItems.prefix(5)) { item in
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            Text(currencyFormatter(for: currency).string(from: NSNumber(value: item.total)) ?? "-")
                                                .bold()
                                        }
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        if !employeeItems.isEmpty {
                            AppCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Top employees")
                                        .font(.headline)
                                    Chart {
                                        ForEach(employeeItems.prefix(6)) { item in
                                            BarMark(
                                                x: .value("Employee", item.name),
                                                y: .value("Amount", item.total)
                                            )
                                            .foregroundStyle(.red)
                                        }
                                    }
                                    .frame(height: 180)

                                    ForEach(employeeItems.prefix(5)) { item in
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            Text(currencyFormatter(for: currency).string(from: NSNumber(value: item.total)) ?? "-")
                                                .bold()
                                        }
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export")
                                .font(.headline)
                            Button {
                                exportCSV()
                            } label: {
                                Label("Export CSV", systemImage: "tray.and.arrow.up")
                            }
                            Button {
                                exportPDF()
                            } label: {
                                Label("Export PDF", systemImage: "doc.richtext")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Reports")
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(items: shareItems)
        }
    }

    private func summaryItems(for entries: [FinanceEntry], name: (FinanceEntry) -> String) -> [ReportItem] {
        let grouped = Dictionary(grouping: entries) { entry in
            let raw = name(entry).trimmingCharacters(in: .whitespacesAndNewlines)
            return raw.isEmpty ? NSLocalizedString("Unknown", comment: "") : raw
        }
        return grouped.map { key, values in
            ReportItem(name: key, total: values.reduce(0) { $0 + $1.amount }, count: values.count)
        }
        .sorted { $0.total > $1.total }
    }

    private func currencyFormatter(for currency: FinanceEntry.Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        return formatter
    }

    private func exportCSV() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let start = formatter.string(from: reportRange.lowerBound)
        let end = formatter.string(from: reportRange.upperBound)
        var lines: [String] = [
            "Period Start,Period End,Currency,Type,Name,Count,Total"
        ]

        for currency in currenciesInRange {
            let receivables = receivablesInRange.filter { $0.currency == currency }
            let payables = payablesInRange.filter { $0.currency == currency }
            let clientItems = summaryItems(for: receivables, name: { $0.clientName ?? NSLocalizedString("Unknown", comment: "") })
            let employeeItems = summaryItems(for: payables, name: { $0.employeeName ?? NSLocalizedString("Unknown", comment: "") })

            for item in clientItems {
                lines.append(csvRow(values: [
                    start,
                    end,
                    currency.code,
                    NSLocalizedString("Receivable", comment: ""),
                    item.name,
                    "\(item.count)",
                    String(format: "%.2f", item.total)
                ]))
            }
            for item in employeeItems {
                lines.append(csvRow(values: [
                    start,
                    end,
                    currency.code,
                    NSLocalizedString("Payable", comment: ""),
                    item.name,
                    "\(item.count)",
                    String(format: "%.2f", item.total)
                ]))
            }
        }

        let csv = lines.joined(separator: "\n")
        shareItems = [csv]
        showingShareSheet = true
    }

    private func exportPDF() {
        let pdfData = buildReportPDF()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let start = formatter.string(from: reportRange.lowerBound)
        let end = formatter.string(from: reportRange.upperBound)
        let fileName = "report-\(start)-\(end).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        do {
            try pdfData.write(to: url)
            shareItems = [url]
        } catch {
            shareItems = [pdfData]
        }
        showingShareSheet = true
    }

    private func buildReportPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            let margin: CGFloat = 24
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                let size = attributed.boundingRect(
                    with: CGSize(width: pageRect.width - margin * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                attributed.draw(in: CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: size.height))
                y += size.height + 8
            }

            let reportTitleKey = scope == .month ? "Monthly report: %@" : "Report: %@"
            draw(String(format: NSLocalizedString(reportTitleKey, comment: ""), periodLabel), font: .boldSystemFont(ofSize: 20))

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            draw(
                String(format: NSLocalizedString("Period: %@ - %@", comment: ""), formatter.string(from: reportRange.lowerBound), formatter.string(from: reportRange.upperBound)),
                font: .systemFont(ofSize: 12),
                color: .darkGray
            )

            for currency in currenciesInRange {
                let receivables = receivablesInRange.filter { $0.currency == currency }
                let payables = payablesInRange.filter { $0.currency == currency }
                let totalReceivables = receivables.reduce(0) { $0 + $1.amount }
                let totalPayables = payables.reduce(0) { $0 + $1.amount }
                let net = totalReceivables - totalPayables

                draw(String(format: NSLocalizedString("Summary (%@)", comment: ""), currency.code), font: .boldSystemFont(ofSize: 14))
                draw(String(format: NSLocalizedString("Receivables: %@ %.2f", comment: ""), currency.code, totalReceivables), font: .systemFont(ofSize: 12))
                draw(String(format: NSLocalizedString("Payables: %@ %.2f", comment: ""), currency.code, totalPayables), font: .systemFont(ofSize: 12))
                draw(String(format: NSLocalizedString("Net: %@ %.2f", comment: ""), currency.code, net), font: .systemFont(ofSize: 12))

                let clientItems = summaryItems(for: receivables, name: { $0.clientName ?? NSLocalizedString("Unknown", comment: "") })
                if !clientItems.isEmpty {
                    draw(NSLocalizedString("Top clients", comment: ""), font: .boldSystemFont(ofSize: 12))
                    for item in clientItems.prefix(5) {
                        draw(String(format: "- %@: %@ %.2f", item.name, currency.code, item.total), font: .systemFont(ofSize: 11))
                    }
                }

                let employeeItems = summaryItems(for: payables, name: { $0.employeeName ?? NSLocalizedString("Unknown", comment: "") })
                if !employeeItems.isEmpty {
                    draw(NSLocalizedString("Top employees", comment: ""), font: .boldSystemFont(ofSize: 12))
                    for item in employeeItems.prefix(5) {
                        draw(String(format: "- %@: %@ %.2f", item.name, currency.code, item.total), font: .systemFont(ofSize: 11))
                    }
                }
            }
        }
    }

    private func csvRow(values: [String]) -> String {
        values.map { value in
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }.joined(separator: ",")
    }

    private func inclusiveRange(start: Date, end: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        let endInclusive = endExclusive.addingTimeInterval(-1)
        return startDay...endInclusive
    }
}

struct MonthlyClosingWizardView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth = Date()
    @State private var stepIndex = 0
    @State private var showingBlockedAlert = false

    private let stepTitles = [
        NSLocalizedString("Period", comment: ""),
        NSLocalizedString("Pending", comment: ""),
        NSLocalizedString("Review", comment: ""),
        NSLocalizedString("Ready", comment: "")
    ]

    private var monthRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) ?? selectedMonth
        let end = calendar.date(byAdding: .month, value: 1, to: start)?.addingTimeInterval(-1) ?? selectedMonth
        return start...end
    }

    private var pendingOutOfPocketReceipts: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .expenseOutOfPocket && $0.status == .pending && monthRange.contains($0.dueDate) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var receiptsWithoutClientCount: Int {
        pendingOutOfPocketReceipts.filter { $0.clientId == nil && ($0.clientName ?? "").isEmpty }.count
    }

    private var syncConflictsCount: Int {
        store.conflictLog.count
    }

    private var blockingIssuesCount: Int {
        receiptsWithoutClientCount + syncConflictsCount
    }

    private var draftInvoices: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .invoiceClient && $0.status == .pending && monthRange.contains($0.dueDate) }
    }

    private var draftPayrolls: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .payrollEmployee && $0.status == .pending && monthRange.contains($0.dueDate) }
    }

    private var invoicesTotal: Double {
        draftInvoices.reduce(0) { $0 + $1.amount }
    }

    private var payrollTotal: Double {
        draftPayrolls.reduce(0) { $0 + $1.amount }
    }

    private var ctaTitle: String {
        stepIndex == stepTitles.count - 1 ? NSLocalizedString("Finish closing", comment: "") : NSLocalizedString("Continue", comment: "")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    monthPickerCard
                    stepHeader
                    stepContent
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())

            PrimaryBottomCTA(title: ctaTitle, systemImage: "arrow.right.circle.fill") {
                advance()
            }
        }
        .navigationTitle("Monthly closing")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if stepIndex > 0 {
                    Button("Back") { stepIndex -= 1 }
                }
            }
        }
        .alert("Resolve pending issues first", isPresented: $showingBlockedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Fix receipts without client link and resolve sync conflicts before moving forward.")
        }
    }

    private var monthPickerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Closing period")
                    .font(.headline)
                DatePicker("Month", selection: $selectedMonth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                Text("Use this workflow to review issues and confirm invoice/payroll readiness.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var stepHeader: some View {
        AppCard {
            HStack(spacing: 8) {
                ForEach(stepTitles.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .frame(width: 24, height: 24)
                            .background(index <= stepIndex ? AppTheme.primary : Color.gray.opacity(0.25))
                            .foregroundColor(index <= stepIndex ? .white : .secondary)
                            .clipShape(Circle())
                        Text(stepTitles[index])
                            .font(.caption2)
                            .foregroundColor(index == stepIndex ? AppTheme.primary : .secondary)
                            .multilineTextAlignment(.center)
                    }
                    if index < stepTitles.count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch stepIndex {
        case 0:
            AppCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step 1: Select period")
                        .font(.headline)
                    Text("Choose the month to validate pending receipts, invoices and payroll before emission.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        case 1:
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Step 2: Pending checks")
                        .font(.headline)
                    HStack {
                        Text("Receipts without client link")
                        Spacer()
                        Text("\(receiptsWithoutClientCount)")
                            .bold()
                            .foregroundColor(receiptsWithoutClientCount == 0 ? .green : .orange)
                    }
                    HStack {
                        Text("Sync conflicts")
                        Spacer()
                        Text("\(syncConflictsCount)")
                            .bold()
                            .foregroundColor(syncConflictsCount == 0 ? .green : .orange)
                    }
                    if blockingIssuesCount > 0 {
                        Text("Resolve these items to unlock the next step.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        case 2:
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Step 3: Review totals")
                        .font(.headline)
                    HStack {
                        Text("Invoices")
                        Spacer()
                        Text("\(draftInvoices.count)")
                            .bold()
                    }
                    HStack {
                        Text("Payroll")
                        Spacer()
                        Text("\(draftPayrolls.count)")
                            .bold()
                    }
                    Divider()
                    HStack {
                        Text("Receivables")
                        Spacer()
                        Text(formatCurrency(invoicesTotal))
                            .bold()
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Payables")
                        Spacer()
                        Text(formatCurrency(payrollTotal))
                            .bold()
                            .foregroundColor(.red)
                    }
                }
            }
        default:
            AppCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Step 4: Ready to emit")
                        .font(.headline)
                    Text("Your monthly batch is ready. You can continue to invoice emission and payroll confirmation.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Tip: review invoice disputes before sending channels.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func advance() {
        if stepIndex == 1 && blockingIssuesCount > 0 {
            showingBlockedAlert = true
            return
        }
        if stepIndex == stepTitles.count - 1 {
            dismiss()
            return
        }
        stepIndex += 1
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = store.appPreferences.preferredCurrency.code
        return formatter.string(from: NSNumber(value: value)) ?? "\(store.appPreferences.preferredCurrency.code) \(value)"
    }
}

struct ReceiptsHubView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingCaptureCamera = false
    @State private var capturedReceiptImage: UIImage?
    @State private var showingQuickEntry = false
    @State private var showCameraUnavailableAlert = false

    private var pendingSyncCount: Int {
        store.pendingChanges.count
    }

    private var suggestedTask: ServiceTask? {
        store.tasks
            .filter { $0.date >= Calendar.current.startOfDay(for: Date()) && $0.status != .canceled }
            .sorted { $0.date < $1.date }
            .first
    }

    private var suggestedClient: Client? {
        guard let task = suggestedTask else { return nil }
        if let clientId = task.clientId, let byId = store.clients.first(where: { $0.id == clientId }) {
            return byId
        }
        return store.clients.first(where: { $0.name == task.clientName })
    }

    private var latestReceipts: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .expenseOutOfPocket && $0.receiptData != nil }
            .sorted { $0.dueDate > $1.dueDate }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Receipt queue")
                                .font(.headline)
                            HStack {
                                Text("Offline queue")
                                Spacer()
                                Text("\(pendingSyncCount)")
                                    .bold()
                                    .foregroundColor(pendingSyncCount == 0 ? .green : .orange)
                            }
                            Button("Force sync now") {
                                store.syncPendingChanges()
                            }
                            .font(.footnote.bold())
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested context")
                                .font(.headline)
                            if let suggestedTask {
                                Text("Task: \(suggestedTask.title)")
                                    .font(.subheadline)
                                Text("Client: \(suggestedClient?.name ?? suggestedTask.clientName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No suggested task available.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest local receipts")
                                .font(.headline)
                            if latestReceipts.isEmpty {
                                Text("No receipts captured yet.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(latestReceipts) { entry in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.title)
                                                .font(.subheadline.bold())
                                            Text(entry.dueDate, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(formatCurrency(entry.amount))
                                            .font(.subheadline.bold())
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())

            PrimaryBottomCTA(title: "Scan new", systemImage: "camera.fill") {
                openCamera()
            }
        }
        .navigationTitle("Receipts")
        .sheet(isPresented: $showingCaptureCamera) {
            ImagePickerView(
                image: $capturedReceiptImage,
                sourceType: .camera,
                allowPhotoLibraryFallback: false,
                onImagePicked: {
                    showingQuickEntry = capturedReceiptImage != nil
                }
            )
        }
        .sheet(isPresented: $showingQuickEntry, onDismiss: {
            capturedReceiptImage = nil
        }) {
            if let image = capturedReceiptImage {
                QuickReceiptEntrySheet(
                    image: image,
                    suggestedClient: suggestedClient,
                    clients: store.clients
                ) { title, amount, dueDate, client in
                    store.addFinanceEntry(
                        title: title,
                        amount: amount,
                        type: .payable,
                        dueDate: dueDate,
                        method: nil,
                        currency: store.appPreferences.preferredCurrency,
                        clientId: client?.id,
                        clientName: client?.name,
                        employeeName: nil,
                        kind: .expenseOutOfPocket,
                        receiptData: image.jpegData(compressionQuality: 0.7)
                    )
                }
            }
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A device camera is required for receipt capture.")
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        showingCaptureCamera = true
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = store.appPreferences.preferredCurrency.code
        return formatter.string(from: NSNumber(value: value)) ?? "\(store.appPreferences.preferredCurrency.code) \(value)"
    }
}

private struct QuickReceiptEntrySheet: View {
    let image: UIImage
    let suggestedClient: Client?
    let clients: [Client]
    let onSave: (_ title: String, _ amount: Double, _ dueDate: Date, _ client: Client?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = NSLocalizedString("Out-of-pocket expense", comment: "")
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var selectedClientId: UUID?

    init(
        image: UIImage,
        suggestedClient: Client?,
        clients: [Client],
        onSave: @escaping (_ title: String, _ amount: Double, _ dueDate: Date, _ client: Client?) -> Void
    ) {
        self.image = image
        self.suggestedClient = suggestedClient
        self.clients = clients
        self.onSave = onSave
        _selectedClientId = State(initialValue: suggestedClient?.id)
    }

    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        guard let parsedAmount else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Receipt") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 220)
                            .cornerRadius(AppTheme.cornerRadius)
                    }

                    Section("Details") {
                        TextField("Title", text: $title)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }

                    Section("Client (optional)") {
                        Picker("Client", selection: $selectedClientId) {
                            Text("Unlinked").tag(nil as UUID?)
                            ForEach(clients) { client in
                                Text(client.name).tag(client.id as UUID?)
                            }
                        }
                    }
                }

                PrimaryButton(title: "Save receipt") {
                    guard let parsedAmount else { return }
                    let selectedClient = clients.first(where: { $0.id == selectedClientId })
                    onSave(
                        title.trimmingCharacters(in: .whitespacesAndNewlines),
                        parsedAmount,
                        dueDate,
                        selectedClient
                    )
                    dismiss()
                }
                .padding()
                .disabled(!canSave)
            }
            .navigationTitle("New receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct EmissionReadyView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var openInvoices = false

    private var pendingInvoices: [FinanceEntry] {
        store.finance.filter { $0.kind == .invoiceClient && $0.status == .pending }
    }

    private var pendingPayrolls: [FinanceEntry] {
        store.finance.filter { $0.kind == .payrollEmployee && $0.status == .pending }
    }

    private var pendingInvoicesTotal: Double {
        pendingInvoices.reduce(0) { $0 + $1.amount }
    }

    private var pendingPayrollTotal: Double {
        pendingPayrolls.reduce(0) { $0 + $1.amount }
    }

    private var enabledChannels: [String] {
        var channels: [String] = []
        if store.appPreferences.enableWhatsApp { channels.append("WhatsApp") }
        if store.appPreferences.enableEmail { channels.append("Email") }
        if store.appPreferences.enableTextMessages { channels.append("Text") }
        return channels
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready for emission")
                                .font(.headline)
                            HStack {
                                Text("Invoices")
                                Spacer()
                                Text("\(pendingInvoices.count)")
                                    .bold()
                            }
                            HStack {
                                Text("Payroll")
                                Spacer()
                                Text("\(pendingPayrolls.count)")
                                    .bold()
                            }
                            Divider()
                            HStack {
                                Text("Receivables")
                                Spacer()
                                Text(formatCurrency(pendingInvoicesTotal))
                                    .foregroundColor(.green)
                                    .bold()
                            }
                            HStack {
                                Text("Payables")
                                Spacer()
                                Text(formatCurrency(pendingPayrollTotal))
                                    .foregroundColor(.red)
                                    .bold()
                            }
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Delivery channels")
                                .font(.headline)
                            Text("Primary: \(enabledChannels.first ?? "Not configured")")
                                .font(.subheadline)
                            Text("Fallback: \(enabledChannels.dropFirst().first ?? "Not configured")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())

            NavigationLink(isActive: $openInvoices) {
                InvoicesListView()
            } label: {
                EmptyView()
            }
            .hidden()

            PrimaryBottomCTA(title: "Emit now", systemImage: "paperplane.fill", isDisabled: pendingInvoices.isEmpty) {
                openInvoices = true
            }
        }
        .navigationTitle("Emission")
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = store.appPreferences.preferredCurrency.code
        return formatter.string(from: NSNumber(value: value)) ?? "\(store.appPreferences.preferredCurrency.code) \(value)"
    }
}

struct FinanceEntryDetailView: View {
    let entry: FinanceEntry

    var body: some View {
        switch entry.kind {
        case .invoiceClient:
            InvoiceDetailView(entry: entry)
        case .payrollEmployee:
            PayrollDetailView(entry: entry)
        case .expenseOutOfPocket:
            ExpenseDetailView(entry: entry)
        default:
            GenericFinanceDetailView(entry: entry)
        }
    }
}

struct InvoicesListView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingForm = false

    private var invoices: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .invoiceClient }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        List {
            if invoices.isEmpty {
                Text("No invoices yet.")
                    .foregroundColor(.secondary)
            }
            ForEach(invoices) { entry in
                NavigationLink {
                    InvoiceDetailView(entry: entry)
                } label: {
                    InvoiceRow(entry: entry)
                }
            }
            .onDelete { indexSet in
                let items = indexSet.map { invoices[$0] }
                items.forEach { store.deleteFinanceEntry($0) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            InvoiceFormView()
        }
    }
}

private struct InvoiceRow: View {
    let entry: FinanceEntry

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency.code
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title).bold()
                HStack(spacing: 6) {
                    if let client = entry.clientName {
                        Text(client)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text(entry.dueDate, style: .date)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    StatusPill(label: entry.status.label, color: entry.status == .paid ? .green : .orange)
                    if entry.isDisputed {
                        StatusPill(label: NSLocalizedString("Disputed", comment: ""), color: .red)
                    }
                    if entry.supersededById != nil {
                        StatusPill(label: NSLocalizedString("Superseded", comment: ""), color: .gray)
                    }
                }
            }
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: entry.amount)) ?? "-")
                .bold()
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct InvoiceFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedClientName: String = ""
    @State private var amountText: String = ""
    @State private var currency: FinanceEntry.Currency = .usd
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var method: FinanceEntry.PaymentMethod? = nil

    private var clientNames: [String] {
        Array(Set(store.clients.map { $0.name })).sorted()
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        parsedAmount != nil && !title.isEmpty && !selectedClientName.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Invoice") {
                        TextField("Title", text: $title)
                        Picker("Client", selection: $selectedClientName) {
                            Text("Select client").tag("")
                            ForEach(clientNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(store.appPreferences.preferredCurrency.code)
                                .foregroundColor(.secondary)
                        }
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        Picker("Method", selection: $method) {
                            Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                            ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                                Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                            }
                        }
                    }
                }
                PrimaryButton(title: "Save") {
                    save()
                }
                .padding()
                .disabled(!canSave)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedClientName.isEmpty {
                    selectedClientName = clientNames.first ?? ""
                }
                if title.isEmpty, let firstClient = clientNames.first {
                    title = String(format: NSLocalizedString("Invoice - %@", comment: ""), firstClient)
                }
                currency = store.appPreferences.preferredCurrency
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let clientId = store.clients.first(where: { $0.name == selectedClientName })?.id
        store.addFinanceEntry(
            title: title,
            amount: amount,
            type: .receivable,
            dueDate: dueDate,
            method: method,
            currency: store.appPreferences.preferredCurrency,
            clientId: clientId,
            clientName: selectedClientName,
            employeeName: nil,
            kind: .invoiceClient
        )
        dismiss()
    }
}

struct InvoiceDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let entry: FinanceEntry

    @State private var title: String
    @State private var amountText: String
    @State private var dueDate: Date
    @State private var currency: FinanceEntry.Currency
    @State private var method: FinanceEntry.PaymentMethod?
    @State private var status: FinanceEntry.Status
    @State private var isDisputed: Bool
    @State private var disputeReason: String
    @State private var selectedChannel: Client.DeliveryChannel = .email
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var pdfPreview: DocumentPreview?
    @State private var showingReissueConfirm = false

    private struct InvoiceLineItem: Identifiable {
        let id: UUID
        let type: String
        let description: String
        let date: Date
        let pricingModel: ServiceType.PricingModel
        let quantity: Double
        let unitPrice: Double
        let total: Double
    }

    init(entry: FinanceEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _amountText = State(initialValue: String(format: "%.2f", entry.amount))
        _dueDate = State(initialValue: entry.dueDate)
        _currency = State(initialValue: entry.currency)
        _method = State(initialValue: entry.method)
        _status = State(initialValue: entry.status)
        _isDisputed = State(initialValue: entry.isDisputed)
        _disputeReason = State(initialValue: entry.disputeReason ?? "")
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var client: Client? {
        if let clientId = entry.clientId {
            return store.clients.first { $0.id == clientId }
        }
        guard let name = entry.clientName else { return nil }
        return store.clients.first { $0.name == name }
    }

    private var parsedPeriodFromTitle: ClosedRange<Date>? {
        let pattern = #"\(([^)]+)\)"#
        guard let range = entry.title.range(of: pattern, options: .regularExpression) else { return nil }
        let content = String(entry.title[range]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        let parts = content.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        let calendar = Calendar.current
        let year = calendar.component(.year, from: entry.dueDate)
        guard let startRaw = formatter.date(from: parts[0]),
              let endRaw = formatter.date(from: parts[1]),
              let start = calendar.date(bySetting: .year, value: year, of: startRaw),
              let end = calendar.date(bySetting: .year, value: year, of: endRaw) else { return nil }
        return start...end
    }

    private var invoicePeriod: ClosedRange<Date> {
        if let parsed = parsedPeriodFromTitle { return parsed }
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.dueDate)) ?? entry.dueDate
        let end = calendar.date(byAdding: .month, value: 1, to: start)
            .flatMap { calendar.date(byAdding: .day, value: -1, to: $0) } ?? entry.dueDate
        return start...end
    }

    private var lineItems: [InvoiceLineItem] {
        let tasksForInvoice = store.tasks.filter { task in
            let matchesClient: Bool
            if let clientId = entry.clientId {
                matchesClient = task.clientId == clientId
            } else if let clientName = entry.clientName {
                matchesClient = task.clientName == clientName
            } else {
                matchesClient = false
            }
            return matchesClient && invoicePeriod.contains(task.date)
        }

        let items: [InvoiceLineItem] = tasksForInvoice.compactMap { task in
            guard let typeId = task.serviceTypeId,
                  let serviceType = store.serviceTypes.first(where: { $0.id == typeId }),
                  serviceType.currency == entry.currency else { return nil }
            var quantity = 0.0
            switch serviceType.pricingModel {
            case .perTask:
                quantity = 1
            case .perHour:
                guard let checkIn = task.checkInTime, let checkOut = task.checkOutTime else {
                    return InvoiceLineItem(
                        id: task.id,
                        type: serviceType.name,
                        description: task.title,
                        date: task.date,
                        pricingModel: serviceType.pricingModel,
                        quantity: 0,
                        unitPrice: serviceType.basePrice,
                        total: 0
                    )
                }
                let hours = checkOut.timeIntervalSince(checkIn) / 3600.0
                quantity = max(0, hours)
            }

            let roundedQuantity = (quantity * 100).rounded() / 100
            let total = roundedQuantity * serviceType.basePrice

            return InvoiceLineItem(
                id: task.id,
                type: serviceType.name,
                description: task.title,
                date: task.date,
                pricingModel: serviceType.pricingModel,
                quantity: roundedQuantity,
                unitPrice: serviceType.basePrice,
                total: total
            )
        }

        if items.isEmpty {
            return [
                InvoiceLineItem(
                    id: entry.id,
                    type: NSLocalizedString("Service", comment: ""),
                    description: entry.title,
                    date: entry.dueDate,
                    pricingModel: .perTask,
                    quantity: 1,
                    unitPrice: entry.amount,
                    total: entry.amount
                )
            ]
        }
        return items.sorted { $0.date < $1.date }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let activeCurrency = store.appPreferences.preferredCurrency
        formatter.currencyCode = activeCurrency.code
        return formatter.string(from: NSNumber(value: value))
            ?? String(format: "%@ %.2f", activeCurrency.code, value)
    }

    private func quantityLabel(for item: InvoiceLineItem) -> String {
        switch item.pricingModel {
        case .perTask:
            return NSLocalizedString("1 task", comment: "")
        case .perHour:
            return String(format: NSLocalizedString("%.2f h", comment: ""), item.quantity)
        }
    }

    private var managerChannels: [Client.DeliveryChannel] {
        var channels: [Client.DeliveryChannel] = []
        if store.appPreferences.enableWhatsApp { channels.append(.whatsapp) }
        if store.appPreferences.enableTextMessages { channels.append(.sms) }
        if store.appPreferences.enableEmail { channels.append(.email) }
        return channels
    }

    private var availableChannels: [Client.DeliveryChannel] {
        guard let client else { return [] }
        let base = managerChannels.filter { channelHasContact($0) }
        let preferred = client.preferredDeliveryChannels
        if preferred.isEmpty {
            return base
        }
        return base.filter { preferred.contains($0) }
    }

    private func channelHasContact(_ channel: Client.DeliveryChannel) -> Bool {
        guard let client else { return false }
        switch channel {
        case .email:
            return !client.email.isEmpty
        case .sms:
            return !client.phone.isEmpty
        case .whatsapp:
            return !client.whatsappPhone.isEmpty || !client.phone.isEmpty
        }
    }

    private var canAdjustInvoice: Bool {
        let calendar = Calendar.current
        let limit = calendar.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        return !isSuperseded && Date() <= limit
    }

    private var disputeDeadline: Date {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: dueDate)
        return calendar.date(byAdding: .day, value: store.appPreferences.disputeWindowDays + 1, to: base) ?? dueDate
    }

    private var disputeWindowOpen: Bool {
        Date() < disputeDeadline
    }

    private var isSuperseded: Bool {
        entry.supersededById != nil
    }

    private var canSave: Bool {
        guard let amount = parsedAmount else { return false }
        if isDisputed && disputeReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        return !isSuperseded && amount > 0 && !title.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Invoice") {
                    TextField("Title", text: $title)
                        .disabled(!canAdjustInvoice)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .disabled(!canAdjustInvoice)
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(store.appPreferences.preferredCurrency.code)
                            .foregroundColor(.secondary)
                    }
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        .disabled(!canAdjustInvoice)
                    Picker("Method", selection: $method) {
                        Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                        ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                            Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                        }
                    }
                    Picker("Status", selection: $status) {
                        Text(FinanceEntry.Status.pending.label).tag(FinanceEntry.Status.pending)
                        Text(FinanceEntry.Status.paid.label).tag(FinanceEntry.Status.paid)
                    }
                }

                Section("Line items") {
                    ForEach(lineItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.type)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(formatCurrency(item.total))
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.primary)
                            }
                            Text(item.description)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text(String(format: NSLocalizedString("Qty: %@ · Unit: %@ · Total: %@", comment: ""), quantityLabel(for: item), formatCurrency(item.unitPrice), formatCurrency(item.total)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Dispute") {
                    Toggle("Client disputed", isOn: $isDisputed)
                        .disabled(!disputeWindowOpen && !isDisputed)
                    TextField("Client message / reason", text: $disputeReason, axis: .vertical)
                        .lineLimit(2...4)
                        .disabled(!isDisputed)
                    if disputeWindowOpen {
                        let deadlineText = disputeDeadline.formatted(date: .abbreviated, time: .omitted)
                        let windowText = store.appPreferences.disputeWindowDays == 0
                            ? NSLocalizedString("Disputes are allowed until the due date.", comment: "")
                            : String(format: NSLocalizedString("Disputes are allowed until %@.", comment: ""), deadlineText)
                        Text(windowText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        let deadlineText = disputeDeadline.formatted(date: .abbreviated, time: .omitted)
                        Text(String(format: NSLocalizedString("Dispute window closed on %@.", comment: ""), deadlineText))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Send invoice") {
                    if isSuperseded {
                        let dateText = entry.supersededAt?.formatted(date: .abbreviated, time: .shortened) ?? "-"
                        Text(String(format: NSLocalizedString("Superseded on %@", comment: ""), dateText))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let client {
                        let channelLabels = availableChannels.map { $0.label }.joined(separator: ", ")
                        if !channelLabels.isEmpty {
                            Text(String(format: NSLocalizedString("Available channels: %@", comment: ""), channelLabels))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Picker("Channel", selection: $selectedChannel) {
                                ForEach(availableChannels) { channel in
                                    Text(channel.label).tag(channel)
                                }
                            }
                        } else {
                            Text(NSLocalizedString("No available channels. Add phone or email for this client.", comment: ""))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button {
                        prepareShare()
                    } label: {
                        Label("Send / Reissue", systemImage: "square.and.arrow.up")
                    }
                    .disabled(availableChannels.isEmpty)
                    Button {
                        preparePDFShare()
                    } label: {
                        Label("Generate PDF", systemImage: "doc.richtext")
                    }
                    if let url = makeChannelURL() {
                        Button {
                            openURL(url)
                        } label: {
                            Label(String(format: NSLocalizedString("Open %@", comment: ""), selectedChannel.label), systemImage: "paperplane.fill")
                        }
                    }
                    if !canAdjustInvoice {
                        Text("Adjustments are blocked less than 1 day before due date.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Reissue") {
                    Button {
                        showingReissueConfirm = true
                    } label: {
                        Label("Reissue invoice", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .disabled(isSuperseded)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") { save() }
                .padding()
                .disabled(!canSave)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Invoice")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(items: shareItems)
        }
        .sheet(item: $pdfPreview) { preview in
            PDFPreviewController(url: preview.url)
                .ignoresSafeArea()
        }
        .confirmationDialog("Reissue invoice?", isPresented: $showingReissueConfirm) {
            Button("Reissue invoice", role: .destructive) {
                reissueInvoice()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            if let firstChannel = availableChannels.first {
                selectedChannel = firstChannel
            }
            currency = store.appPreferences.preferredCurrency
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let trimmedReason = disputeReason.trimmingCharacters(in: .whitespacesAndNewlines)

        store.updateFinanceEntry(entry) { current in
            current.title = title
            current.amount = amount
            current.dueDate = dueDate
            current.currency = store.appPreferences.preferredCurrency
            current.method = method
            current.status = status
            current.isDisputed = isDisputed
            current.disputeReason = isDisputed ? trimmedReason : nil
        }
        dismiss()
    }

    private func reissueInvoice() {
        let recomputedTotal = lineItems.reduce(0) { $0 + $1.total }
        let finalAmount = recomputedTotal > 0 ? recomputedTotal : entry.amount
        store.reissueInvoice(entry, amount: finalAmount, dueDate: dueDate)
    }

    private func prepareShare() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let activeCurrency = store.appPreferences.preferredCurrency
        formatter.currencyCode = activeCurrency.code
        let amountString = formatter.string(from: NSNumber(value: parsedAmount ?? entry.amount)) ?? "\(activeCurrency.code) \(parsedAmount ?? entry.amount)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueString = dateFormatter.string(from: dueDate)

        var body = String(
            format: NSLocalizedString("Invoice: %@\nAmount: %@\nDue: %@", comment: ""),
            title,
            amountString,
            dueString
        )
        if let clientName = entry.clientName {
            body.append(String(format: NSLocalizedString("\nClient: %@", comment: ""), clientName))
        }
        if !lineItems.isEmpty {
            body.append(NSLocalizedString("\n\nLine items:", comment: ""))
            for item in lineItems {
                body.append(
                    String(
                        format: NSLocalizedString("\n- %@ | %@ | %@ | Unit: %@ | Total: %@", comment: ""),
                        item.type,
                        item.description,
                        quantityLabel(for: item),
                        formatCurrency(item.unitPrice),
                        formatCurrency(item.total)
                    )
                )
            }
        }
        body.append(String(format: NSLocalizedString("\nChannel: %@", comment: ""), selectedChannel.label))
        if isDisputed {
            let reason = disputeReason.isEmpty ? NSLocalizedString("Pending reason", comment: "") : disputeReason
            body.append(String(format: NSLocalizedString("\nStatus: DISPUTED - %@", comment: ""), reason))
        }

        shareItems = [body]
        showingShareSheet = true
    }

    private func preparePDFShare() {
        let pdfData = buildInvoicePDF()
        let fileName = "\(entry.title.replacingOccurrences(of: " ", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        do {
            try pdfData.write(to: url)
            shareItems = [url]
            showingShareSheet = true
            pdfPreview = DocumentPreview(url: url)
        } catch {
            shareItems = [pdfData]
            showingShareSheet = true
        }
    }

    private func buildInvoicePDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        let activeCurrency = store.appPreferences.preferredCurrency
        numberFormatter.currencyCode = activeCurrency.code

        let instructions = String(
            format: NSLocalizedString("Please pay via %@ by %@.", comment: ""),
            method?.label ?? selectedChannel.label,
            dateFormatter.string(from: dueDate)
        )
        let companyProfile = store.appPreferences.companyProfile
        let clientName = entry.clientName ?? NSLocalizedString("Client", comment: "")
        let disputeURL = makeDisputeURL()

        return renderer.pdfData { context in
            context.beginPage()
            let margin: CGFloat = 24
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                let size = attributed.boundingRect(
                    with: CGSize(width: pageRect.width - margin * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                attributed.draw(in: CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: size.height))
                y += size.height + 8
            }

            func drawLink(_ text: String, url: URL, font: UIFont, color: UIColor = .systemBlue) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: text, attributes: attrs)
                let size = attributed.boundingRect(
                    with: CGSize(width: pageRect.width - margin * 2, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                let rect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: size.height)
                attributed.draw(in: rect)
                context.setURL(url, for: rect)
                y += size.height + 8
            }

            if let companyProfile {
                if let logoData = companyProfile.logoData, let logoImage = UIImage(data: logoData) {
                    let maxLogoWidth: CGFloat = 140
                    let maxLogoHeight: CGFloat = 64
                    let widthRatio = maxLogoWidth / max(logoImage.size.width, 1)
                    let heightRatio = maxLogoHeight / max(logoImage.size.height, 1)
                    let ratio = min(widthRatio, heightRatio)
                    let drawWidth = logoImage.size.width * ratio
                    let drawHeight = logoImage.size.height * ratio
                    let logoRect = CGRect(x: margin, y: y, width: drawWidth, height: drawHeight)
                    logoImage.draw(in: logoRect)
                    y += drawHeight + 8
                }
                if !companyProfile.legalName.isEmpty {
                    draw(companyProfile.legalName, font: .boldSystemFont(ofSize: 14))
                }
                let companyAddress = [companyProfile.addressLine1, companyProfile.addressLine2]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                if !companyAddress.isEmpty {
                    draw(companyAddress, font: .systemFont(ofSize: 11), color: .darkGray)
                }
                let cityLine = [companyProfile.city, companyProfile.region, companyProfile.postalCode]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                if !cityLine.isEmpty {
                    draw(cityLine, font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if !companyProfile.countryName.isEmpty {
                    draw(companyProfile.countryName, font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if !companyProfile.taxIdentifier.isEmpty {
                    draw(
                        String(
                            format: NSLocalizedString("%@: %@", comment: ""),
                            companyProfile.taxCountry.taxIdLabel,
                            companyProfile.taxIdentifier
                        ),
                        font: .systemFont(ofSize: 11),
                        color: .darkGray
                    )
                }
                if !companyProfile.contactEmail.isEmpty {
                    draw(String(format: NSLocalizedString("Company email: %@", comment: ""), companyProfile.contactEmail), font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if !companyProfile.contactPhone.isEmpty {
                    draw(String(format: NSLocalizedString("Company phone: %@", comment: ""), companyProfile.contactPhone), font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if !companyProfile.website.isEmpty {
                    draw(String(format: NSLocalizedString("Website: %@", comment: ""), companyProfile.website), font: .systemFont(ofSize: 11), color: .darkGray)
                }
                y += 8
            }

            draw(NSLocalizedString("Invoice", comment: ""), font: .boldSystemFont(ofSize: 22))
            draw(String(format: NSLocalizedString("Client: %@", comment: ""), clientName), font: .systemFont(ofSize: 14))
            if let email = client?.email, !email.isEmpty {
                draw(String(format: NSLocalizedString("Email: %@", comment: ""), email), font: .systemFont(ofSize: 12), color: .darkGray)
            }
            if let phone = client?.phone, !phone.isEmpty {
                draw(String(format: NSLocalizedString("Phone: %@", comment: ""), phone), font: .systemFont(ofSize: 12), color: .darkGray)
            }
            draw(String(format: NSLocalizedString("Due date: %@", comment: ""), dateFormatter.string(from: dueDate)), font: .systemFont(ofSize: 14))
            draw(instructions, font: .systemFont(ofSize: 12))
            if let disputeURL {
                drawLink(NSLocalizedString("Dispute this invoice", comment: ""), url: disputeURL, font: .systemFont(ofSize: 12))
            }

            y += 8
            draw(NSLocalizedString("Line items", comment: ""), font: .boldSystemFont(ofSize: 16))

            for item in lineItems {
                draw(
                    String(
                        format: NSLocalizedString("- %@ (%@)", comment: ""),
                        item.type,
                        dateFormatter.string(from: item.date)
                    ),
                    font: .systemFont(ofSize: 12)
                )
                draw(item.description, font: .systemFont(ofSize: 11), color: .darkGray)
                draw(
                    String(
                        format: NSLocalizedString("Qty: %@ | Unit: %@ | Total: %@", comment: ""),
                        quantityLabel(for: item),
                        numberFormatter.string(from: NSNumber(value: item.unitPrice))
                            ?? String(format: "%@ %.2f", activeCurrency.code, item.unitPrice),
                        numberFormatter.string(from: NSNumber(value: item.total))
                            ?? String(format: "%@ %.2f", activeCurrency.code, item.total)
                    ),
                    font: .systemFont(ofSize: 11),
                    color: .darkGray
                )
            }

            let totalString = numberFormatter.string(from: NSNumber(value: parsedAmount ?? entry.amount))
                ?? String(format: "%@ %.2f", activeCurrency.code, parsedAmount ?? entry.amount)
            y += 8
            draw(String(format: NSLocalizedString("Total: %@", comment: ""), totalString), font: .boldSystemFont(ofSize: 14))

            if isDisputed {
                let reason = disputeReason.isEmpty ? NSLocalizedString("Pending reason", comment: "") : disputeReason
                draw(String(format: NSLocalizedString("Status: DISPUTED - %@", comment: ""), reason), font: .boldSystemFont(ofSize: 12), color: .red)
            }
        }
    }

    private func makeChannelURL() -> URL? {
        guard let client else { return nil }
        switch selectedChannel {
        case .email:
            guard !client.email.isEmpty else { return nil }
            let subject = String(format: NSLocalizedString("Invoice %@", comment: ""), title)
            let body = String(
                format: NSLocalizedString("Hello %@, here is your invoice %@.", comment: ""),
                client.name,
                title
            )
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "mailto:\(client.email)?subject=\(encodedSubject)&body=\(encodedBody)")
        case .whatsapp:
            let targetPhone = client.whatsappPhone.isEmpty ? client.phone : client.whatsappPhone
            guard !targetPhone.isEmpty else { return nil }
            let digits = targetPhone.filter { $0.isNumber || $0 == "+" }
            let text = String(
                format: NSLocalizedString("Invoice %@ - due %@", comment: ""),
                title,
                dueDate.formatted(date: .abbreviated, time: .omitted)
            )
            let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        case .sms:
            guard !client.phone.isEmpty else { return nil }
            let digits = client.phone.filter { $0.isNumber || $0 == "+" }
            return URL(string: "sms:\(digits)")
        }
    }

    private func makeDisputeURL() -> URL? {
        guard let client else { return nil }
        let channels = availableChannels
        for channel in channels {
            if let url = disputeURL(for: channel, client: client) {
                return url
            }
        }
        return disputeURL(for: .email, client: client)
            ?? disputeURL(for: .sms, client: client)
            ?? disputeURL(for: .whatsapp, client: client)
    }

    private func disputeURL(for channel: Client.DeliveryChannel, client: Client) -> URL? {
        let subject = String(format: NSLocalizedString("Dispute invoice %@", comment: ""), title)
        let body = String(
            format: NSLocalizedString("Hello %@, I would like to dispute invoice %@.", comment: ""),
            client.name,
            title
        )
        switch channel {
        case .email:
            guard !client.email.isEmpty else { return nil }
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "mailto:\(client.email)?subject=\(encodedSubject)&body=\(encodedBody)")
        case .whatsapp:
            let targetPhone = client.whatsappPhone.isEmpty ? client.phone : client.whatsappPhone
            guard !targetPhone.isEmpty else { return nil }
            let digits = targetPhone.filter { $0.isNumber || $0 == "+" }
            let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        case .sms:
            guard !client.phone.isEmpty else { return nil }
            let digits = client.phone.filter { $0.isNumber || $0 == "+" }
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "sms:\(digits)&body=\(encodedBody)")
        }
    }
}

private struct DocumentPreview: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct PDFPreviewController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct PayrollListView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingForm = false

    private var payrolls: [FinanceEntry] {
        store.finance
            .filter { $0.kind == .payrollEmployee }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        List {
            if payrolls.isEmpty {
                Text("No payroll entries yet.")
                    .foregroundColor(.secondary)
            }
            ForEach(payrolls) { entry in
                NavigationLink {
                    PayrollDetailView(entry: entry)
                } label: {
                    PayrollRow(entry: entry)
                }
            }
            .onDelete { indexSet in
                let items = indexSet.map { payrolls[$0] }
                items.forEach { store.deleteFinanceEntry($0) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Payroll")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            PayrollFormView()
        }
    }
}

private struct PayrollRow: View {
    let entry: FinanceEntry

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency.code
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title).bold()
                if let employee = entry.employeeName {
                    Text(employee)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text(entry.dueDate, style: .date)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(currencyFormatter.string(from: NSNumber(value: entry.amount)) ?? "-")
                    .bold()
                StatusPill(label: entry.status.label, color: entry.status == .paid ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PayrollFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedEmployeeName: String = ""
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var periodStart: Date = {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: comps) ?? now
    }()
    @State private var periodEnd: Date = Date()
    @State private var method: FinanceEntry.PaymentMethod? = nil
    @State private var showingConfirmation = false
    @State private var hoursWorkedText: String = ""
    @State private var daysWorkedText: String = ""
    @State private var hourlyRateText: String = ""
    @State private var bonusText: String = ""
    @State private var deductionsText: String = ""
    @State private var taxesText: String = ""
    @State private var reimbursementsText: String = ""
    @State private var payrollNotes: String = ""

    private var employeeNames: [String] {
        Array(Set(store.employees.map { $0.name })).sorted()
    }

    private var hoursWorked: Double {
        parseDouble(hoursWorkedText)
    }

    private var daysWorked: Int {
        parseInt(daysWorkedText)
    }

    private var hourlyRate: Double {
        parseDouble(hourlyRateText)
    }

    private var bonus: Double {
        parseDouble(bonusText)
    }

    private var deductions: Double {
        parseDouble(deductionsText)
    }

    private var taxes: Double {
        parseDouble(taxesText)
    }

    private var reimbursements: Double {
        parseDouble(reimbursementsText)
    }

    private var computedDaysFromPeriod: Int {
        daysBetween(start: periodStart, end: periodEnd)
    }

    private var finalDaysWorked: Int {
        daysWorkedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? computedDaysFromPeriod
            : daysWorked
    }

    private var basePay: Double {
        let computed = hoursWorked * hourlyRate
        if computed == 0, entry.payrollBasePay > 0 {
            return entry.payrollBasePay
        }
        return computed
    }

    private var netPay: Double {
        let computed = basePay + bonus + reimbursements - deductions - taxes
        if computed == 0 {
            if entry.payrollNetPay > 0 { return entry.payrollNetPay }
            if entry.amount > 0 { return entry.amount }
        }
        return computed
    }

    private var canSave: Bool {
        netPay > 0 && !selectedEmployeeName.isEmpty && !title.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Payroll") {
                        TextField("Title", text: $title)
                        Picker("Employee", selection: $selectedEmployeeName) {
                            Text("Select employee").tag("")
                            ForEach(employeeNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(store.appPreferences.preferredCurrency.code)
                                .foregroundColor(.secondary)
                        }
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        Picker("Method", selection: $method) {
                            Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                            ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                                Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                            }
                        }
                    }
                    Section(NSLocalizedString("Period", comment: "")) {
                        DatePicker(NSLocalizedString("From", comment: ""), selection: $periodStart, displayedComponents: .date)
                        DatePicker(NSLocalizedString("To", comment: ""), selection: $periodEnd, displayedComponents: .date)
                        TextField(NSLocalizedString("Days worked", comment: ""), text: $daysWorkedText)
                            .keyboardType(.numberPad)
                        Text(String(format: NSLocalizedString("Calculated days: %d", comment: ""), computedDaysFromPeriod))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Section(NSLocalizedString("Breakdown", comment: "")) {
                        TextField(NSLocalizedString("Hours worked", comment: ""), text: $hoursWorkedText)
                            .keyboardType(.decimalPad)
                        TextField(NSLocalizedString("Hourly rate", comment: ""), text: $hourlyRateText)
                            .keyboardType(.decimalPad)
                        Text(String(format: NSLocalizedString("Base pay: %@ %.2f", comment: ""), store.appPreferences.preferredCurrency.code, basePay))
                            .font(.subheadline)
                        TextField(NSLocalizedString("Bonus", comment: ""), text: $bonusText)
                            .keyboardType(.decimalPad)
                        TextField(NSLocalizedString("Deductions", comment: ""), text: $deductionsText)
                            .keyboardType(.decimalPad)
                        TextField(NSLocalizedString("Taxes", comment: ""), text: $taxesText)
                            .keyboardType(.decimalPad)
                        TextField(NSLocalizedString("Reimbursements", comment: ""), text: $reimbursementsText)
                            .keyboardType(.decimalPad)
                        Text(String(format: NSLocalizedString("Net pay: %@ %.2f", comment: ""), store.appPreferences.preferredCurrency.code, netPay))
                            .font(.headline)
                    }
                    Section(NSLocalizedString("Notes", comment: "")) {
                        TextEditor(text: $payrollNotes)
                            .frame(minHeight: 80)
                    }
                }
                PrimaryButton(title: "Save") {
                    showingConfirmation = true
                }
                .padding()
                .disabled(!canSave)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Payroll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Confirm payroll", isPresented: $showingConfirmation) {
                Button("Create") { save() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This payroll entry is manual. Confirm to continue.")
            }
            .onAppear {
                if selectedEmployeeName.isEmpty {
                    selectedEmployeeName = employeeNames.first ?? ""
                }
                if title.isEmpty, let employee = employeeNames.first {
                    title = String(format: NSLocalizedString("Payroll - %@", comment: ""), employee)
                }
                if hourlyRateText.isEmpty, let employee = store.employees.first(where: { $0.name == selectedEmployeeName }) {
                    if let rate = employee.hourlyRate {
                        hourlyRateText = String(format: "%.2f", rate)
                    }
                }
            }
            .onChange(of: selectedEmployeeName) { newValue in
                if title.isEmpty {
                    title = String(format: NSLocalizedString("Payroll - %@", comment: ""), newValue)
                }
                if hourlyRateText.isEmpty,
                   let employee = store.employees.first(where: { $0.name == newValue }),
                   let rate = employee.hourlyRate {
                    hourlyRateText = String(format: "%.2f", rate)
                }
            }
        }
    }

    private func save() {
        let employeeId = store.employees.first(where: { $0.name == selectedEmployeeName })?.id
        store.addFinanceEntry(
            title: title,
            amount: netPay,
            type: .payable,
            dueDate: dueDate,
            method: method,
            currency: store.appPreferences.preferredCurrency,
            clientName: nil,
            employeeId: employeeId,
            employeeName: selectedEmployeeName,
            kind: .payrollEmployee,
            payrollPeriodStart: periodStart,
            payrollPeriodEnd: periodEnd,
            payrollHoursWorked: hoursWorked,
            payrollDaysWorked: finalDaysWorked,
            payrollHourlyRate: hourlyRate,
            payrollBasePay: basePay,
            payrollBonus: bonus,
            payrollDeductions: deductions,
            payrollTaxes: taxes,
            payrollReimbursements: reimbursements,
            payrollNetPay: netPay,
            payrollNotes: payrollNotes.isEmpty ? nil : payrollNotes
        )
        dismiss()
    }

    private func parseDouble(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func parseInt(_ text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard endDay >= startDay else { return 0 }
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return (components.day ?? 0) + 1
    }
}

struct PayrollDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    let entry: FinanceEntry

    @State private var title: String
    @State private var dueDate: Date
    @State private var currency: FinanceEntry.Currency
    @State private var method: FinanceEntry.PaymentMethod?
    @State private var status: FinanceEntry.Status
    @State private var periodStart: Date
    @State private var periodEnd: Date
    @State private var hoursWorkedText: String
    @State private var daysWorkedText: String
    @State private var hourlyRateText: String
    @State private var bonusText: String
    @State private var deductionsText: String
    @State private var taxesText: String
    @State private var reimbursementsText: String
    @State private var payrollNotes: String

    init(entry: FinanceEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _dueDate = State(initialValue: entry.dueDate)
        _currency = State(initialValue: entry.currency)
        _method = State(initialValue: entry.method)
        _status = State(initialValue: entry.status)
        _periodStart = State(initialValue: entry.payrollPeriodStart ?? entry.dueDate)
        _periodEnd = State(initialValue: entry.payrollPeriodEnd ?? entry.dueDate)
        _hoursWorkedText = State(initialValue: entry.payrollHoursWorked > 0 ? String(format: "%.2f", entry.payrollHoursWorked) : "")
        _daysWorkedText = State(initialValue: entry.payrollDaysWorked > 0 ? "\(entry.payrollDaysWorked)" : "")
        _hourlyRateText = State(initialValue: entry.payrollHourlyRate > 0 ? String(format: "%.2f", entry.payrollHourlyRate) : "")
        _bonusText = State(initialValue: entry.payrollBonus > 0 ? String(format: "%.2f", entry.payrollBonus) : "")
        _deductionsText = State(initialValue: entry.payrollDeductions > 0 ? String(format: "%.2f", entry.payrollDeductions) : "")
        _taxesText = State(initialValue: entry.payrollTaxes > 0 ? String(format: "%.2f", entry.payrollTaxes) : "")
        _reimbursementsText = State(initialValue: entry.payrollReimbursements > 0 ? String(format: "%.2f", entry.payrollReimbursements) : "")
        _payrollNotes = State(initialValue: entry.payrollNotes ?? "")
    }

    private var isManager: Bool {
        store.session?.role == .manager
    }

    private var hoursWorked: Double {
        parseDouble(hoursWorkedText)
    }

    private var daysWorked: Int {
        parseInt(daysWorkedText)
    }

    private var hourlyRate: Double {
        parseDouble(hourlyRateText)
    }

    private var bonus: Double {
        parseDouble(bonusText)
    }

    private var deductions: Double {
        parseDouble(deductionsText)
    }

    private var taxes: Double {
        parseDouble(taxesText)
    }

    private var reimbursements: Double {
        parseDouble(reimbursementsText)
    }

    private var computedDaysFromPeriod: Int {
        daysBetween(start: periodStart, end: periodEnd)
    }

    private var finalDaysWorked: Int {
        daysWorkedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? computedDaysFromPeriod
            : daysWorked
    }

    private var basePay: Double {
        hoursWorked * hourlyRate
    }

    private var netPay: Double {
        basePay + bonus + reimbursements - deductions - taxes
    }

    private var canEditFields: Bool {
        status == .pending && isManager
    }

    private var canSave: Bool {
        isManager && netPay > 0 && !title.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Payroll") {
                    if let employee = entry.employeeName {
                        Text(String(format: NSLocalizedString("Employee: %@", comment: ""), employee))
                            .font(.subheadline)
                    }
                    TextField("Title", text: $title)
                        .disabled(!canEditFields)
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(store.appPreferences.preferredCurrency.code)
                            .foregroundColor(.secondary)
                    }
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        .disabled(!canEditFields)
                    Picker("Method", selection: $method) {
                        Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                        ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                            Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                        }
                    }
                    Picker("Status", selection: $status) {
                        Text(FinanceEntry.Status.pending.label).tag(FinanceEntry.Status.pending)
                        Text(FinanceEntry.Status.paid.label).tag(FinanceEntry.Status.paid)
                    }
                }
                Section(NSLocalizedString("Period", comment: "")) {
                    DatePicker(NSLocalizedString("From", comment: ""), selection: $periodStart, displayedComponents: .date)
                        .disabled(!canEditFields)
                    DatePicker(NSLocalizedString("To", comment: ""), selection: $periodEnd, displayedComponents: .date)
                        .disabled(!canEditFields)
                    TextField(NSLocalizedString("Days worked", comment: ""), text: $daysWorkedText)
                        .keyboardType(.numberPad)
                        .disabled(!canEditFields)
                    Text(String(format: NSLocalizedString("Calculated days: %d", comment: ""), computedDaysFromPeriod))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section(NSLocalizedString("Breakdown", comment: "")) {
                    TextField(NSLocalizedString("Hours worked", comment: ""), text: $hoursWorkedText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    TextField(NSLocalizedString("Hourly rate", comment: ""), text: $hourlyRateText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    Text(String(format: NSLocalizedString("Base pay: %@ %.2f", comment: ""), store.appPreferences.preferredCurrency.code, basePay))
                        .font(.subheadline)
                    TextField(NSLocalizedString("Bonus", comment: ""), text: $bonusText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    TextField(NSLocalizedString("Deductions", comment: ""), text: $deductionsText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    TextField(NSLocalizedString("Taxes", comment: ""), text: $taxesText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    TextField(NSLocalizedString("Reimbursements", comment: ""), text: $reimbursementsText)
                        .keyboardType(.decimalPad)
                        .disabled(!canEditFields)
                    Text(String(format: NSLocalizedString("Net pay: %@ %.2f", comment: ""), store.appPreferences.preferredCurrency.code, netPay))
                        .font(.headline)
                }
                Section(NSLocalizedString("Notes", comment: "")) {
                    TextEditor(text: $payrollNotes)
                        .frame(minHeight: 80)
                        .disabled(!canEditFields)
                }
                if !canEditFields {
                    Text("Editing is locked after payment confirmation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") { save() }
                .padding()
                .disabled(!canSave)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Payroll")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            currency = store.appPreferences.preferredCurrency
        }
    }

    private func save() {
        store.updateFinanceEntry(entry) { current in
            current.title = title
            current.amount = netPay
            current.dueDate = dueDate
            current.currency = store.appPreferences.preferredCurrency
            current.method = method
            current.status = status
            current.payrollPeriodStart = periodStart
            current.payrollPeriodEnd = periodEnd
            current.payrollHoursWorked = hoursWorked
            current.payrollDaysWorked = finalDaysWorked
            current.payrollHourlyRate = hourlyRate
            current.payrollBasePay = basePay
            current.payrollBonus = bonus
            current.payrollDeductions = deductions
            current.payrollTaxes = taxes
            current.payrollReimbursements = reimbursements
            current.payrollNetPay = netPay
            current.payrollNotes = payrollNotes.isEmpty ? nil : payrollNotes
        }
        dismiss()
    }

    private func parseDouble(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func parseInt(_ text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard endDay >= startDay else { return 0 }
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return (components.day ?? 0) + 1
    }
}

struct GenericFinanceDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    let entry: FinanceEntry
    @State private var status: FinanceEntry.Status
    @State private var method: FinanceEntry.PaymentMethod?

    init(entry: FinanceEntry) {
        self.entry = entry
        _status = State(initialValue: entry.status)
        _method = State(initialValue: entry.method)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Entry") {
                    Text(entry.title).bold()
                    Text(entry.dueDate, style: .date)
                        .foregroundColor(.secondary)
                    if let client = entry.clientName {
                        Text(String(format: NSLocalizedString("Client: %@", comment: ""), client))
                            .font(.footnote)
                    }
                    if let employee = entry.employeeName {
                        Text(String(format: NSLocalizedString("Employee: %@", comment: ""), employee))
                            .font(.footnote)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text(FinanceEntry.Status.pending.label).tag(FinanceEntry.Status.pending)
                        Text(FinanceEntry.Status.paid.label).tag(FinanceEntry.Status.paid)
                    }
                    Picker("Method", selection: $method) {
                        Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                        ForEach(FinanceEntry.PaymentMethod.allCases) { value in
                            Text(value.label).tag(value as FinanceEntry.PaymentMethod?)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") {
                store.updateFinanceEntry(entry) { current in
                    current.status = status
                    current.method = method
                }
                dismiss()
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Finance entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct ExpenseDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    let entry: FinanceEntry
    @State private var status: FinanceEntry.Status
    @State private var method: FinanceEntry.PaymentMethod?
    @State private var showingShareSheet = false
    @State private var showingReceiptPreview = false
    @State private var shareItems: [Any] = []

    init(entry: FinanceEntry) {
        self.entry = entry
        _status = State(initialValue: entry.status)
        _method = State(initialValue: entry.method)
    }

    private var receiptImage: UIImage? {
        guard let data = entry.receiptData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Expense") {
                    Text(entry.title).bold()
                    Text(entry.dueDate, style: .date)
                        .foregroundColor(.secondary)
                    if let client = entry.clientName, !client.isEmpty {
                        Text(String(format: NSLocalizedString("Client: %@", comment: ""), client))
                            .font(.footnote)
                    }
                    Text(String(format: NSLocalizedString("Amount: %@ %.2f", comment: ""), entry.currency.code, entry.amount))
                        .font(.subheadline)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text(FinanceEntry.Status.pending.label).tag(FinanceEntry.Status.pending)
                        Text(FinanceEntry.Status.paid.label).tag(FinanceEntry.Status.paid)
                    }
                    Picker("Method", selection: $method) {
                        Text("None").tag(nil as FinanceEntry.PaymentMethod?)
                        ForEach(FinanceEntry.PaymentMethod.allCases) { value in
                            Text(value.label).tag(value as FinanceEntry.PaymentMethod?)
                        }
                    }
                }

                if let receiptImage {
                    Section("Receipt") {
                        Button {
                            showingReceiptPreview = true
                        } label: {
                            Image(uiImage: receiptImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        .buttonStyle(.plain)
                        Button {
                            shareReceipt()
                        } label: {
                            Label("Share receipt", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") {
                store.updateFinanceEntry(entry) { current in
                    current.status = status
                    current.method = method
                }
                dismiss()
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Expense")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(items: shareItems)
        }
        .sheet(isPresented: $showingReceiptPreview) {
            if let receiptImage {
                ReceiptPreviewView(image: receiptImage)
            }
        }
    }

    private func shareReceipt() {
        var items: [Any] = []
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let text = String(
            format: NSLocalizedString("Expense receipt for %@\nAmount: %@ %.2f\nDue: %@", comment: ""),
            entry.title,
            entry.currency.code,
            entry.amount,
            formatter.string(from: entry.dueDate)
        )
        items.append(text)
        if let image = receiptImage {
            items.append(image)
        }
        shareItems = items
        showingShareSheet = true
    }
}

private struct ReceiptPreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationTitle("Receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ServiceFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String = ""
    @State private var status: ServiceTask.Status = .scheduled
    @State private var selectedEmployeeID: UUID?
    @State private var selectedClientID: UUID?
    @State private var selectedServiceTypeID: UUID?
    @State private var notifyClient = true
    @State private var notifyTeam = true
    init(initialDate: Date) {
        _selectedDate = State(initialValue: initialDate)
        let calendar = Calendar.current
        let baseStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate) ?? initialDate
        let baseEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: initialDate) ?? initialDate.addingTimeInterval(60 * 60)
        _startTime = State(initialValue: baseStart)
        _endTime = State(initialValue: baseEnd)
    }

    init(initialDate: Date, client: Client) {
        _selectedDate = State(initialValue: initialDate)
        let calendar = Calendar.current
        let baseStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate) ?? initialDate
        let baseEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: initialDate) ?? initialDate.addingTimeInterval(60 * 60)
        _startTime = State(initialValue: baseStart)
        _endTime = State(initialValue: baseEnd)
        _selectedClientID = State(initialValue: client.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Title", text: $title)
                    Picker("Status", selection: $status) {
                        ForEach(ServiceTask.Status.allCases) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Date & time") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Assignments") {
                    if store.employees.isEmpty {
                        Text("Add at least one employee to create services.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Employee", selection: Binding(
                            get: { selectedEmployeeID ?? store.employees.first?.id },
                            set: { selectedEmployeeID = $0 }
                        )) {
                            ForEach(store.employees, id: \.id) { employee in
                                Text(employee.name).tag(employee.id as UUID?)
                            }
                        }
                    }

                    if store.clients.isEmpty {
                        Text("Add at least one client to create services.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Client", selection: Binding(
                            get: { selectedClientID ?? store.clients.first?.id },
                            set: { selectedClientID = $0 }
                        )) {
                            ForEach(store.clients, id: \.id) { client in
                                Text(client.name).tag(client.id as UUID?)
                            }
                        }
                    }
                }

                if !store.serviceTypes.isEmpty {
                    Section("Service type") {
                        Picker("Type", selection: Binding(
                            get: { selectedServiceTypeID ?? store.serviceTypes.first?.id },
                            set: { selectedServiceTypeID = $0 }
                        )) {
                            ForEach(store.serviceTypes, id: \.id) { type in
                                Text(type.name).tag(type.id as UUID?)
                            }
                        }
                    }
                }

                Section("Notes & notifications") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                    Toggle("Notify client", isOn: $notifyClient)
                    Toggle("Notify team", isOn: $notifyTeam)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") { save() }
                .padding()
                .disabled(!canSave)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("New Service")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            if selectedEmployeeID == nil { selectedEmployeeID = store.employees.first?.id }
            if selectedClientID == nil { selectedClientID = store.clients.first?.id }
            notifyClient = store.notificationPreferences.enableClientNotifications
            notifyTeam = store.notificationPreferences.enableTeamNotifications
        }
        .onChange(of: selectedDate) { newValue in
            startTime = combine(date: newValue, time: startTime)
            endTime = combine(date: newValue, time: endTime)
        }
    }

    private var canSave: Bool {
        !title.isEmpty && selectedEmployeeID != nil && selectedClientID != nil && endTime >= startTime
    }

    private func save() {
        guard
            let employeeID = selectedEmployeeID ?? store.employees.first?.id,
            let clientID = selectedClientID ?? store.clients.first?.id,
            let employee = store.employees.first(where: { $0.id == employeeID }),
            let client = store.clients.first(where: { $0.id == clientID })
        else { return }

        var finalNotes = notes
        let clientNote = NSLocalizedString("Notify client.", comment: "")
        let teamNote = NSLocalizedString("Notify team.", comment: "")
        if notifyClient { finalNotes.append(contentsOf: finalNotes.isEmpty ? clientNote : "\n\(clientNote)") }
        if notifyTeam { finalNotes.append(contentsOf: finalNotes.isEmpty ? teamNote : "\n\(teamNote)") }

        let serviceTypeIdToUse = selectedServiceTypeID ?? store.serviceTypes.first?.id

        store.addTask(
            title: title,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            employee: employee,
            clientId: client.id,
            clientName: client.name,
            address: client.address,
            notes: finalNotes,
            status: status,
            serviceTypeId: serviceTypeIdToUse
        )
        dismiss()
    }

    private func combine(date: Date, time: Date) -> Date {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        let combined = Calendar.current.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: components.second ?? 0,
            of: date
        ) ?? date
        return combined
    }
}

struct FinanceFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var type: FinanceEntry.EntryType = .receivable
    @State private var dueDate: Date = Date()
    @State private var method: FinanceEntry.PaymentMethod? = nil
    @State private var currency: FinanceEntry.Currency = .usd
    @State private var isOutOfPocket = false
    @State private var selectedClientName: String = ""
    @State private var receiptImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var showingShareSheet = false

    @State private var shareItems: [Any] = []

    private var clientNames: [String] {
        Array(Set(store.clients.map { $0.name })).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Entry") {
                        TextField("Title", text: $title)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(store.appPreferences.preferredCurrency.code)
                                .foregroundColor(.secondary)
                        }
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }

                    Section("Type") {
                        Picker("", selection: $type) {
                            Text("Receivable").tag(FinanceEntry.EntryType.receivable)
                            Text("Payable").tag(FinanceEntry.EntryType.payable)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Method (optional)") {
                        Picker("Method", selection: $method) {
                            Text("Do not set now").tag(nil as FinanceEntry.PaymentMethod?)
                            ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                                Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                            }
                        }
                    }

                    if type == .payable {
                        Section("Out-of-pocket expense") {
                            Toggle("I paid this out of pocket", isOn: $isOutOfPocket)
                            if isOutOfPocket {
                                Picker("Client", selection: $selectedClientName) {
                                    Text("Select client").tag("")
                                    ForEach(clientNames, id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                Button {
                                    showingImagePicker = true
                                } label: {
                                    Label(
                                        receiptImage == nil ? "Capture receipt photo" : "Retake receipt photo",
                                        systemImage: "camera.fill"
                                    )
                                }
                            }
                        }
                    }
                }

                PrimaryButton(title: "Save") {
                    save()
                }
                .padding()
                .disabled(!canSave)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView(image: $receiptImage)
            }
            .sheet(isPresented: $showingShareSheet) {
                ActivityView(items: shareItems)
            }
            .onAppear {
                currency = store.appPreferences.preferredCurrency
            }
        }
    }

    private var parsedAmount: Double? {
        let normalized = amount.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var canSave: Bool {
        guard let value = parsedAmount else { return false }
        return !title.isEmpty && value > 0
    }

    private func save() {
        guard let value = parsedAmount else { return }
        let clientName = isOutOfPocket ? (selectedClientName.isEmpty ? nil : selectedClientName) : nil
        let clientId = clientName.flatMap { name in
            store.clients.first(where: { $0.name == name })?.id
        }
        let kind: FinanceEntry.Kind = (type == .payable && isOutOfPocket) ? .expenseOutOfPocket : .general
        let receiptData = receiptImage?.jpegData(compressionQuality: 0.7)

        store.addFinanceEntry(
            title: title,
            amount: value,
            type: type,
            dueDate: dueDate,
            method: method,
            currency: store.appPreferences.preferredCurrency,
            clientId: clientId,
            clientName: clientName,
            employeeName: nil,
            kind: kind,
            receiptData: receiptData
        )

        if let image = receiptImage, let clientName {
            var items: [Any] = []
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: dueDate)
            let activeCurrency = store.appPreferences.preferredCurrency
            let text = String(
                format: NSLocalizedString("Expense receipt for %@\n\n%@\nAmount: %@ %.2f\nDue date: %@", comment: ""),
                clientName,
                title,
                activeCurrency.code,
                value,
                dateString
            )
            items.append(text)
            items.append(image)
            shareItems = items
            showingShareSheet = true
        } else {
            dismiss()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    let onMenu: (() -> Void)?

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    var body: some View {
        NavigationStack {
            List {
                if let session = store.session {
                    Section("Session") {
                        Text(String(format: NSLocalizedString("User: %@", comment: ""), session.name))
                        Button("Sign out", role: .destructive) { store.logout() }
                    }
                }
                Section("Sync") {
                    Button("Force sync") { store.syncPendingChanges() }
                    if let lastSync = store.lastSync {
                        Text(String(format: NSLocalizedString("Last: %@", comment: ""), lastSync.formatted(date: .abbreviated, time: .shortened)))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if !store.pendingChanges.isEmpty {
                        Text(String(format: NSLocalizedString("%d pending changes in the queue", comment: ""), store.pendingChanges.count))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                Section("Conflicts") {
                    if store.conflictLog.isEmpty {
                        Text("No conflicts recorded.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(store.conflictLog.sorted { $0.timestamp > $1.timestamp }) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.summary)
                                    .font(.subheadline)
                                Text(String(format: NSLocalizedString("%@ · %@", comment: ""), entry.entity, entry.field))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Text(entry.timestamp, style: .date)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if store.session?.role == .manager {
                    Section("Audit log") {
                        NavigationLink("Audit log") {
                            AuditLogView()
                        }
                        if store.auditLog.isEmpty {
                            Text("No audit entries yet.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if store.session?.role == .manager {
                    Section("Team") {
                        NavigationLink("Employees") {
                            EmployeesView()
                        }
                    }
                }

                if store.session?.role == .manager {
                    Section("App preferences") {
                        Picker("Language", selection: $store.appPreferences.language) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.label).tag(language)
                            }
                        }
                        Picker("Currency", selection: $store.appPreferences.preferredCurrency) {
                            ForEach(FinanceEntry.Currency.allCases) { currency in
                                Text(currency.code).tag(currency)
                            }
                        }
                        Stepper(value: $store.appPreferences.disputeWindowDays, in: 0...30) {
                            let days = store.appPreferences.disputeWindowDays
                            let labelKey = days == 1
                                ? "Dispute window: %d day after due date"
                                : "Dispute window: %d days after due date"
                            Text(String(format: NSLocalizedString(labelKey, comment: ""), days))
                        }
                        Text("0 days means disputes are only allowed until the due date.")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        NavigationLink("Company profile (invoices)") {
                            CompanyProfileSettingsView()
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Notifications for clients", isOn: $store.notificationPreferences.enableClientNotifications)
                    Toggle("Notifications for team", isOn: $store.notificationPreferences.enableTeamNotifications)
                    Toggle("Push notifications", isOn: $store.notificationPreferences.enablePush)
                        .onChange(of: store.notificationPreferences.enablePush) { enabled in
                            if enabled {
                                store.requestPushAuthorizationIfNeeded()
                            }
                    }
                    Toggle("Siri suggestions", isOn: $store.notificationPreferences.enableSiri)
                }

                if store.session?.role == .manager {
                    Section("Delivery channels") {
                        Toggle("WhatsApp", isOn: $store.appPreferences.enableWhatsApp)
                        Toggle("Text Message", isOn: $store.appPreferences.enableTextMessages)
                        Toggle("Email", isOn: $store.appPreferences.enableEmail)
                        if !store.appPreferences.enableWhatsApp &&
                            !store.appPreferences.enableTextMessages &&
                            !store.appPreferences.enableEmail {
                            Text("Enable at least one channel to send invoices.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
            }
        }
    }
}

struct CompanyProfileSettingsView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var legalName = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var region = ""
    @State private var postalCode = ""
    @State private var countryName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var website = ""
    @State private var taxCountry: CompanyProfile.TaxCountry = .unitedStates
    @State private var taxIdentifier = ""
    @State private var logoImage: UIImage?
    @State private var showingLogoPicker = false

    private var canSave: Bool {
        !legalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Logo") {
                    if let logoImage {
                        Image(uiImage: logoImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 140)
                            .cornerRadius(AppTheme.cornerRadius)
                    } else {
                        Text("No logo selected")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Button(logoImage == nil ? "Add logo" : "Change logo") {
                        showingLogoPicker = true
                    }
                    if logoImage != nil {
                        Button("Remove logo", role: .destructive) {
                            logoImage = nil
                        }
                    }
                }

                Section("Company") {
                    TextField("Legal name", text: $legalName)
                    TextField("Address line 1", text: $addressLine1)
                    TextField("Address line 2", text: $addressLine2)
                    TextField("City", text: $city)
                    TextField("State/Region", text: $region)
                    TextField("Postal code", text: $postalCode)
                    TextField("Country", text: $countryName)
                }

                Section("Contact") {
                    TextField("Email", text: $contactEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Tax") {
                    Picker("Tax country", selection: $taxCountry) {
                        ForEach(CompanyProfile.TaxCountry.allCases) { country in
                            Text(country.label).tag(country)
                        }
                    }
                    TextField(taxCountry.taxIdLabel, text: $taxIdentifier)
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") {
                save()
            }
            .padding()
            .disabled(!canSave)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Company profile")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingLogoPicker) {
            ImagePickerView(
                image: $logoImage,
                sourceType: .photoLibrary,
                allowPhotoLibraryFallback: true
            )
        }
        .onAppear {
            loadFromPreferences()
        }
    }

    private func loadFromPreferences() {
        let profile = store.appPreferences.companyProfile ?? CompanyProfile()
        legalName = profile.legalName
        addressLine1 = profile.addressLine1
        addressLine2 = profile.addressLine2
        city = profile.city
        region = profile.region
        postalCode = profile.postalCode
        countryName = profile.countryName
        contactEmail = profile.contactEmail
        contactPhone = profile.contactPhone
        website = profile.website
        taxCountry = profile.taxCountry
        taxIdentifier = profile.taxIdentifier
        logoImage = profile.logoData.flatMap { UIImage(data: $0) }
    }

    private func save() {
        let profile = CompanyProfile(
            legalName: legalName.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine1: addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine2: addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            region: region.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
            countryName: countryName.trimmingCharacters(in: .whitespacesAndNewlines),
            contactEmail: contactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            contactPhone: contactPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            website: website.trimmingCharacters(in: .whitespacesAndNewlines),
            taxCountry: taxCountry,
            taxIdentifier: taxIdentifier.trimmingCharacters(in: .whitespacesAndNewlines),
            logoData: logoImage?.jpegData(compressionQuality: 0.8)
        )
        store.appPreferences.companyProfile = profile
        dismiss()
    }
}

struct AuditLogView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingClearAlert = false

    private var sortedEntries: [AuditLogEntry] {
        store.auditLog.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            if sortedEntries.isEmpty {
                Text("No audit entries yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sortedEntries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.summary)
                            .font(.subheadline)
                        Text(String(format: NSLocalizedString("Actor: %@", comment: ""), entry.actor))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(String(format: NSLocalizedString("Action: %@", comment: ""), entry.action))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(entry.timestamp, style: .date)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Audit log")
        .toolbar {
            if !store.auditLog.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        showingClearAlert = true
                    }
                }
            }
        }
        .alert("Clear audit log?", isPresented: $showingClearAlert) {
            Button("Clear", role: .destructive) { store.clearAuditLog() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct InvoiceGeneratorView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: comps) ?? now
    }()
    @State private var endDate: Date = Date()
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedClientName: String = ""

    private var clientNames: [String] {
        Array(Set(store.clients.map { $0.name })).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Period") {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                Section("Due date") {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }
                Section("Client") {
                    Picker("Client", selection: $selectedClientName) {
                        Text("All clients").tag("")
                        ForEach(clientNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }
            .navigationTitle("Generate invoices")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        let clientName = selectedClientName.isEmpty ? nil : selectedClientName
                        store.generateInvoices(from: startDate, to: endDate, dueDate: dueDate, clientName: clientName)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PayrollGeneratorView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: comps) ?? now
    }()
    @State private var endDate: Date = Date()
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var selectedEmployeeName: String = ""

    private var employeeNames: [String] {
        Array(Set(store.employees.map { $0.name })).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Period") {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                Section("Due date") {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }
                Section("Employee") {
                    Picker("Employee", selection: $selectedEmployeeName) {
                        Text("All employees").tag("")
                        ForEach(employeeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }
            .navigationTitle("Generate payroll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        let employeeName = selectedEmployeeName.isEmpty ? nil : selectedEmployeeName
                        store.generatePayrolls(from: startDate, to: endDate, dueDate: dueDate, employeeName: employeeName)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ClientDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    let client: Client
    @State private var showingServiceForm = false
    @State private var showingEditForm = false
    @State private var showingDeleteConfirm = false
    @State private var showingDeleteBlocked = false
    @State private var deleteBlockedMessage = ""

    private var clientTasks: [ServiceTask] {
        store.tasks
            .filter { $0.clientName == currentClient.name || $0.clientId == currentClient.id }
            .sorted {
                let lhsDate = $0.startTime ?? $0.date
                let rhsDate = $1.startTime ?? $1.date
                return lhsDate > rhsDate
            }
    }

    private var currentClient: Client {
        store.clients.first(where: { $0.id == client.id }) ?? client
    }

    private var isManager: Bool {
        store.session?.role == .manager
    }

    var body: some View {
        List {
            Section("Client") {
                Text(currentClient.name).bold()
                if !currentClient.phone.isEmpty {
                    Text(String(format: NSLocalizedString("Phone: %@", comment: ""), currentClient.phone))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !currentClient.whatsappPhone.isEmpty {
                    Text(String(format: NSLocalizedString("WhatsApp phone: %@", comment: ""), currentClient.whatsappPhone))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !currentClient.email.isEmpty {
                    Text(String(format: NSLocalizedString("Email: %@", comment: ""), currentClient.email))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text(currentClient.address)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if !currentClient.propertyDetails.isEmpty {
                    Text(String(format: NSLocalizedString("Property: %@", comment: ""), currentClient.propertyDetails))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !currentClient.preferredSchedule.isEmpty {
                    Text(String(format: NSLocalizedString("Preferred schedule: %@", comment: ""), currentClient.preferredSchedule))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !currentClient.accessNotes.isEmpty {
                    Text(String(format: NSLocalizedString("Access notes: %@", comment: ""), currentClient.accessNotes))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section("Delivery channels") {
                let channels = currentClient.preferredDeliveryChannels.isEmpty
                    ? [Client.DeliveryChannel.email]
                    : currentClient.preferredDeliveryChannels
                Text(channels.map { $0.label }.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Service history") {
                if clientTasks.isEmpty {
                    Text("No services registered yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(clientTasks) { task in
                        NavigationLink(destination: ServiceDetailView(task: task)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).bold()
                                HStack(spacing: 8) {
                                    Text(task.date, style: .date)
                                    if let start = task.startTime {
                                        Text(start, style: .time)
                                    }
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                StatusBadge(status: task.status)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    showingServiceForm = true
                } label: {
                    Label("Create service", systemImage: "plus.circle.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(currentClient.name)
        .toolbar {
            if isManager {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showingEditForm = true }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete", role: .destructive) { showingDeleteConfirm = true }
                }
            }
        }
        .sheet(isPresented: $showingServiceForm) {
            ServiceFormView(initialDate: Date(), client: currentClient)
        }
        .sheet(isPresented: $showingEditForm) {
            ClientForm(client: currentClient)
        }
        .confirmationDialog("Delete client?", isPresented: $showingDeleteConfirm) {
            Button("Delete client", role: .destructive) {
                if !store.deleteClient(currentClient) {
                    deleteBlockedMessage = NSLocalizedString(
                        "This client has linked services or finance entries. Resolve them before deleting.",
                        comment: ""
                    )
                    showingDeleteBlocked = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Cannot delete", isPresented: $showingDeleteBlocked) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteBlockedMessage)
        }
    }
}

// MARK: - Services catalog

struct ServicesView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.serviceTypes) { service in
                    NavigationLink(destination: ServiceTypeDetailView(serviceType: service)) {
                        ServiceRow(serviceType: service)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                NavigationStack {
                    ServiceTypeForm()
                }
                .environmentObject(store)
            }
        }
    }
}

private struct ServiceRow: View {
    let serviceType: ServiceType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(serviceType.name)
                    .font(.headline)
                Spacer()
                Text("\(serviceType.currency.code) \(serviceType.basePrice, specifier: "%.2f")")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.primary)
            }
            Text(serviceType.pricingModel.label)
                .font(.caption)
                .foregroundColor(.secondary)
            if !serviceType.description.isEmpty {
                Text(serviceType.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct ServiceTypeDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    let serviceType: ServiceType
    @State private var showingEdit = false
    @State private var showDeleteAlert = false
    @State private var showDeleteBlocked = false

    private var linkedTasksCount: Int {
        store.tasks.filter { $0.serviceTypeId == serviceType.id }.count
    }

    private var canDelete: Bool { linkedTasksCount == 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(serviceType.name)
                            .font(.title3.bold())
                        if !serviceType.description.isEmpty {
                            Text(serviceType.description)
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        Text(String(format: NSLocalizedString("Base price: %@ %.2f", comment: ""), serviceType.currency.code, serviceType.basePrice))
                            .font(.body)
                        Text(String(format: NSLocalizedString("Pricing model: %@", comment: ""), serviceType.pricingModel.label))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                if linkedTasksCount > 0 {
                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Usage")
                                .font(.headline)
                            Text(String(format: NSLocalizedString("Linked to %d services. Reassign before deleting.", comment: ""), linkedTasksCount))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                AppCard {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit service", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)

                if canDelete {
                    AppCard {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete service", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Service")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ServiceTypeForm(serviceType: serviceType)
            }
            .environmentObject(store)
        }
        .alert("Delete service?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if store.deleteServiceType(serviceType) {
                    dismiss()
                } else {
                    showDeleteBlocked = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Cannot delete service", isPresented: $showDeleteBlocked) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This service type is linked to existing tasks. Reassign or remove those tasks before deleting.")
        }
    }
}

struct ServiceTypeForm: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    private let serviceType: ServiceType?

    @State private var name: String
    @State private var description: String
    @State private var basePriceText: String
    @State private var pricingModel: ServiceType.PricingModel

    private var basePrice: Double? {
        Double(basePriceText.replacingOccurrences(of: ",", with: "."))
    }

    private var isEditing: Bool { serviceType != nil }

    init(serviceType: ServiceType? = nil) {
        self.serviceType = serviceType
        _name = State(initialValue: serviceType?.name ?? "")
        _description = State(initialValue: serviceType?.description ?? "")
        if let price = serviceType?.basePrice {
            _basePriceText = State(initialValue: String(format: "%.2f", price))
        } else {
            _basePriceText = State(initialValue: "")
        }
        _pricingModel = State(initialValue: serviceType?.pricingModel ?? .perTask)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Service") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Base price", text: $basePriceText)
                        .keyboardType(.decimalPad)
                    Picker("Pricing model", selection: $pricingModel) {
                        ForEach(ServiceType.PricingModel.allCases) { model in
                            Text(model.label).tag(model)
                        }
                    }
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(store.appPreferences.preferredCurrency.code)
                            .foregroundColor(.secondary)
                    }
                }
            }

            PrimaryButton(title: isEditing ? "Update" : "Save") {
                guard let price = basePrice, !name.isEmpty else { return }
                if let serviceType {
                    store.updateServiceType(
                        serviceType,
                        name: name,
                        description: description,
                        basePrice: price,
                        currency: store.appPreferences.preferredCurrency,
                        pricingModel: pricingModel
                    )
                } else {
                    store.addServiceType(
                        name: name,
                        description: description,
                        basePrice: price,
                        currency: store.appPreferences.preferredCurrency,
                        pricingModel: pricingModel
                    )
                }
                dismiss()
            }
            .padding()
            .disabled(name.isEmpty || basePrice == nil)
        }
        .navigationTitle(isEditing ? "Edit Service" : "New Service")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

// MARK: - Teams

struct TeamsView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingForm = false
    @State private var selectedTeamForRemoval: String?

    private var teams: [(name: String, members: [Employee])] {
        let grouped = Dictionary(grouping: store.employees.filter { !$0.team.isEmpty }) { $0.team }
        return grouped.map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.name < $1.name }
    }

    private var unassigned: [Employee] {
        store.employees.filter { $0.team.isEmpty }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if teams.isEmpty && unassigned.isEmpty {
                Text("No employees yet.")
                    .foregroundColor(.secondary)
            }
            ForEach(teams, id: \.name) { team in
                Section(header: Text(String(format: NSLocalizedString("%@ (%d)", comment: ""), team.name, team.members.count))) {
                    ForEach(team.members) { employee in
                        teamRow(employee: employee)
                    }
                    Button(role: .destructive) {
                        selectedTeamForRemoval = team.name
                        removeTeam(team.name)
                    } label: {
                        Label("Remove team", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            if !unassigned.isEmpty {
                Section(header: Text("Unassigned")) {
                    ForEach(unassigned) { employee in
                        teamRow(employee: employee)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Teams")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Label("New Team", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            NavigationStack {
                TeamForm()
            }
            .environmentObject(store)
        }
    }

    private func teamRow(employee: Employee) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(employee.name).bold()
                if !employee.team.isEmpty {
                    Text(String(format: NSLocalizedString("Team: %@", comment: ""), employee.team))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unassigned")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Menu {
                Button("Remove from team") {
                    updateTeam(for: employee, to: "")
                }
                ForEach(teams.map { $0.name }, id: \.self) { teamName in
                    Button(String(format: NSLocalizedString("Move to %@", comment: ""), teamName)) {
                        updateTeam(for: employee, to: teamName)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
    }

    private func updateTeam(for employee: Employee, to team: String) {
        store.updateEmployee(
            employee,
            name: employee.name,
            roleTitle: employee.role,
            team: team,
            phone: employee.phone,
            hourlyRate: employee.hourlyRate,
            currency: employee.currency,
            extraEarningsDescription: employee.extraEarningsDescription,
            documentsDescription: employee.documentsDescription
        )
    }

    private func removeTeam(_ team: String) {
        let members = store.employees.filter { $0.team == team }
        members.forEach { member in
            updateTeam(for: member, to: "")
        }
    }
}

struct TeamForm: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedEmployeeIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Team") {
                    TextField("Name", text: $name)
                }
                Section("Assign employees") {
                    ForEach(store.employees) { employee in
                        HStack {
                            Text(employee.name)
                            Spacer()
                            if selectedEmployeeIDs.contains(employee.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedEmployeeIDs.contains(employee.id) {
                                selectedEmployeeIDs.remove(employee.id)
                            } else {
                                selectedEmployeeIDs.insert(employee.id)
                            }
                        }
                    }
                }
            }
            PrimaryButton(title: "Save") {
                let employeesToUpdate = store.employees.filter { selectedEmployeeIDs.contains($0.id) }
                employeesToUpdate.forEach { employee in
                    store.updateEmployee(
                        employee,
                        name: employee.name,
                        roleTitle: employee.role,
                        team: name,
                        phone: employee.phone,
                        hourlyRate: employee.hourlyRate,
                        currency: employee.currency,
                        extraEarningsDescription: employee.extraEarningsDescription,
                        documentsDescription: employee.documentsDescription
                    )
                }
                dismiss()
            }
            .padding()
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .navigationTitle("New Team")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct StatusBadge: View {
    let status: ServiceTask.Status

    var body: some View {
        Text(status.label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .accessibilityLabel(status.label)
    }

    private var backgroundColor: Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .canceled: return .red
        }
    }
}

struct PaymentStatusIcon: View {
    let hasPending: Bool

    var body: some View {
        Image(systemName: hasPending ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .font(.title3)
            .foregroundColor(hasPending ? .orange : .green)
            .accessibilityLabel(Text(hasPending ? "Pending payments" : "No pending payments"))
    }
}

struct FinanceRow: View {
    let entry: FinanceEntry
    var onStatusChange: (_ status: FinanceEntry.Status, _ method: FinanceEntry.PaymentMethod?) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.title).bold()
                HStack(spacing: 4) {
                    if let name = entry.clientName ?? entry.employeeName {
                        Text(name)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text(entry.dueDate, style: .date)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    StatusPill(label: entry.status.label, color: entry.status == .paid ? .green : .orange)
                    if let method = entry.method {
                        StatusPill(label: method.label, color: .blue.opacity(0.8))
                    }
                    if entry.kind == .invoiceClient && entry.isDisputed {
                        StatusPill(label: NSLocalizedString("Disputed", comment: ""), color: .red)
                    }
                    if entry.kind == .expenseOutOfPocket, entry.receiptData != nil {
                        StatusPill(label: NSLocalizedString("Receipt", comment: ""), color: .blue.opacity(0.7))
                    }
                }
            }
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: entry.amount)) ?? "-")
                .bold()
                .foregroundColor(entry.type == .receivable ? .green : .red)
            Menu {
                Button("Mark paid (Pix)") {
                    onStatusChange(.paid, .pix)
                }
                Button("Mark paid (Card)") {
                    onStatusChange(.paid, .card)
                }
                Button("Mark paid (Cash)") {
                    onStatusChange(.paid, .cash)
                }
                if entry.status == .paid {
                    Button("Mark as pending") {
                        onStatusChange(.pending, entry.method)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
        }
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currency.code
        return formatter
    }
}

struct ServiceDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var status: ServiceTask.Status
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var showClientAlert = false
    @State private var showTeamAlert = false
    @State private var checkInTime: Date?
    @State private var checkOutTime: Date?
    @State private var checkInPhoto: UIImage?
    @State private var checkOutPhoto: UIImage?
    @State private var showingCheckInCamera = false
    @State private var showingCheckOutCamera = false
    @State private var showCameraUnavailableAlert = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var selectedEmployeeID: UUID?
    @State private var selectedClientID: UUID?
    @State private var selectedServiceTypeID: UUID?
    let task: ServiceTask

    init(task: ServiceTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _status = State(initialValue: task.status)
        _startTime = State(initialValue: task.startTime ?? task.date)
        _endTime = State(initialValue: task.endTime ?? task.date.addingTimeInterval(60 * 60))
        _notes = State(initialValue: task.notes)
        _checkInTime = State(initialValue: task.checkInTime)
        _checkOutTime = State(initialValue: task.checkOutTime)
        _checkInPhoto = State(initialValue: task.checkInPhotoData.flatMap { UIImage(data: $0) })
        _checkOutPhoto = State(initialValue: task.checkOutPhotoData.flatMap { UIImage(data: $0) })
        _selectedEmployeeID = State(initialValue: task.assignedEmployee.id)
        _selectedClientID = State(initialValue: task.clientId)
        _selectedServiceTypeID = State(initialValue: task.serviceTypeId)
    }

    private var isManager: Bool {
        store.session?.role == .manager
    }

    private var selectedEmployee: Employee? {
        if let selectedEmployeeID {
            return store.employees.first { $0.id == selectedEmployeeID }
        }
        return store.employees.first { $0.name == task.assignedEmployee.name }
    }

    private var selectedClient: Client? {
        if let selectedClientID {
            return store.clients.first { $0.id == selectedClientID }
        }
        return store.clients.first { $0.name == task.clientName }
    }

    private var selectedServiceType: ServiceType? {
        if let selectedServiceTypeID {
            return store.serviceTypes.first { $0.id == selectedServiceTypeID }
        }
        if let serviceTypeId = task.serviceTypeId {
            return store.serviceTypes.first { $0.id == serviceTypeId }
        }
        return nil
    }

    private var hasCheckInPhoto: Bool {
        checkInPhoto != nil
    }

    private var hasCheckOutPhoto: Bool {
        checkOutPhoto != nil
    }

    private var canTriggerCheckOut: Bool {
        checkInTime != nil && hasCheckInPhoto
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Service") {
                    TextField("Title", text: $title)
                        .disabled(!isManager)
                    Picker("Status", selection: $status) {
                        ForEach(ServiceTask.Status.allCases) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Start", selection: $startTime, displayedComponents: [.hourAndMinute, .date])
                    DatePicker("End", selection: $endTime, displayedComponents: [.hourAndMinute, .date])
                }

                Section("Assignments") {
                    if store.employees.isEmpty {
                        Text("Add at least one employee to create services.")
                            .foregroundColor(.secondary)
                    } else if isManager {
                        Picker("Employee", selection: Binding(
                            get: { selectedEmployeeID ?? store.employees.first?.id },
                            set: { selectedEmployeeID = $0 }
                        )) {
                            ForEach(store.employees, id: \.id) { employee in
                                Text(employee.name).tag(employee.id as UUID?)
                            }
                        }
                    } else {
                        Text(selectedEmployee?.name ?? task.assignedEmployee.name)
                            .font(.subheadline)
                    }

                    if store.clients.isEmpty {
                        Text("Add at least one client to create services.")
                            .foregroundColor(.secondary)
                    } else if isManager {
                        Picker("Client", selection: Binding(
                            get: { selectedClientID ?? store.clients.first?.id },
                            set: { selectedClientID = $0 }
                        )) {
                            ForEach(store.clients, id: \.id) { client in
                                Text(client.name).tag(client.id as UUID?)
                            }
                        }
                    } else {
                        Text(selectedClient?.name ?? task.clientName)
                            .bold()
                    }

                    if let address = selectedClient?.address, !address.isEmpty {
                        Text(address)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else if !task.address.isEmpty {
                        Text(task.address)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                if !store.serviceTypes.isEmpty {
                    Section("Service type") {
                        if isManager {
                            Picker("Type", selection: Binding(
                                get: { selectedServiceTypeID ?? store.serviceTypes.first?.id },
                                set: { selectedServiceTypeID = $0 }
                            )) {
                                ForEach(store.serviceTypes, id: \.id) { type in
                                    Text(type.name).tag(type.id as UUID?)
                                }
                            }
                        } else if let selectedServiceType {
                            Text(selectedServiceType.name)
                                .font(.subheadline)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                Section("Check-in / Check-out") {
                    if let checkInTime {
                        Text(String(format: NSLocalizedString("Checked in: %@", comment: ""), checkInTime.formatted(date: .omitted, time: .shortened)))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let checkOutTime {
                        Text(String(format: NSLocalizedString("Checked out: %@", comment: ""), checkOutTime.formatted(date: .omitted, time: .shortened)))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    if let checkInPhoto {
                        Image(uiImage: checkInPhoto)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(alignment: .bottomLeading) {
                                Text("Check-in photo")
                                    .font(.caption2.bold())
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                    }

                    if let checkOutPhoto {
                        Image(uiImage: checkOutPhoto)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(alignment: .bottomLeading) {
                                Text("Check-out photo")
                                    .font(.caption2.bold())
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                    }

                    if checkInTime == nil {
                        Button("Check-in now (camera)") {
                            openCheckInCamera()
                        }
                    } else {
                        if !hasCheckInPhoto {
                            Text("Capture check-in photo to continue.")
                                .font(.footnote)
                                .foregroundColor(.orange)
                            Button("Capture check-in photo (camera)") {
                                openCheckInCamera()
                            }
                        }

                        if checkOutTime == nil {
                            if canTriggerCheckOut {
                                Button("Check-out now (camera)") {
                                    openCheckOutCamera()
                                }
                            } else {
                                Text("Check-out is unlocked only after check-in with photo.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        } else if !hasCheckOutPhoto {
                            Text("Capture check-out photo to complete evidence.")
                                .font(.footnote)
                                .foregroundColor(.orange)
                            Button("Capture check-out photo (camera)") {
                                openCheckOutCamera()
                            }
                        }
                    }
                }

                Section("Quick actions") {
                    Button("Mark as completed") { status = .completed }
                    Button("Cancel service", role: .destructive) { status = .canceled }
                    Button("Notify client") {
                        guard store.notificationPreferences.enableClientNotifications else { return }
                        showClientAlert = true
                        if store.notificationPreferences.enablePush {
                            store.sendLocalNotification(
                                title: NSLocalizedString("Notification to client", comment: ""),
                                body: String(
                                    format: NSLocalizedString("Service \"%@\" updated for %@.", comment: ""),
                                    task.title,
                                    task.clientName
                                )
                            )
                        }
                    }
                    Button("Notify team") {
                        guard store.notificationPreferences.enableTeamNotifications else { return }
                        showTeamAlert = true
                        if store.notificationPreferences.enablePush {
                            store.sendLocalNotification(
                                title: NSLocalizedString("Notification to team", comment: ""),
                                body: String(
                                    format: NSLocalizedString("Service \"%@\" updated for %@.", comment: ""),
                                    task.title,
                                    task.assignedEmployee.name
                                )
                            )
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") {
                guard validateBeforeSave() else {
                    showValidationAlert = true
                    return
                }
                let employee = selectedEmployee
                let client = selectedClient
                let checkInPhotoData = checkInPhoto?.jpegData(compressionQuality: 0.7) ?? task.checkInPhotoData
                let checkOutPhotoData = checkOutPhoto?.jpegData(compressionQuality: 0.7) ?? task.checkOutPhotoData
                store.updateTask(
                    task,
                    title: isManager ? title : nil,
                    status: status,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    checkInTime: checkInTime,
                    checkOutTime: checkOutTime,
                    checkInPhotoData: checkInPhotoData,
                    checkOutPhotoData: checkOutPhotoData,
                    employee: isManager ? employee : nil,
                    client: isManager ? client : nil,
                    serviceTypeId: isManager ? selectedServiceTypeID : nil
                )
                dismiss()
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .alert("Notification sent to client", isPresented: $showClientAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Notification sent to team", isPresented: $showTeamAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A device camera is required for check-in/check-out photos.")
        }
        .alert("Cannot save service", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .sheet(isPresented: $showingCheckInCamera) {
            ImagePickerView(
                image: $checkInPhoto,
                sourceType: .camera,
                allowPhotoLibraryFallback: false,
                onImagePicked: handleCheckInPhotoCaptured
            )
        }
        .sheet(isPresented: $showingCheckOutCamera) {
            ImagePickerView(
                image: $checkOutPhoto,
                sourceType: .camera,
                allowPhotoLibraryFallback: false,
                onImagePicked: handleCheckOutPhotoCaptured
            )
        }
        .onAppear {
            if selectedEmployeeID == nil {
                selectedEmployeeID = store.employees.first(where: { $0.id == task.assignedEmployee.id })?.id
                    ?? store.employees.first?.id
            }
            if selectedClientID == nil {
                selectedClientID = store.clients.first(where: { $0.id == task.clientId })?.id
                    ?? store.clients.first(where: { $0.name == task.clientName })?.id
                    ?? store.clients.first?.id
            }
            if selectedServiceTypeID == nil {
                selectedServiceTypeID = task.serviceTypeId ?? store.serviceTypes.first?.id
            }
        }
    }

    private func openCheckInCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        showingCheckInCamera = true
    }

    private func openCheckOutCamera() {
        guard checkInTime != nil else {
            validationMessage = NSLocalizedString("Check-in must be completed before check-out.", comment: "")
            showValidationAlert = true
            return
        }
        guard hasCheckInPhoto else {
            validationMessage = NSLocalizedString("Capture check-in photo before check-out.", comment: "")
            showValidationAlert = true
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        showingCheckOutCamera = true
    }

    private func handleCheckInPhotoCaptured() {
        checkInTime = Date()
        status = .inProgress
        if let checkOutTime, let checkInTime, checkOutTime < checkInTime {
            self.checkOutTime = nil
            checkOutPhoto = nil
        }
    }

    private func handleCheckOutPhotoCaptured() {
        guard checkInTime != nil else { return }
        checkOutTime = Date()
    }

    private func validateBeforeSave() -> Bool {
        if let checkOutTime, checkInTime == nil {
            validationMessage = NSLocalizedString("Check-out cannot be saved without check-in.", comment: "")
            return false
        }
        if checkInTime != nil && !hasCheckInPhoto {
            validationMessage = NSLocalizedString("Check-in photo is mandatory.", comment: "")
            return false
        }
        if checkOutTime != nil && !hasCheckOutPhoto {
            validationMessage = NSLocalizedString("Check-out photo is mandatory.", comment: "")
            return false
        }
        if let checkInTime, let checkOutTime, checkOutTime < checkInTime {
            validationMessage = NSLocalizedString("Check-out time cannot be earlier than check-in time.", comment: "")
            return false
        }
        return true
    }
}

private struct StatusPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct PrimaryBottomCTA: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: action) {
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(AppTheme.background)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            AppTheme.primary,
                            AppTheme.primary.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.primary.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
}

struct ClientForm: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss
    private let client: Client?
    private let onSave: (() -> Void)?
    @State private var name = ""
    @State private var address = ""
    @State private var propertyDetails = ""
    @State private var phoneLocal = ""
    @State private var phoneCode: CountryCode = .defaultCode
    @State private var whatsappPhoneLocal = ""
    @State private var whatsappPhoneCode: CountryCode = .defaultCode
    @State private var email = ""
    @State private var preferredSchedule = ""
    @State private var accessNotes = ""
    @State private var enableEmail = true
    @State private var enableWhatsApp = false
    @State private var enableText = false
    @State private var showContactPicker = false

    init(client: Client? = nil, onSave: (() -> Void)? = nil) {
        self.client = client
        self.onSave = onSave
        _name = State(initialValue: client?.name ?? "")
        _address = State(initialValue: client?.address ?? "")
        _propertyDetails = State(initialValue: client?.propertyDetails ?? "")
        _email = State(initialValue: client?.email ?? "")
        _preferredSchedule = State(initialValue: client?.preferredSchedule ?? "")
        _accessNotes = State(initialValue: client?.accessNotes ?? "")
        if let phone = client?.phone, !phone.isEmpty {
            let split = ClientForm.splitPhone(phone)
            _phoneCode = State(initialValue: split.code)
            _phoneLocal = State(initialValue: split.number)
        }
        if let whatsapp = client?.whatsappPhone, !whatsapp.isEmpty {
            let split = ClientForm.splitPhone(whatsapp)
            _whatsappPhoneCode = State(initialValue: split.code)
            _whatsappPhoneLocal = State(initialValue: split.number)
        }
        let channels = client?.preferredDeliveryChannels ?? []
        _enableEmail = State(initialValue: channels.isEmpty ? true : channels.contains(.email))
        _enableWhatsApp = State(initialValue: channels.contains(.whatsapp))
        _enableText = State(initialValue: channels.contains(.sms))
    }

    private var isEditing: Bool {
        client != nil
    }

    private var selectedChannels: [Client.DeliveryChannel] {
        var channels: [Client.DeliveryChannel] = []
        if enableEmail { channels.append(.email) }
        if enableWhatsApp { channels.append(.whatsapp) }
        if enableText { channels.append(.sms) }
        return channels.isEmpty ? [.email] : channels
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Identification") {
                        TextField("Name", text: $name)
                    }
                    Section("Contact") {
                        HStack {
                            CountryCodePicker(selection: $phoneCode)
                            TextField("Phone", text: $phoneLocal)
                                .keyboardType(.phonePad)
                        }
                        HStack {
                            CountryCodePicker(selection: $whatsappPhoneCode)
                            TextField("WhatsApp phone", text: $whatsappPhoneLocal)
                                .keyboardType(.phonePad)
                        }
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        if !name.isEmpty {
                            let previewPhone = phoneLocal.isEmpty ? whatsappPhoneLocal : phoneLocal
                            let previewNumber = previewPhone.isEmpty ? nil : "\(phoneCode.dialCode) \(previewPhone)"
                            ContactAvatarView(name: name, phone: previewNumber, size: 56)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button {
                            showContactPicker = true
                        } label: {
                            Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                    Section("Property & schedule") {
                        TextField("Address", text: $address)
                        TextField("Property (type, block, size)", text: $propertyDetails)
                        TextField("Preferred schedule", text: $preferredSchedule)
                    }
                    Section("Access") {
                        TextField("Access instructions / front desk", text: $accessNotes)
                    }
                    Section("Delivery channels") {
                        Toggle("Email", isOn: $enableEmail)
                        Toggle("WhatsApp", isOn: $enableWhatsApp)
                        Toggle("Text Message", isOn: $enableText)
                        Text("Used when sending invoices or receipts.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)

                PrimaryButton(title: "Save") {
                    let fullPhone = phoneLocal.isEmpty ? "" : "\(phoneCode.dialCode) \(phoneLocal)"
                    let fullWhatsApp = whatsappPhoneLocal.isEmpty ? "" : "\(whatsappPhoneCode.dialCode) \(whatsappPhoneLocal)"
                    if let client {
                        store.updateClient(
                            client,
                            name: name,
                            contact: name,
                            address: address,
                            propertyDetails: propertyDetails,
                            phone: fullPhone,
                            whatsappPhone: fullWhatsApp,
                            email: email,
                            accessNotes: accessNotes,
                            preferredSchedule: preferredSchedule,
                            preferredDeliveryChannels: selectedChannels
                        )
                    } else {
                        store.addClient(
                            name: name,
                            contact: name,
                            address: address,
                            propertyDetails: propertyDetails,
                            phone: fullPhone,
                            whatsappPhone: fullWhatsApp,
                            email: email,
                            accessNotes: accessNotes,
                            preferredSchedule: preferredSchedule,
                            preferredDeliveryChannels: selectedChannels
                        )
                    }
                    onSave?()
                    dismiss()
                }
                .padding()
                .disabled(name.isEmpty)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Client" : "New Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if client == nil {
                    enableEmail = true
                }
            }
#if canImport(ContactsUI) && canImport(UIKit)
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contact in
                    apply(contact: contact)
                    showContactPicker = false
                } onCancel: {
                    showContactPicker = false
                }
            }
#endif
        }
    }

    private static func splitPhone(_ fullPhone: String) -> (code: CountryCode, number: String) {
        let trimmed = fullPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        for code in CountryCode.all {
            if trimmed.hasPrefix(code.dialCode) {
                let number = trimmed
                    .replacingOccurrences(of: code.dialCode, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (code, number)
            }
        }
        return (.defaultCode, trimmed)
    }

#if canImport(Contacts)
    private func apply(contact: CNContact) {
        if name.isEmpty {
            if let fullName = CNContactFormatter.string(from: contact, style: .fullName) {
                name = fullName
            } else {
                let composed = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if !composed.isEmpty { name = composed }
            }
        }

        if email.isEmpty, let value = contact.emailAddresses.first?.value as String?, !value.isEmpty {
            email = value
        }

        let numbers = contact.phoneNumbers.map { $0.value.stringValue }.filter { !$0.isEmpty }
        if phoneLocal.isEmpty, let first = numbers.first {
            applyPhone(first, code: &phoneCode, local: &phoneLocal)
        }
        if whatsappPhoneLocal.isEmpty, let second = numbers.dropFirst().first {
            applyPhone(second, code: &whatsappPhoneCode, local: &whatsappPhoneLocal)
        }
    }

    private func applyPhone(_ value: String, code: inout CountryCode, local: inout String) {
        let normalized = value.replacingOccurrences(of: " ", with: "")
        if let match = CountryCode.all.first(where: { normalized.hasPrefix($0.dialCode) }) {
            code = match
            let localPart = normalized.dropFirst(match.dialCode.count)
            local = String(localPart)
        } else {
            local = value
        }
    }
#endif
}
