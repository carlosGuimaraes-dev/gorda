import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var user: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Gestão de Serviços")
                    .font(.largeTitle.bold())
                VStack(spacing: 12) {
                    TextField("Usuária", text: $user)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    SecureField("Senha", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                Button(action: { store.login(user: user, password: password) }) {
                    Text("Entrar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                if let lastSync = store.lastSync {
                    Text("Última sincronização: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
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
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }
            ClientsView()
                .tabItem { Label("Clientes", systemImage: "person.2") }
            FinanceView()
                .tabItem { Label("Financeiro", systemImage: "creditcard") }
            SettingsView()
                .tabItem { Label("Config", systemImage: "gear") }
        }
    }
}

struct AgendaView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var selectedDate = Date()
    @State private var showingForm = false

    var filteredTasks: [ServiceTask] {
        store.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Data", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                List {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: ServiceDetailView(task: task)) {
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
                                Text("Cliente: \(task.clientName)")
                                    .font(.subheadline)
                                Text(task.address)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Text(task.notes)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingForm = true }) {
                        Label("Novo serviço", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new_service_button")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { store.syncPendingChanges() }) {
                        Label("Sincronizar", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ServiceFormView(initialDate: selectedDate)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name).bold()
                        Text("Contato: \(client.contact)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Telefone: \(client.phone)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("E-mail: \(client.email)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(client.address)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Imóvel: \(client.propertyDetails)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if !client.preferredSchedule.isEmpty {
                            Text("Horário preferido: \(client.preferredSchedule)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        if !client.accessNotes.isEmpty {
                            Text("Acesso: \(client.accessNotes)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Clientes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingForm = true }) {
                        Label("Novo", systemImage: "plus")
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
                Section(header: Text("A receber")) {
                    ForEach(store.finance.filter { $0.type == .receivable }) { entry in
                        FinanceRow(entry: entry) { status, method in
                            store.markFinanceEntry(entry, status: status, method: method)
                        }
                    }
                }
                Section(header: Text("A pagar")) {
                    ForEach(store.finance.filter { $0.type == .payable }) { entry in
                        FinanceRow(entry: entry) { status, method in
                            store.markFinanceEntry(entry, status: status, method: method)
                        }
                    }
                }
            }
            .navigationTitle("Financeiro")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingForm = true }) {
                        Label("Novo", systemImage: "plus")
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Serviço") {
                    TextField("Título", text: $title)
                    Picker("Status", selection: $status) {
                        ForEach(ServiceTask.Status.allCases) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Data e horários") {
                    DatePicker("Data", selection: $selectedDate, displayedComponents: .date)
                    DatePicker("Início", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Fim", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Responsáveis") {
                    if store.employees.isEmpty {
                        Text("Cadastre pelo menos um funcionário para criar serviços.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Funcionário", selection: Binding(
                            get: { selectedEmployeeID ?? store.employees.first?.id },
                            set: { selectedEmployeeID = $0 }
                        )) {
                            ForEach(store.employees, id: \.id) { employee in
                                Text(employee.name).tag(employee.id as UUID?)
                            }
                        }
                    }

                    if store.clients.isEmpty {
                        Text("Cadastre pelo menos um cliente para criar serviços.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Cliente", selection: Binding(
                            get: { selectedClientID ?? store.clients.first?.id },
                            set: { selectedClientID = $0 }
                        )) {
                            ForEach(store.clients, id: \.id) { client in
                                Text(client.name).tag(client.id as UUID?)
                            }
                        }
                    }
                }

                Section("Notas e notificações") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                    Toggle("Notificar cliente", isOn: $notifyClient)
                    Toggle("Notificar equipe", isOn: $notifyTeam)
                }
            }
            .navigationTitle("Novo Serviço")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if selectedEmployeeID == nil { selectedEmployeeID = store.employees.first?.id }
                if selectedClientID == nil { selectedClientID = store.clients.first?.id }
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
        if notifyClient { finalNotes.append(contentsOf: finalNotes.isEmpty ? "Notificar cliente." : "\nNotificar cliente.") }
        if notifyTeam { finalNotes.append(contentsOf: finalNotes.isEmpty ? "Notificar equipe." : "\nNotificar equipe.") }

        store.addTask(
            title: title,
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            employee: employee,
            clientName: client.name,
            address: client.address,
            notes: finalNotes,
            status: status
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Lançamento") {
                    TextField("Título", text: $title)
                    TextField("Valor", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Vencimento", selection: $dueDate, displayedComponents: .date)
                }

                Section("Tipo") {
                    Picker("", selection: $type) {
                        Text("A receber").tag(FinanceEntry.EntryType.receivable)
                        Text("A pagar").tag(FinanceEntry.EntryType.payable)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Método (opcional)") {
                    Picker("Método", selection: $method) {
                        Text("Não registrar agora").tag(nil as FinanceEntry.PaymentMethod?)
                        ForEach(FinanceEntry.PaymentMethod.allCases) { method in
                            Text(method.label).tag(method as FinanceEntry.PaymentMethod?)
                        }
                    }
                }
            }
            .navigationTitle("Novo Lançamento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
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
        store.addFinanceEntry(title: title, amount: value, type: type, dueDate: dueDate, method: method)
        dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: OfflineStore

    var body: some View {
        NavigationStack {
            List {
                if let session = store.session {
                    Section("Sessão") {
                        Text("Usuária: \(session.name)")
                        Button("Sair", role: .destructive) { store.logout() }
                    }
                }
                Section("Sync") {
                    Button("Forçar sincronização") { store.syncPendingChanges() }
                    if let lastSync = store.lastSync {
                        Text("Última: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Configurações")
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
                Button("Marcar pago (Pix)") {
                    onStatusChange(.paid, .pix)
                }
                Button("Marcar pago (Cartão)") {
                    onStatusChange(.paid, .card)
                }
                Button("Marcar pago (Dinheiro)") {
                    onStatusChange(.paid, .cash)
                }
                if entry.status == .paid {
                    Button("Voltar para pendente") {
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
        formatter.locale = Locale(identifier: "pt_BR")
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
    let task: ServiceTask

    init(task: ServiceTask) {
        self.task = task
        _status = State(initialValue: task.status)
        _startTime = State(initialValue: task.startTime ?? task.date)
        _endTime = State(initialValue: task.endTime ?? task.date.addingTimeInterval(60 * 60))
        _notes = State(initialValue: task.notes)
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

            Section("Agendamento") {
                DatePicker("Início", selection: $startTime, displayedComponents: [.hourAndMinute, .date])
                DatePicker("Fim", selection: $endTime, displayedComponents: [.hourAndMinute, .date])
            }

            Section("Cliente") {
                Text(task.clientName).bold()
                Text(task.address)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(task.assignedEmployee.name)
                    .font(.subheadline)
            }

            Section("Notas") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }

            Section("Ações rápidas") {
                Button("Marcar concluído") { status = .completed }
                Button("Cancelar serviço", role: .destructive) { status = .canceled }
                Button("Notificar cliente") { showClientAlert = true }
                Button("Notificar equipe") { showTeamAlert = true }
            }
        }
        .navigationTitle(task.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") {
                    store.updateTask(task, status: status, startTime: startTime, endTime: endTime, notes: notes)
                    dismiss()
                }
            }
        }
        .alert("Notificação enviada ao cliente", isPresented: $showClientAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Notificação enviada à equipe", isPresented: $showTeamAlert) {
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
                Section("Identificação") {
                    TextField("Nome", text: $name)
                    TextField("Contato principal", text: $contact)
                }
                Section("Contato") {
                    TextField("Telefone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Imóvel e agenda") {
                    TextField("Endereço", text: $address)
                    TextField("Imóvel (tipo, bloco, metragem)", text: $propertyDetails)
                    TextField("Horário preferido", text: $preferredSchedule)
                }
                Section("Acesso") {
                    TextField("Instruções de acesso/portaria", text: $accessNotes)
                }
            }
            .navigationTitle("Novo Cliente")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
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
