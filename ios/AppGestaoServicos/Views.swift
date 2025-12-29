import SwiftUI
import Charts
import UIKit
import QuickLook

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
                            Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
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
                Text("Hello, \(name)")
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
                        Text(String(format: "%.1f h", totalWorkedHours))
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
                                    Text("\(summary.completed)/\(summary.total) completed")
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

    private var teams: [String] {
        Array(Set(store.employees.map { $0.team })).sorted()
    }

    private var tasksForSelectedScope: [ServiceTask] {
        let calendar = Calendar.current
        switch scope {
        case .day:
            return store.tasks.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        case .month:
            return store.tasks.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
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
        let allTasks = store.tasks
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
            Text("Client: \(task.clientName)")
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

struct ClientsView: View {
    @EnvironmentObject private var store: OfflineStore
    @EnvironmentObject private var menuController: MenuController
    @State private var showingForm = false
    let onMenu: (() -> Void)?

    init(onMenu: (() -> Void)? = nil) {
        self.onMenu = onMenu
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.clients) { client in
                    let hasPendingReceivables = store.finance.contains {
                        $0.clientName == client.name && $0.type == .receivable && $0.status == .pending
                    }

                    NavigationLink(destination: ClientDetailView(client: client)) {
                        HStack(spacing: 12) {
                            ContactAvatarView(name: client.name, phone: client.phone, size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.name).bold()
                                if !client.phone.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.primary)
                                        Text(client.phone)
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
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    MenuButton { onMenu?() ?? { menuController.isPresented = true }() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingForm = true }) {
                        Label("New", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ClientForm()
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
                        StatusPill(label: "Disputed", color: .red)
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
                    title = "Invoice - \(firstClient)"
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

    private var lineItems: [(title: String, date: Date, amount: Double)] {
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

        let items: [(title: String, date: Date, amount: Double)] = tasksForInvoice.compactMap { task in
            guard let typeId = task.serviceTypeId,
                  let serviceType = store.serviceTypes.first(where: { $0.id == typeId }),
                  serviceType.currency == entry.currency else { return nil }
            return (task.title, task.date, serviceType.basePrice)
        }

        if items.isEmpty {
            return [(entry.title, entry.dueDate, entry.amount)]
        }
        return items.sorted { $0.date < $1.date }
    }

    private var canAdjustInvoice: Bool {
        let calendar = Calendar.current
        let limit = calendar.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        return Date() <= limit
    }

    private var disputeDeadline: Date {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: dueDate)
        return calendar.date(byAdding: .day, value: store.appPreferences.disputeWindowDays + 1, to: base) ?? dueDate
    }

    private var disputeWindowOpen: Bool {
        Date() < disputeDeadline
    }

    private var canSave: Bool {
        guard let amount = parsedAmount else { return false }
        if isDisputed && disputeReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        return amount > 0 && !title.isEmpty
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
                    if let client {
                        Text("Preferred channels: \(client.preferredDeliveryChannels.map { $0.label }.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Picker("Channel", selection: $selectedChannel) {
                            ForEach(client.preferredDeliveryChannels) { channel in
                                Text(channel.label).tag(channel)
                            }
                        }
                    }
                    Button {
                        prepareShare()
                    } label: {
                        Label("Send / Reissue", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        preparePDFShare()
                    } label: {
                        Label("Generate PDF", systemImage: "doc.richtext")
                    }
                    if let url = makeChannelURL() {
                        Button {
                            openURL(url)
                        } label: {
                            Label("Open \(selectedChannel.label)", systemImage: "paperplane.fill")
                        }
                    }
                    if !canAdjustInvoice {
                        Text("Adjustments are blocked less than 1 day before due date.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
        .onAppear {
            if let firstChannel = client?.preferredDeliveryChannels.first {
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

    private func prepareShare() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let activeCurrency = store.appPreferences.preferredCurrency
        formatter.currencyCode = activeCurrency.code
        let amountString = formatter.string(from: NSNumber(value: parsedAmount ?? entry.amount)) ?? "\(activeCurrency.code) \(parsedAmount ?? entry.amount)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueString = dateFormatter.string(from: dueDate)

        var body = "Invoice: \(title)\nAmount: \(amountString)\nDue: \(dueString)"
        if let clientName = entry.clientName {
            body.append("\nClient: \(clientName)")
        }
        body.append("\nChannel: \(selectedChannel.label)")
        if isDisputed {
            let reason = disputeReason.isEmpty ? "Pending reason" : disputeReason
            body.append("\nStatus: DISPUTED - \(reason)")
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

        let instructions = "Please pay via \(method?.label ?? selectedChannel.label) by \(dateFormatter.string(from: dueDate))."
        let clientName = entry.clientName ?? "Client"
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

            draw("Invoice", font: .boldSystemFont(ofSize: 22))
            draw("Client: \(clientName)", font: .systemFont(ofSize: 14))
            if let email = client?.email, !email.isEmpty {
                draw("Email: \(email)", font: .systemFont(ofSize: 12), color: .darkGray)
            }
            if let phone = client?.phone, !phone.isEmpty {
                draw("Phone: \(phone)", font: .systemFont(ofSize: 12), color: .darkGray)
            }
            draw("Due date: \(dateFormatter.string(from: dueDate))", font: .systemFont(ofSize: 14))
            draw(instructions, font: .systemFont(ofSize: 12))
            if let disputeURL {
                drawLink(NSLocalizedString("Dispute this invoice", comment: ""), url: disputeURL, font: .systemFont(ofSize: 12))
            }

            y += 8
            draw("Line items", font: .boldSystemFont(ofSize: 16))

            for item in lineItems {
                let amount = numberFormatter.string(from: NSNumber(value: item.amount)) ?? "\(activeCurrency.code) \(item.amount)"
                draw("- \(item.title) (\(dateFormatter.string(from: item.date))): \(amount)", font: .systemFont(ofSize: 12))
            }

            let totalString = numberFormatter.string(from: NSNumber(value: parsedAmount ?? entry.amount)) ?? "\(activeCurrency.code) \(parsedAmount ?? entry.amount)"
            y += 8
            draw("Total: \(totalString)", font: .boldSystemFont(ofSize: 14))

            if isDisputed {
                let reason = disputeReason.isEmpty ? "Pending reason" : disputeReason
                draw("Status: DISPUTED - \(reason)", font: .boldSystemFont(ofSize: 12), color: .red)
            }
        }
    }

    private func makeChannelURL() -> URL? {
        guard let client else { return nil }
        switch selectedChannel {
        case .email:
            guard !client.email.isEmpty else { return nil }
            let subject = "Invoice \(title)"
            let body = "Hello \(client.name), here is your invoice \(title)."
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "mailto:\(client.email)?subject=\(encodedSubject)&body=\(encodedBody)")
        case .whatsapp:
            guard !client.phone.isEmpty else { return nil }
            let digits = client.phone.filter { $0.isNumber || $0 == "+" }
            let text = "Invoice \(title) - due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
            let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        case .imessage:
            guard !client.phone.isEmpty else { return nil }
            let digits = client.phone.filter { $0.isNumber || $0 == "+" }
            return URL(string: "sms:\(digits)")
        }
    }

    private func makeDisputeURL() -> URL? {
        guard let client else { return nil }

        let preferredChannels = client.preferredDeliveryChannels
        for channel in preferredChannels {
            if let url = disputeURL(for: channel, client: client) {
                return url
            }
        }
        return disputeURL(for: .email, client: client)
            ?? disputeURL(for: .imessage, client: client)
            ?? disputeURL(for: .whatsapp, client: client)
    }

    private func disputeURL(for channel: Client.DeliveryChannel, client: Client) -> URL? {
        let subject = "Dispute invoice \(title)"
        let body = "Hello \(client.name), I would like to dispute invoice \(title)."
        switch channel {
        case .email:
            guard !client.email.isEmpty else { return nil }
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "mailto:\(client.email)?subject=\(encodedSubject)&body=\(encodedBody)")
        case .whatsapp:
            guard !client.phone.isEmpty else { return nil }
            let digits = client.phone.filter { $0.isNumber || $0 == "+" }
            let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        case .imessage:
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
    @State private var amountText: String = ""
    @State private var currency: FinanceEntry.Currency = .usd
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var method: FinanceEntry.PaymentMethod? = nil
    @State private var showingConfirmation = false

    private var employeeNames: [String] {
        Array(Set(store.employees.map { $0.name })).sorted()
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        parsedAmount != nil && !selectedEmployeeName.isEmpty && !title.isEmpty
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
                    title = "Payroll - \(employee)"
                }
                currency = store.appPreferences.preferredCurrency
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let employeeId = store.employees.first(where: { $0.name == selectedEmployeeName })?.id
        store.addFinanceEntry(
            title: title,
            amount: amount,
            type: .payable,
            dueDate: dueDate,
            method: method,
            currency: store.appPreferences.preferredCurrency,
            clientName: nil,
            employeeId: employeeId,
            employeeName: selectedEmployeeName,
            kind: .payrollEmployee
        )
        dismiss()
    }
}

struct PayrollDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    let entry: FinanceEntry

    @State private var title: String
    @State private var amountText: String
    @State private var dueDate: Date
    @State private var currency: FinanceEntry.Currency
    @State private var method: FinanceEntry.PaymentMethod?
    @State private var status: FinanceEntry.Status

    init(entry: FinanceEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _amountText = State(initialValue: String(format: "%.2f", entry.amount))
        _dueDate = State(initialValue: entry.dueDate)
        _currency = State(initialValue: entry.currency)
        _method = State(initialValue: entry.method)
        _status = State(initialValue: entry.status)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canEditFields: Bool {
        status == .pending
    }

    private var canSave: Bool {
        parsedAmount != nil && !title.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Payroll") {
                    if let employee = entry.employeeName {
                        Text("Employee: \(employee)")
                            .font(.subheadline)
                    }
                    TextField("Title", text: $title)
                        .disabled(!canEditFields)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
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
        guard let amount = parsedAmount else { return }
        store.updateFinanceEntry(entry) { current in
            current.title = title
            current.amount = amount
            current.dueDate = dueDate
            current.currency = store.appPreferences.preferredCurrency
            current.method = method
            current.status = status
        }
        dismiss()
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
                        Text("Client: \(client)")
                            .font(.footnote)
                    }
                    if let employee = entry.employeeName {
                        Text("Employee: \(employee)")
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
                        Text("Client: \(client)")
                            .font(.footnote)
                    }
                    Text("Amount: \(entry.currency.code) \(entry.amount, specifier: "%.2f")")
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
                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(AppTheme.cornerRadius)
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
    }

    private func shareReceipt() {
        var items: [Any] = []
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let text = "Expense receipt for \(entry.title)\nAmount: \(entry.currency.code) \(entry.amount)\nDue: \(formatter.string(from: entry.dueDate))"
        items.append(text)
        if let image = receiptImage {
            items.append(image)
        }
        shareItems = items
        showingShareSheet = true
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
        if notifyClient { finalNotes.append(contentsOf: finalNotes.isEmpty ? "Notify client." : "\nNotify client.") }
        if notifyTeam { finalNotes.append(contentsOf: finalNotes.isEmpty ? "Notify team." : "\nNotify team.") }

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
            let text = "Expense receipt for \(clientName)\n\n\(title)\nAmount: \(activeCurrency.code) \(value)\nDue date: \(dateString)"
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
                        Text("User: \(session.name)")
                        Button("Sign out", role: .destructive) { store.logout() }
                    }
                }
                Section("Sync") {
                    Button("Force sync") { store.syncPendingChanges() }
                    if let lastSync = store.lastSync {
                        Text("Last: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if !store.pendingChanges.isEmpty {
                        Text("\(store.pendingChanges.count) pending changes in the queue")
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
                                Text("\(entry.entity) · \(entry.field)")
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

    private var clientTasks: [ServiceTask] {
        store.tasks
            .filter { $0.clientName == client.name }
            .sorted {
                let lhsDate = $0.startTime ?? $0.date
                let rhsDate = $1.startTime ?? $1.date
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        List {
            Section("Client") {
                Text(client.name).bold()
                if !client.phone.isEmpty {
                    Text("Phone: \(client.phone)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !client.email.isEmpty {
                    Text("Email: \(client.email)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text(client.address)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if !client.propertyDetails.isEmpty {
                    Text("Property: \(client.propertyDetails)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !client.preferredSchedule.isEmpty {
                    Text("Preferred schedule: \(client.preferredSchedule)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !client.preferredDeliveryChannels.isEmpty {
                Text("Invoice delivery: \(client.preferredDeliveryChannels.map { $0.label }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if !client.accessNotes.isEmpty {
                    Text("Access notes: \(client.accessNotes)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
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
        .navigationTitle(client.name)
        .sheet(isPresented: $showingServiceForm) {
            ServiceFormView(initialDate: Date(), client: client)
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
                        Text("Base price: \(serviceType.currency.code) \(serviceType.basePrice, specifier: "%.2f")")
                            .font(.body)
                    }
                }
                .padding(.horizontal)

                if linkedTasksCount > 0 {
                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Usage")
                                .font(.headline)
                            Text("Linked to \(linkedTasksCount) services. Reassign before deleting.")
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
    @State private var currency: FinanceEntry.Currency

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
        _currency = State(initialValue: serviceType?.currency ?? .usd)
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
                        currency: store.appPreferences.preferredCurrency
                    )
                } else {
                    store.addServiceType(
                        name: name,
                        description: description,
                        basePrice: price,
                        currency: store.appPreferences.preferredCurrency
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
        .onAppear {
            currency = store.appPreferences.preferredCurrency
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
                Section(header: Text("\(team.name) (\(team.members.count))")) {
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
                    Text("Team: \(employee.team)")
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
                    Button("Move to \(teamName)") {
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
            .accessibilityLabel(hasPending ? "Pending payments" : "No pending payments")
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
                        StatusPill(label: "Disputed", color: .red)
                    }
                    if entry.kind == .expenseOutOfPocket, entry.receiptData != nil {
                        StatusPill(label: "Receipt", color: .blue.opacity(0.7))
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
    @State private var status: ServiceTask.Status
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var showClientAlert = false
    @State private var showTeamAlert = false
    @State private var checkInTime: Date?
    @State private var checkOutTime: Date?
    let task: ServiceTask

    init(task: ServiceTask) {
        self.task = task
        _status = State(initialValue: task.status)
        _startTime = State(initialValue: task.startTime ?? task.date)
        _endTime = State(initialValue: task.endTime ?? task.date.addingTimeInterval(60 * 60))
        _notes = State(initialValue: task.notes)
        _checkInTime = State(initialValue: task.checkInTime)
        _checkOutTime = State(initialValue: task.checkOutTime)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Status") {
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

                Section("Client") {
                    Text(task.clientName).bold()
                    Text(task.address)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(task.assignedEmployee.name)
                        .font(.subheadline)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                Section("Check-in / Check-out") {
                    if let checkInTime {
                        Text("Checked in: \(checkInTime.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let checkOutTime {
                        Text("Checked out: \(checkOutTime.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Button("Check-in now") {
                            checkInTime = Date()
                        }
                        Button("Check-out now") {
                            checkOutTime = Date()
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
                                title: "Notification to client",
                                body: "Service \"\(task.title)\" updated for \(task.clientName)."
                            )
                        }
                    }
                    Button("Notify team") {
                        guard store.notificationPreferences.enableTeamNotifications else { return }
                        showTeamAlert = true
                        if store.notificationPreferences.enablePush {
                            store.sendLocalNotification(
                                title: "Notification to team",
                                body: "Service \"\(task.title)\" updated for \(task.assignedEmployee.name)."
                            )
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)

            PrimaryButton(title: "Save") {
                store.updateTask(
                    task,
                    status: status,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    checkInTime: checkInTime,
                    checkOutTime: checkOutTime
                )
                dismiss()
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(task.title)
        .alert("Notification sent to client", isPresented: $showClientAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Notification sent to team", isPresented: $showTeamAlert) {
            Button("OK", role: .cancel) { }
        }
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
    @State private var name = ""
    @State private var address = ""
    @State private var propertyDetails = ""
    @State private var phoneLocal = ""
    @State private var phoneCode: CountryCode = .defaultCode
    @State private var email = ""
    @State private var preferredSchedule = ""
    @State private var accessNotes = ""
    @State private var prefersEmail = true
    @State private var prefersWhatsApp = false
    @State private var prefersIMessage = false

    private var selectedChannels: [Client.DeliveryChannel] {
        var result: [Client.DeliveryChannel] = []
        if prefersEmail { result.append(.email) }
        if prefersWhatsApp { result.append(.whatsapp) }
        if prefersIMessage { result.append(.imessage) }
        return result.isEmpty ? [.email] : result
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
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    Section("Property & schedule") {
                        TextField("Address", text: $address)
                        TextField("Property (type, block, size)", text: $propertyDetails)
                        TextField("Preferred schedule", text: $preferredSchedule)
                    }
                    Section("Access") {
                        TextField("Access instructions / front desk", text: $accessNotes)
                    }
                    Section("Delivery channels for invoices") {
                        Toggle("Email", isOn: $prefersEmail)
                        Toggle("WhatsApp", isOn: $prefersWhatsApp)
                        Toggle("iMessage", isOn: $prefersIMessage)
                        Text("Used when sending invoices or receipts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)

                PrimaryButton(title: "Save") {
                    let fullPhone = phoneLocal.isEmpty ? "" : "\(phoneCode.dialCode) \(phoneLocal)"
                    store.addClient(
                        name: name,
                        contact: name,
                        address: address,
                        propertyDetails: propertyDetails,
                        phone: fullPhone,
                        email: email,
                        accessNotes: accessNotes,
                        preferredSchedule: preferredSchedule,
                        preferredDeliveryChannels: selectedChannels
                    )
                    dismiss()
                }
                .padding()
                .disabled(name.isEmpty)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
