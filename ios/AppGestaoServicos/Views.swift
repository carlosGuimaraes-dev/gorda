import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var user: String = ""
    @State private var password: String = ""
    @State private var role: UserSession.Role = .manager

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Service Management")
                    .font(.largeTitle.bold())
                VStack(spacing: 12) {
                    TextField("User", text: $user)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    Picker("Profile", selection: $role) {
                        Text("Employee").tag(UserSession.Role.employee)
                        Text("Manager").tag(UserSession.Role.manager)
                    }
                    .pickerStyle(.segmented)
                }
                Button(action: { store.login(user: user, password: password, role: role) }) {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                if let lastSync = store.lastSync {
                    Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                NavigationLink(destination: HomeView().environmentObject(store), isActive: .constant(store.session != nil)) {
                    EmptyView()
                }
            }
            .padding()
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
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var scope: TimeScope = .day

    private enum TimeScope: String, CaseIterable, Identifiable {
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
                Spacer()
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("Operations") {
                    HStack {
                        VStack {
                            Text("Total tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(tasksForScope.count)")
                                .font(.title2.bold())
                        }
                        Spacer()
                        let completed = tasksForScope.filter { $0.status == .completed }.count
                        VStack {
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(completed)")
                                .font(.title2.bold())
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)

                if !teamsSummary.isEmpty {
                    GroupBox("By team") {
                        ForEach(teamsSummary, id: \.team) { summary in
                            HStack {
                                Text(summary.team)
                                Spacer()
                                Text("\(summary.completed)/\(summary.total) completed")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }

                GroupBox("Finance") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Receivables")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: receivablesPending)) ?? "-")
                                .bold()
                                .foregroundColor(.green)
                        }
                        HStack {
                            Text("Payables")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: payablesPending)) ?? "-")
                                .bold()
                                .foregroundColor(.red)
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
                    }
                    .padding()
                }
                .padding(.horizontal)
            }
        }
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
                }
            }
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
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(client.name).bold()
                            Text("Contact: \(client.contact)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Phone: \(client.phone)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text("Email: \(client.email)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text(client.address)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Text("Property: \(client.propertyDetails)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
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
                    }
                }
            }
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
                Text("Contact: \(client.contact)")
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

struct FinanceRow: View {
    let entry: FinanceEntry
    var onStatusChange: (_ status: FinanceEntry.Status, _ method: FinanceEntry.PaymentMethod?) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.title).bold()
                Text(entry.dueDate, style: .date)
                    .font(.footnote)
                    .foregroundColor(.secondary)
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
        .navigationTitle(task.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
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
            }
        }
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

struct ClientForm: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var contact = ""
    @State private var address = ""
    @State private var propertyDetails = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var preferredSchedule = ""
    @State private var accessNotes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Identification") {
                    TextField("Name", text: $name)
                    TextField("Primary contact", text: $contact)
                }
                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
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
            .navigationTitle("New Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addClient(
                            name: name,
                            contact: contact,
                            address: address,
                            propertyDetails: propertyDetails,
                            phone: phone,
                            email: email,
                            accessNotes: accessNotes,
                            preferredSchedule: preferredSchedule
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || contact.isEmpty)
                }
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(OfflineStore())
}
