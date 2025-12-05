import SwiftUI
import Charts

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

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge") }
            AgendaView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            ClientsView()
                .tabItem { Label("Clients", systemImage: "person.2") }
            FinanceView()
                .tabItem { Label("Finance", systemImage: "creditcard") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var scope: TimeScope = .day

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
    @State private var selectedDate = Date()
    @State private var showingForm = false
    @State private var scope: Scope = .day
    @State private var selectedTeam: String? = nil

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

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
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
    @State private var showingForm = false

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
    @State private var showingForm = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Receivables")) {
                    ForEach(store.finance.filter { $0.type == .receivable }) { entry in
                        FinanceRow(entry: entry) { status, method in
                            store.markFinanceEntry(entry, status: status, method: method)
                        }
                    }
                }
                Section(header: Text("Payables")) {
                    ForEach(store.finance.filter { $0.type == .payable }) { entry in
                        FinanceRow(entry: entry) { status, method in
                            store.markFinanceEntry(entry, status: status, method: method)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingForm = true }) {
                        Label("New", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new_finance_button")
                }
            }
            .sheet(isPresented: $showingForm) {
                FinanceFormView()
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
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        ForEach(FinanceEntry.Currency.allCases) { curr in
                            Text(curr.code).tag(curr)
                        }
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
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
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
        store.addFinanceEntry(title: title, amount: value, type: type, dueDate: dueDate, method: method, currency: currency)
        dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: OfflineStore

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

                if store.session?.role == .manager {
                    Section("Team") {
                        NavigationLink("Employees") {
                            EmployeesView()
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
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
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

private struct StatusBadge: View {
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
                        preferredSchedule: preferredSchedule
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
