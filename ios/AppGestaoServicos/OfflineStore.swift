import Foundation
import SwiftUI
import UserNotifications
import CoreData
import Intents

final class OfflineStore: ObservableObject {
    @Published private(set) var clients: [Client] = []
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var tasks: [ServiceTask] = []
    @Published private(set) var finance: [FinanceEntry] = []
    @Published private(set) var serviceTypes: [ServiceType] = []
    @Published private(set) var pendingChanges: [PendingChange] = []
    @Published private(set) var conflictLog: [ConflictLogEntry] = []
    @Published var notificationPreferences = NotificationPreferences() {
        didSet { persist() }
    }
    @Published var appPreferences = AppPreferences() {
        didSet {
            if oldValue.preferredCurrency != appPreferences.preferredCurrency {
                applyPreferredCurrency()
            }
            persist()
        }
    }
    @Published var session: UserSession?
    @Published var lastSync: Date?

    private let context: NSManagedObjectContext

    private let persistenceURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("offline_data.json")
    }()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        load()
        seedDemoDataIfNeeded()
        backfillRelationshipsIfNeeded()
        applyPreferredCurrency()
    }

    func login(user: String, password: String, role: UserSession.Role) {
        guard !user.isEmpty, !password.isEmpty else { return }
        session = UserSession(token: UUID().uuidString, name: user, role: role)
        if let session {
            KeychainHelper.saveSession(session)
        }
        persist()
    }

    func logout() {
        session = nil
        KeychainHelper.deleteSession()
        persist()
    }

    func addTask(
        title: String,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        employee: Employee,
        clientId: UUID? = nil,
        clientName: String,
        address: String,
        notes: String,
        status: ServiceTask.Status = .scheduled,
        serviceTypeId: UUID? = nil
    ) {
        let task = ServiceTask(
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            status: status,
            assignedEmployee: employee,
            clientId: clientId,
            clientName: clientName,
            address: address,
            notes: notes,
            serviceTypeId: serviceTypeId
        )
        tasks.append(task)
        pendingChanges.append(PendingChange(operation: .addTask, entityId: task.id))
        saveTaskToCoreData(task)
        donateServiceCreationShortcut(for: task)
        persist()
    }

    func updateTask(
        _ task: ServiceTask,
        status: ServiceTask.Status,
        startTime: Date? = nil,
        endTime: Date? = nil,
        notes: String? = nil,
        checkInTime: Date? = nil,
        checkOutTime: Date? = nil
    ) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
        tasks[index].startTime = startTime ?? tasks[index].startTime
        tasks[index].endTime = endTime ?? tasks[index].endTime
        tasks[index].notes = notes ?? tasks[index].notes
        tasks[index].checkInTime = checkInTime ?? tasks[index].checkInTime
        tasks[index].checkOutTime = checkOutTime ?? tasks[index].checkOutTime
        pendingChanges.append(PendingChange(operation: .updateTask, entityId: task.id))
        saveTaskToCoreData(tasks[index])
        persist()
    }

    func addClient(
        name: String,
        contact: String,
        address: String,
        propertyDetails: String,
        phone: String,
        whatsappPhone: String,
        email: String,
        accessNotes: String,
        preferredSchedule: String
    ) {
        let channels = availableDeliveryChannels(phone: phone, whatsappPhone: whatsappPhone, email: email)
        let client = Client(
            id: UUID(),
            name: name,
            contact: contact,
            address: address,
            propertyDetails: propertyDetails,
            phone: phone,
            whatsappPhone: whatsappPhone,
            email: email,
            accessNotes: accessNotes,
            preferredSchedule: preferredSchedule,
            preferredDeliveryChannels: channels
        )
        clients.append(client)
        pendingChanges.append(PendingChange(operation: .addClient, entityId: client.id))
        saveClientToCoreData(client)
        persist()
    }

    func addFinanceEntry(
        title: String,
        amount: Double,
        type: FinanceEntry.EntryType,
        dueDate: Date,
        method: FinanceEntry.PaymentMethod? = nil,
        currency: FinanceEntry.Currency = .usd,
        clientId: UUID? = nil,
        clientName: String? = nil,
        employeeId: UUID? = nil,
        employeeName: String? = nil,
        kind: FinanceEntry.Kind = .general,
        receiptData: Data? = nil,
        isDisputed: Bool = false,
        disputeReason: String? = nil
    ) {
        let matchedClient = clientId.flatMap { id in
            clients.first(where: { $0.id == id })
        } ?? clientName.flatMap { name in
            clients.first(where: { $0.name == name })
        }
        let matchedEmployee = employeeId.flatMap { id in
            employees.first(where: { $0.id == id })
        } ?? employeeName.flatMap { name in
            employees.first(where: { $0.name == name })
        }

        let lockedCurrency = appPreferences.preferredCurrency
        let entry = FinanceEntry(
            title: title,
            amount: amount,
            type: type,
            dueDate: dueDate,
            status: .pending,
            method: method,
            currency: lockedCurrency,
            clientId: clientId ?? matchedClient?.id,
            clientName: clientName ?? matchedClient?.name,
            employeeId: employeeId ?? matchedEmployee?.id,
            employeeName: employeeName ?? matchedEmployee?.name,
            kind: kind,
            isDisputed: isDisputed,
            disputeReason: disputeReason,
            receiptData: receiptData
        )
        finance.append(entry)
        pendingChanges.append(PendingChange(operation: .addFinanceEntry, entityId: entry.id))
        saveFinanceEntryToCoreData(entry)
        persist()
    }

    func addServiceType(
        name: String,
        description: String,
        basePrice: Double,
        currency: FinanceEntry.Currency
    ) {
        let lockedCurrency = appPreferences.preferredCurrency
        let serviceType = ServiceType(
            name: name,
            description: description,
            basePrice: basePrice,
            currency: lockedCurrency
        )
        serviceTypes.append(serviceType)
        pendingChanges.append(PendingChange(operation: .addServiceType, entityId: serviceType.id))
        saveServiceTypeToCoreData(serviceType)
        persist()
    }

    func updateServiceType(
        _ serviceType: ServiceType,
        name: String,
        description: String,
        basePrice: Double,
        currency: FinanceEntry.Currency
    ) {
        guard let index = serviceTypes.firstIndex(where: { $0.id == serviceType.id }) else { return }
        let lockedCurrency = appPreferences.preferredCurrency
        serviceTypes[index].name = name
        serviceTypes[index].description = description
        serviceTypes[index].basePrice = basePrice
        serviceTypes[index].currency = lockedCurrency
        pendingChanges.append(PendingChange(operation: .updateServiceType, entityId: serviceType.id))
        saveServiceTypeToCoreData(serviceTypes[index])
        persist()
    }

    func deleteServiceType(_ serviceType: ServiceType) -> Bool {
        let isLinked = tasks.contains { $0.serviceTypeId == serviceType.id }
        guard !isLinked else { return false }
        serviceTypes.removeAll { $0.id == serviceType.id }
        pendingChanges.append(PendingChange(operation: .deleteServiceType, entityId: serviceType.id))
        deleteServiceTypeFromCoreData(serviceType.id)
        persist()
        return true
    }

    func markFinanceEntry(_ entry: FinanceEntry, status: FinanceEntry.Status, method: FinanceEntry.PaymentMethod?) {
        guard let index = finance.firstIndex(where: { $0.id == entry.id }) else { return }
        finance[index].status = status
        finance[index].method = method
        pendingChanges.append(PendingChange(operation: .markFinanceEntry, entityId: entry.id))
        saveFinanceEntryToCoreData(finance[index])
        persist()
    }

    func updateFinanceEntry(_ entry: FinanceEntry, mutate: (inout FinanceEntry) -> Void) {
        guard let index = finance.firstIndex(where: { $0.id == entry.id }) else { return }
        mutate(&finance[index])
        finance[index].currency = appPreferences.preferredCurrency
        pendingChanges.append(PendingChange(operation: .updateFinanceEntry, entityId: entry.id))
        saveFinanceEntryToCoreData(finance[index])
        persist()
    }

    func markInvoiceDisputed(_ entry: FinanceEntry, reason: String?) {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: entry.dueDate)
        let deadline = calendar.date(byAdding: .day, value: appPreferences.disputeWindowDays + 1, to: base) ?? entry.dueDate
        guard Date() < deadline else { return }
        updateFinanceEntry(entry) { current in
            current.isDisputed = true
            current.disputeReason = reason
        }
    }

    func deleteFinanceEntry(_ entry: FinanceEntry) {
        finance.removeAll { $0.id == entry.id }
        pendingChanges.append(PendingChange(operation: .deleteFinanceEntry, entityId: entry.id))
        deleteFinanceEntryFromCoreData(entry.id)
        persist()
    }

    func generateInvoices(from startDate: Date, to endDate: Date, dueDate: Date, clientName: String? = nil) {
        let relevantTasks = tasks.filter { task in
            guard task.status != .canceled else { return false }
            return task.date >= startDate && task.date <= endDate
        }

        let groupedByClient: [String: [ServiceTask]] = Dictionary(grouping: relevantTasks) { task in
            if let clientId = task.clientId {
                return clientId.uuidString
            }
            return task.clientName
        }
        let allowedClientIds: Set<UUID>?
        let allowedClientNames: Set<String>?
        if let specific = clientName {
            let matches = clients.filter { $0.name == specific }
            allowedClientIds = Set(matches.map { $0.id })
            allowedClientNames = [specific]
        } else {
            allowedClientIds = nil
            allowedClientNames = nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let periodLabel = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"

        for (key, clientTasks) in groupedByClient {
            guard !clientTasks.isEmpty else { continue }

            if let allowedIds = allowedClientIds, let allowedNames = allowedClientNames {
                let isAllowed: Bool
                if let id = UUID(uuidString: key) {
                    isAllowed = allowedIds.contains(id)
                } else {
                    isAllowed = allowedNames.contains(key)
                }
                guard isAllowed else { continue }
            }

            let resolvedClientId: UUID? = {
                if let id = UUID(uuidString: key) {
                    return id
                }
                if let taskId = clientTasks.first?.clientId {
                    return taskId
                }
                if let name = clientTasks.first?.clientName {
                    return clients.first(where: { $0.name == name })?.id
                }
                return nil
            }()

            let resolvedClientName: String = {
                if let resolvedClientId,
                   let matched = clients.first(where: { $0.id == resolvedClientId }) {
                    return matched.name
                }
                if let name = clientTasks.first?.clientName, !name.isEmpty {
                    return name
                }
                return key
            }()

            var totalsByCurrency: [FinanceEntry.Currency: Double] = [:]
            for task in clientTasks {
                guard let typeId = task.serviceTypeId,
                      let serviceType = serviceTypes.first(where: { $0.id == typeId }) else { continue }
                totalsByCurrency[serviceType.currency, default: 0] += serviceType.basePrice
            }

            for (currency, total) in totalsByCurrency {
                guard total > 0 else { continue }
                let title = "Invoice \(resolvedClientName) (\(periodLabel)) \(currency.code)"

                let entry = FinanceEntry(
                    title: title,
                    amount: total,
                    type: .receivable,
                    dueDate: dueDate,
                    status: .pending,
                    method: nil,
                    currency: currency,
                    clientId: resolvedClientId,
                    clientName: resolvedClientName,
                    employeeId: nil,
                    employeeName: nil,
                    kind: .invoiceClient
                )
                finance.append(entry)
                pendingChanges.append(PendingChange(operation: .addFinanceEntry, entityId: entry.id))
                saveFinanceEntryToCoreData(entry)
            }
        }

        persist()
    }

    func generatePayrolls(from startDate: Date, to endDate: Date, dueDate: Date, employeeName: String? = nil) {
        let targetEmployees: [Employee]
        if let specific = employeeName {
            targetEmployees = employees.filter { $0.name == specific }
        } else {
            targetEmployees = employees
        }

        for employee in targetEmployees {
            guard let rate = employee.hourlyRate else { continue }
            let payrollCurrency = appPreferences.preferredCurrency

            let employeeTasks = tasks.filter { task in
                (task.assignedEmployee.id == employee.id || task.assignedEmployee.name == employee.name) &&
                task.date >= startDate && task.date <= endDate &&
                task.checkInTime != nil && task.checkOutTime != nil &&
                task.status != .canceled
            }

            let totalHours: Double = employeeTasks.compactMap { task in
                guard let checkIn = task.checkInTime, let checkOut = task.checkOutTime else { return nil }
                let interval = checkOut.timeIntervalSince(checkIn)
                return interval > 0 ? interval / 3600.0 : nil
            }.reduce(0, +)

            guard totalHours > 0 else { continue }

            let totalAmount = totalHours * rate

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let periodLabel = formatter.string(from: startDate)

            let title = "Payroll \(employee.name) \(periodLabel)"

            let entry = FinanceEntry(
                title: title,
                amount: totalAmount,
                type: .payable,
                dueDate: dueDate,
                status: .pending,
                method: nil,
                currency: payrollCurrency,
                clientId: nil,
                clientName: nil,
                employeeId: employee.id,
                employeeName: employee.name,
                kind: .payrollEmployee
            )
            finance.append(entry)
            pendingChanges.append(PendingChange(operation: .addFinanceEntry, entityId: entry.id))
            saveFinanceEntryToCoreData(entry)
        }

        persist()
    }

    func addEmployee(
        name: String,
        roleTitle: String,
        team: String,
        phone: String?,
        hourlyRate: Double?,
        currency: Employee.Currency?,
        extraEarningsDescription: String?,
        documentsDescription: String?
    ) {
        let lockedCurrency = employeeCurrency(for: appPreferences.preferredCurrency)
        let employee = Employee(
            id: UUID(),
            name: name,
            role: roleTitle,
            team: team,
            phone: phone,
            hourlyRate: hourlyRate,
            currency: lockedCurrency,
            extraEarningsDescription: extraEarningsDescription,
            documentsDescription: documentsDescription
        )
        employees.append(employee)
        pendingChanges.append(PendingChange(operation: .addEmployee, entityId: employee.id))
        saveEmployeeToCoreData(employee)
        persist()
    }

    func updateEmployee(
        _ employee: Employee,
        name: String,
        roleTitle: String,
        team: String,
        phone: String?,
        hourlyRate: Double?,
        currency: Employee.Currency?,
        extraEarningsDescription: String?,
        documentsDescription: String?
    ) {
        guard let index = employees.firstIndex(where: { $0.id == employee.id }) else { return }
        let lockedCurrency = employeeCurrency(for: appPreferences.preferredCurrency)
        employees[index].name = name
        employees[index].role = roleTitle
        employees[index].team = team
        employees[index].phone = phone
        employees[index].hourlyRate = hourlyRate
        employees[index].currency = lockedCurrency
        employees[index].extraEarningsDescription = extraEarningsDescription
        employees[index].documentsDescription = documentsDescription
        pendingChanges.append(PendingChange(operation: .updateEmployee, entityId: employee.id))
        saveEmployeeToCoreData(employees[index])
        persist()
    }

    func deleteEmployee(_ employee: Employee) -> Bool {
        let isAssigned = tasks.contains { $0.assignedEmployee.id == employee.id }
        guard !isAssigned else { return false }
        employees.removeAll { $0.id == employee.id }
        pendingChanges.append(PendingChange(operation: .deleteEmployee, entityId: employee.id))
        deleteEmployeeFromCoreData(employee.id)
        persist()
        return true
    }

    func syncPendingChanges() {
        // Ponto para integrar com backend.
        // Aqui simulamos envio da fila com política simples
        // de "última escrita vence" por entidade.
        if !pendingChanges.isEmpty {
            let sorted = pendingChanges.sorted { $0.timestamp < $1.timestamp }
            var latestByEntity: [UUID: PendingChange] = [:]
            for change in sorted {
                latestByEntity[change.entityId] = change
            }
            let finalChanges = latestByEntity.values.sorted { $0.timestamp < $1.timestamp }

            print("Sincronizando \(finalChanges.count) mudanças (de \(pendingChanges.count) pendentes)...")
            for change in finalChanges {
                print(" - \(change.operation.rawValue) para \(change.entityId) em \(change.timestamp)")
            }

            pendingChanges.removeAll()
        }
        lastSync = Date()
        persist()
    }

    func recordConflict(entity: String, field: String, summary: String) {
        let entry = ConflictLogEntry(entity: entity, field: field, summary: summary)
        conflictLog.append(entry)
        persist()
    }

    func requestPushAuthorizationIfNeeded() {
        guard notificationPreferences.enablePush else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                // Resultado poderia ser persistido ou enviado ao backend em uma versão futura.
            }
        }
    }

    func sendLocalNotification(title: String, body: String) {
        guard notificationPreferences.enablePush else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func donateServiceCreationShortcut(for task: ServiceTask) {
        guard notificationPreferences.enableSiri else { return }

        let activity = NSUserActivity(activityType: "com.gorda.AppGestaoServicos.createService")
        activity.title = NSLocalizedString("Create service", comment: "")
        activity.userInfo = [
            "title": task.title,
            "clientName": task.clientName
        ]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = String(
            format: NSLocalizedString("Create service for %@", comment: ""),
            task.clientName
        )
        activity.becomeCurrent()
    }

    private func persist() {
        do {
            let snapshot = Snapshot(
                clients: clients,
                employees: employees,
                tasks: tasks,
                finance: finance,
                session: session.map { UserSession(token: "", name: $0.name, role: $0.role) },
                lastSync: lastSync,
                pendingChanges: pendingChanges,
                notificationPreferences: notificationPreferences,
                appPreferences: appPreferences,
                conflictLog: conflictLog
            )
            let data = try JSONEncoder().encode(snapshot)
            let payload = try encryptSnapshotData(data)
            try payload.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Falha ao persistir: \(error)")
        }
    }

    private func load() {
        // Primeiro tenta Core Data; se estiver vazio, cai para o JSON antigo.
        let requestClients = NSFetchRequest<NSManagedObject>(entityName: "ClientEntity")
        let requestEmployees = NSFetchRequest<NSManagedObject>(entityName: "EmployeeEntity")
        let requestServiceTypes = NSFetchRequest<NSManagedObject>(entityName: "ServiceTypeEntity")
        let requestTasks = NSFetchRequest<NSManagedObject>(entityName: "ServiceTaskEntity")
        let requestFinance = NSFetchRequest<NSManagedObject>(entityName: "FinanceEntryEntity")

        do {
            let clientObjects = try context.fetch(requestClients)
            let employeeObjects = try context.fetch(requestEmployees)
            let serviceTypeObjects = try context.fetch(requestServiceTypes)
            let taskObjects = try context.fetch(requestTasks)
            let financeObjects = try context.fetch(requestFinance)

            if !clientObjects.isEmpty || !employeeObjects.isEmpty || !serviceTypeObjects.isEmpty || !taskObjects.isEmpty || !financeObjects.isEmpty {
                self.clients = clientObjects.compactMap(Self.clientFromManagedObject)
                self.employees = employeeObjects.compactMap(Self.employeeFromManagedObject)
                self.serviceTypes = serviceTypeObjects.compactMap(Self.serviceTypeFromManagedObject)
                self.tasks = taskObjects.compactMap { self.taskFromManagedObject($0) }
                self.finance = financeObjects.compactMap { self.financeFromManagedObject($0) }
            }
        } catch {
            // Se der erro, tenta fallback em JSON.
        }

        if clients.isEmpty && employees.isEmpty && tasks.isEmpty && finance.isEmpty {
            // Fallback para snapshot antigo, se Core Data estiver vazio.
            do {
                let data = try Data(contentsOf: persistenceURL)
                let decoded = try decryptSnapshotData(data)
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: decoded)
                self.clients = snapshot.clients
                self.employees = snapshot.employees
                self.tasks = snapshot.tasks
                self.finance = snapshot.finance
                self.session = snapshot.session
                self.lastSync = snapshot.lastSync
                self.pendingChanges = snapshot.pendingChanges
                self.notificationPreferences = snapshot.notificationPreferences
                self.appPreferences = snapshot.appPreferences
                self.conflictLog = snapshot.conflictLog
            } catch {
                // Primeiro uso ou dados indisponíveis; segue vazio.
            }
        }

        if let secureSession = KeychainHelper.loadSession() {
            self.session = secureSession
        }
    }

    private func backfillRelationshipsIfNeeded() {
        var didUpdate = false

        for index in tasks.indices {
            var task = tasks[index]
            var updated = false

            if let clientId = task.clientId,
               let matchedClient = clients.first(where: { $0.id == clientId }) {
                if task.clientName != matchedClient.name {
                    task.clientName = matchedClient.name
                    updated = true
                }
            } else if let matchedClient = clients.first(where: {
                (!$0.name.isEmpty && $0.name == task.clientName) || (!$0.address.isEmpty && $0.address == task.address)
            }) {
                task.clientId = matchedClient.id
                task.clientName = matchedClient.name
                updated = true
            }

            if let matchedEmployee = employees.first(where: { $0.id == task.assignedEmployee.id }) {
                if task.assignedEmployee.name != matchedEmployee.name {
                    task.assignedEmployee = matchedEmployee
                    updated = true
                }
            } else if let matchedEmployee = employees.first(where: { $0.name == task.assignedEmployee.name }) {
                task.assignedEmployee = matchedEmployee
                updated = true
            }

            if updated {
                tasks[index] = task
                saveTaskToCoreData(task)
                didUpdate = true
            }
        }

        for index in finance.indices {
            var entry = finance[index]
            var updated = false

            if let clientId = entry.clientId,
               let matchedClient = clients.first(where: { $0.id == clientId }) {
                if entry.clientName != matchedClient.name {
                    entry.clientName = matchedClient.name
                    updated = true
                }
            } else if let clientName = entry.clientName,
                      let matchedClient = clients.first(where: { $0.name == clientName }) {
                entry.clientId = matchedClient.id
                entry.clientName = matchedClient.name
                updated = true
            }

            if let employeeId = entry.employeeId,
               let matchedEmployee = employees.first(where: { $0.id == employeeId }) {
                if entry.employeeName != matchedEmployee.name {
                    entry.employeeName = matchedEmployee.name
                    updated = true
                }
            } else if let employeeName = entry.employeeName,
                      let matchedEmployee = employees.first(where: { $0.name == employeeName }) {
                entry.employeeId = matchedEmployee.id
                entry.employeeName = matchedEmployee.name
                updated = true
            }

            if updated {
                finance[index] = entry
                saveFinanceEntryToCoreData(entry)
                didUpdate = true
            }
        }

        if didUpdate {
            persist()
        }
    }

    private func applyPreferredCurrency() {
        let preferred = appPreferences.preferredCurrency
        let lockedEmployeeCurrency = employeeCurrency(for: preferred)
        var didUpdate = false

        for index in serviceTypes.indices {
            if serviceTypes[index].currency != preferred {
                serviceTypes[index].currency = preferred
                saveServiceTypeToCoreData(serviceTypes[index])
                didUpdate = true
            }
        }

        for index in employees.indices {
            if employees[index].currency != lockedEmployeeCurrency {
                employees[index].currency = lockedEmployeeCurrency
                saveEmployeeToCoreData(employees[index])
                didUpdate = true
            }
        }

        for index in finance.indices {
            if finance[index].currency != preferred {
                finance[index].currency = preferred
                saveFinanceEntryToCoreData(finance[index])
                didUpdate = true
            }
        }

        if didUpdate {
            persist()
        }
    }

    private func employeeCurrency(for currency: FinanceEntry.Currency) -> Employee.Currency {
        Employee.Currency(rawValue: currency.rawValue) ?? .usd
    }

    private func availableDeliveryChannels(phone: String, whatsappPhone: String, email: String) -> [Client.DeliveryChannel] {
        var channels: [Client.DeliveryChannel] = []
        if !whatsappPhone.isEmpty || !phone.isEmpty {
            channels.append(.whatsapp)
        }
        if !phone.isEmpty {
            channels.append(.sms)
        }
        if !email.isEmpty {
            channels.append(.email)
        }
        return channels.isEmpty ? [.email] : channels
    }

    private func encryptSnapshotData(_ data: Data) throws -> Data {
        let header = Data("ENCv1:".utf8)
        let encrypted = try CryptoHelper.encrypt(data)
        return header + encrypted
    }

    private func decryptSnapshotData(_ data: Data) throws -> Data {
        let header = Data("ENCv1:".utf8)
        if data.prefix(header.count) == header {
            let payload = data.dropFirst(header.count)
            return try CryptoHelper.decrypt(payload)
        }
        return data
    }

    private func encryptString(_ value: String) -> String {
        CryptoHelper.encryptString(value)
    }

    private func decryptString(_ value: String) -> String {
        CryptoHelper.decryptString(value)
    }

    private func encryptData(_ data: Data?) -> Data? {
        CryptoHelper.encryptData(data)
    }

    private func decryptData(_ data: Data?) -> Data? {
        CryptoHelper.decryptData(data)
    }

    private func seedDemoDataIfNeeded() {
        // Caso novo (sem dados): cria um cenário completo.
        if clients.isEmpty && employees.isEmpty && tasks.isEmpty && finance.isEmpty {
            createFullDemoData()
            return
        }

        // Caso antigo com apenas um registro da seed anterior: adiciona mais dados.
        if clients.count == 1,
           employees.count == 1,
           tasks.count == 1,
           finance.count == 1,
           clients.first?.name == "Carla Lima" {
            createAdditionalDemoData(usingExistingEmployee: employees[0], existingClient: clients[0])
        }
    }

    private func createFullDemoData() {
        notificationPreferences = NotificationPreferences(
            enableClientNotifications: true,
            enableTeamNotifications: true,
            enablePush: true,
            enableSiri: false
        )

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Employees
        let employeeAna = Employee(
            id: UUID(),
            name: "Ana Souza",
            role: "Cleaner",
            team: "Team A",
            phone: "+351 910 000 001",
            hourlyRate: 25,
            currency: .eur,
            extraEarningsDescription: "Night and weekend bonus",
            documentsDescription: "EU work permit"
        )
        let employeeJohn = Employee(
            id: UUID(),
            name: "John Miller",
            role: "Cleaner",
            team: "Team B",
            phone: "+1 (415) 555-0120",
            hourlyRate: 22,
            currency: .usd,
            extraEarningsDescription: "Overtime",
            documentsDescription: "US resident"
        )
        let employeeMaria = Employee(
            id: UUID(),
            name: "Maria Garcia",
            role: "Senior cleaner",
            team: "Team C",
            phone: "+34 600 987 654",
            hourlyRate: 28,
            currency: .eur,
            extraEarningsDescription: "Project bonus",
            documentsDescription: "EU resident"
        )
        employees = [employeeAna, employeeJohn, employeeMaria]
        employees.forEach(saveEmployeeToCoreData)

        // Service types (default catalog)
        let standardCleaning = ServiceType(
            name: "Standard cleaning",
            description: "Regular home cleaning service",
            basePrice: 90,
            currency: .eur
        )
        let groceriesShopping = ServiceType(
            name: "Groceries shopping",
            description: "Shopping for groceries and supplies",
            basePrice: 40,
            currency: .eur
        )
        let lightbulbReplacement = ServiceType(
            name: "Lightbulb replacement",
            description: "Replace bulbs in the property",
            basePrice: 15,
            currency: .eur
        )
        let rugPurchase = ServiceType(
            name: "Rug purchase",
            description: "Select and purchase rugs for the home",
            basePrice: 120,
            currency: .eur
        )
        let laundryService = ServiceType(
            name: "Laundry",
            description: "Laundry service (per batch / pieces)",
            basePrice: 35,
            currency: .eur
        )

        serviceTypes = [
            standardCleaning,
            groceriesShopping,
            lightbulbReplacement,
            rugPurchase,
            laundryService
        ]
        serviceTypes.forEach(saveServiceTypeToCoreData)

        // Clients
        let clientCarla = Client(
            id: UUID(),
            name: "Carla Lima",
            contact: "Carla Lima",
            address: "Rua das Flores, 123, Lisbon",
            propertyDetails: "Apartment 302, 90m²",
            phone: "+351 912 000 001",
            whatsappPhone: "+351 912 000 001",
            email: "carla@example.com",
            accessNotes: "Call front desk on arrival",
            preferredSchedule: "Weekdays 8am–12pm",
            preferredDeliveryChannels: [.email, .whatsapp]
        )
        let clientJames = Client(
            id: UUID(),
            name: "James Walker",
            contact: "James Walker",
            address: "1200 Market St, San Francisco, CA",
            propertyDetails: "Townhouse, 3 bedrooms",
            phone: "+1 (415) 555-0100",
            whatsappPhone: "+1 (415) 555-0100",
            email: "james@example.com",
            accessNotes: "Ring the side doorbell",
            preferredSchedule: "Mon/Wed/Fri 2pm–6pm",
            preferredDeliveryChannels: [.email]
        )
        let clientLucia = Client(
            id: UUID(),
            name: "Lucía Fernández",
            contact: "Lucía Fernández",
            address: "Calle Mayor 45, Madrid",
            propertyDetails: "Flat, 2 bedrooms",
            phone: "+34 600 123 456",
            whatsappPhone: "+34 600 123 456",
            email: "lucia@example.com",
            accessNotes: "Entrance B, 4th floor",
            preferredSchedule: "Tuesday and Thursday mornings",
            preferredDeliveryChannels: [.sms, .email]
        )
        clients = [clientCarla, clientJames, clientLucia]
        clients.forEach(saveClientToCoreData)

        // Tasks for the next days and last week
        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let tasksDemo: [ServiceTask] = [
            ServiceTask(
                title: "Standard cleaning - Carla",
                date: makeDate(dayOffset: 0, hour: 9, minute: 0),
                startTime: makeDate(dayOffset: 0, hour: 9, minute: 0),
                endTime: makeDate(dayOffset: 0, hour: 11, minute: 0),
                status: .inProgress,
                assignedEmployee: employeeAna,
                clientName: clientCarla.name,
                address: clientCarla.address,
                notes: "Focus on kitchen and balcony.",
                serviceTypeId: standardCleaning.id,
                checkInTime: makeDate(dayOffset: 0, hour: 9, minute: 5),
                checkOutTime: nil
            ),
            ServiceTask(
                title: "Groceries - Lucía",
                date: makeDate(dayOffset: 1, hour: 14, minute: 0),
                startTime: makeDate(dayOffset: 1, hour: 14, minute: 0),
                endTime: makeDate(dayOffset: 1, hour: 18, minute: 0),
                status: .scheduled,
                assignedEmployee: employeeMaria,
                clientName: clientLucia.name,
                address: clientLucia.address,
                notes: "Weekly groceries shopping and restock.",
                serviceTypeId: groceriesShopping.id
            ),
            ServiceTask(
                title: "Lightbulb replacement - James",
                date: makeDate(dayOffset: 0, hour: 18, minute: 0),
                startTime: makeDate(dayOffset: 0, hour: 18, minute: 0),
                endTime: makeDate(dayOffset: 0, hour: 20, minute: 0),
                status: .scheduled,
                assignedEmployee: employeeJohn,
                clientName: clientJames.name,
                address: clientJames.address,
                notes: "Replace bulbs in hallway and kitchen.",
                serviceTypeId: lightbulbReplacement.id
            ),
            ServiceTask(
                title: "Rug purchase - Carla",
                date: makeDate(dayOffset: 2, hour: 10, minute: 30),
                startTime: makeDate(dayOffset: 2, hour: 10, minute: 30),
                endTime: makeDate(dayOffset: 2, hour: 12, minute: 0),
                status: .scheduled,
                assignedEmployee: employeeAna,
                clientName: clientCarla.name,
                address: clientCarla.address,
                notes: "Help choose new rugs for living room.",
                serviceTypeId: rugPurchase.id
            ),
            ServiceTask(
                title: "Standard cleaning - James",
                date: makeDate(dayOffset: -2, hour: 9, minute: 0),
                startTime: makeDate(dayOffset: -2, hour: 9, minute: 0),
                endTime: makeDate(dayOffset: -2, hour: 12, minute: 0),
                status: .completed,
                assignedEmployee: employeeJohn,
                clientName: clientJames.name,
                address: clientJames.address,
                notes: "Client requested focus on living room.",
                serviceTypeId: standardCleaning.id,
                checkInTime: makeDate(dayOffset: -2, hour: 9, minute: 5),
                checkOutTime: makeDate(dayOffset: -2, hour: 11, minute: 50)
            ),
            ServiceTask(
                title: "Laundry - Carla",
                date: makeDate(dayOffset: -5, hour: 13, minute: 0),
                startTime: makeDate(dayOffset: -5, hour: 13, minute: 0),
                endTime: makeDate(dayOffset: -5, hour: 17, minute: 0),
                status: .completed,
                assignedEmployee: employeeMaria,
                clientName: clientCarla.name,
                address: clientCarla.address,
                notes: "Laundry service for ~25 pieces.",
                serviceTypeId: laundryService.id,
                checkInTime: makeDate(dayOffset: -5, hour: 13, minute: 10),
                checkOutTime: makeDate(dayOffset: -5, hour: 16, minute: 45)
            ),
            ServiceTask(
                title: "Laundry pickup - Carla",
                date: makeDate(dayOffset: 0, hour: 12, minute: 30),
                startTime: makeDate(dayOffset: 0, hour: 12, minute: 30),
                endTime: makeDate(dayOffset: 0, hour: 13, minute: 30),
                status: .scheduled,
                assignedEmployee: employeeMaria,
                clientName: clientCarla.name,
                address: clientCarla.address,
                notes: "Pickup linens and drop off at cleaner.",
                serviceTypeId: laundryService.id
            ),
            ServiceTask(
                title: "Touch-up cleaning - James",
                date: makeDate(dayOffset: 0, hour: 15, minute: 0),
                startTime: makeDate(dayOffset: 0, hour: 15, minute: 0),
                endTime: makeDate(dayOffset: 0, hour: 17, minute: 0),
                status: .canceled,
                assignedEmployee: employeeJohn,
                clientName: clientJames.name,
                address: clientJames.address,
                notes: "Canceled by client (family visit postponed).",
                serviceTypeId: standardCleaning.id
            ),
            ServiceTask(
                title: "Standard cleaning - Lucía",
                date: makeDate(dayOffset: -1, hour: 10, minute: 0),
                startTime: makeDate(dayOffset: -1, hour: 10, minute: 0),
                endTime: makeDate(dayOffset: -1, hour: 13, minute: 0),
                status: .completed,
                assignedEmployee: employeeAna,
                clientName: clientLucia.name,
                address: clientLucia.address,
                notes: "Pre-event cleaning before guests arrive.",
                serviceTypeId: standardCleaning.id,
                checkInTime: makeDate(dayOffset: -1, hour: 10, minute: 5),
                checkOutTime: makeDate(dayOffset: -1, hour: 12, minute: 50)
            ),
            ServiceTask(
                title: "Rug follow-up - Carla",
                date: makeDate(dayOffset: 3, hour: 11, minute: 0),
                startTime: makeDate(dayOffset: 3, hour: 11, minute: 0),
                endTime: makeDate(dayOffset: 3, hour: 12, minute: 30),
                status: .scheduled,
                assignedEmployee: employeeAna,
                clientName: clientCarla.name,
                address: clientCarla.address,
                notes: "Deliver selected rugs and place in living room.",
                serviceTypeId: rugPurchase.id
            ),
            ServiceTask(
                title: "Groceries restock - James",
                date: makeDate(dayOffset: 2, hour: 16, minute: 0),
                startTime: makeDate(dayOffset: 2, hour: 16, minute: 0),
                endTime: makeDate(dayOffset: 2, hour: 18, minute: 0),
                status: .scheduled,
                assignedEmployee: employeeMaria,
                clientName: clientJames.name,
                address: clientJames.address,
                notes: "Restock pantry and beverages.",
                serviceTypeId: groceriesShopping.id
            ),
            ServiceTask(
                title: "Laundry - Lucía",
                date: makeDate(dayOffset: -4, hour: 8, minute: 0),
                startTime: makeDate(dayOffset: -4, hour: 8, minute: 0),
                endTime: makeDate(dayOffset: -4, hour: 11, minute: 0),
                status: .completed,
                assignedEmployee: employeeJohn,
                clientName: clientLucia.name,
                address: clientLucia.address,
                notes: "Seasonal linens and curtains.",
                serviceTypeId: laundryService.id,
                checkInTime: makeDate(dayOffset: -4, hour: 8, minute: 10),
                checkOutTime: makeDate(dayOffset: -4, hour: 10, minute: 45)
            )
        ]

        tasks = tasksDemo
        tasks.forEach(saveTaskToCoreData)

        // Finance entries (some created manually, others linked by service type)
        var financeEntries: [FinanceEntry] = []

        financeEntries.append(
            FinanceEntry(
                title: "Invoice - Standard cleaning Carla",
                amount: standardCleaning.basePrice,
                type: .receivable,
                dueDate: makeDate(dayOffset: 1, hour: 0, minute: 0),
                status: .pending,
                method: nil,
                currency: standardCleaning.currency,
                clientName: clientCarla.name,
                employeeName: employeeAna.name,
                kind: .invoiceClient
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Invoice - Groceries Lucía",
                amount: groceriesShopping.basePrice,
                type: .receivable,
                dueDate: makeDate(dayOffset: 3, hour: 0, minute: 0),
                status: .pending,
                method: nil,
                currency: groceriesShopping.currency,
                clientName: clientLucia.name,
                employeeName: employeeMaria.name,
                kind: .invoiceClient
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Invoice - Lightbulb replacement James",
                amount: lightbulbReplacement.basePrice,
                type: .receivable,
                dueDate: makeDate(dayOffset: 2, hour: 0, minute: 0),
                status: .pending,
                method: .card,
                currency: lightbulbReplacement.currency,
                clientName: clientJames.name,
                employeeName: employeeJohn.name,
                kind: .invoiceClient,
                isDisputed: true,
                disputeReason: "Client reported wrong quantity"
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Payroll - Ana Souza",
                amount: 600,
                type: .payable,
                dueDate: makeDate(dayOffset: 5, hour: 0, minute: 0),
                status: .pending,
                method: .pix,
                currency: .eur,
                clientName: nil,
                employeeName: employeeAna.name,
                kind: .payrollEmployee
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Payroll - John Miller",
                amount: 550,
                type: .payable,
                dueDate: makeDate(dayOffset: 5, hour: 0, minute: 0),
                status: .pending,
                method: .pix,
                currency: .usd,
                clientName: nil,
                employeeName: employeeJohn.name,
                kind: .payrollEmployee
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Payroll - Maria Garcia",
                amount: 650,
                type: .payable,
                dueDate: makeDate(dayOffset: 5, hour: 0, minute: 0),
                status: .pending,
                method: .pix,
                currency: .eur,
                clientName: nil,
                employeeName: employeeMaria.name,
                kind: .payrollEmployee
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Cleaning supplies - Month",
                amount: 450,
                type: .payable,
                dueDate: makeDate(dayOffset: 7, hour: 0, minute: 0),
                status: .pending,
                method: .card,
                currency: .usd,
                clientName: nil,
                employeeName: nil
            )
        )

        financeEntries.append(
            FinanceEntry(
                title: "Invoice - Laundry Carla",
                amount: laundryService.basePrice,
                type: .receivable,
                dueDate: makeDate(dayOffset: -2, hour: 0, minute: 0),
                status: .paid,
                method: .cash,
                currency: laundryService.currency,
                clientName: clientCarla.name,
                employeeName: employeeMaria.name,
                kind: .invoiceClient
            )
        )

        finance = financeEntries
        finance.forEach(saveFinanceEntryToCoreData)

        lastSync = Date()
        persist()
    }

    private func createAdditionalDemoData(usingExistingEmployee employee: Employee, existingClient client: Client) {
        // Apenas adiciona alguns serviços e lançamentos extras usando o funcionário/cliente já existentes.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let extraServiceType = ServiceType(
            name: "Extra visit",
            description: "Quick on-demand visit",
            basePrice: 60,
            currency: .eur
        )
        serviceTypes.append(extraServiceType)
        saveServiceTypeToCoreData(extraServiceType)

        let newTasks = [
            ServiceTask(
                title: "Extra visit - \(client.name)",
                date: makeDate(dayOffset: 1, hour: 8, minute: 0),
                startTime: makeDate(dayOffset: 1, hour: 8, minute: 0),
                endTime: makeDate(dayOffset: 1, hour: 9, minute: 30),
                status: .scheduled,
                assignedEmployee: employee,
                clientName: client.name,
                address: client.address,
                notes: "Quick kitchen check.",
                serviceTypeId: extraServiceType.id
            ),
            ServiceTask(
                title: "Follow-up cleaning - \(client.name)",
                date: makeDate(dayOffset: -1, hour: 15, minute: 0),
                startTime: makeDate(dayOffset: -1, hour: 15, minute: 0),
                endTime: makeDate(dayOffset: -1, hour: 17, minute: 0),
                status: .completed,
                assignedEmployee: employee,
                clientName: client.name,
                address: client.address,
                notes: "Second visit this week.",
                serviceTypeId: extraServiceType.id,
                checkInTime: makeDate(dayOffset: -1, hour: 15, minute: 10),
                checkOutTime: makeDate(dayOffset: -1, hour: 16, minute: 45)
            )
        ]

        tasks.append(contentsOf: newTasks)
        newTasks.forEach(saveTaskToCoreData)

        let extraFinance = [
            FinanceEntry(
                title: "Invoice - Extra visit \(client.name)",
                amount: extraServiceType.basePrice,
                type: .receivable,
                dueDate: makeDate(dayOffset: 2, hour: 0, minute: 0),
                status: .pending,
                method: nil,
                currency: extraServiceType.currency,
                clientName: client.name,
                employeeName: employee.name,
                kind: .invoiceClient
            )
        ]

        finance.append(contentsOf: extraFinance)
        extraFinance.forEach(saveFinanceEntryToCoreData)

        lastSync = Date()
        persist()
    }

    // MARK: - Core Data helpers

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }

    private func saveClientToCoreData(_ client: Client) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ClientEntity")
        request.predicate = NSPredicate(format: "id == %@", client.id as CVarArg)
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "ClientEntity", in: context) else { return }
            object = NSManagedObject(entity: entity, insertInto: context)
        }

        object.setValue(client.id, forKey: "id")
        object.setValue(client.name, forKey: "name")
        object.setValue(encryptString(client.contact), forKey: "contact")
        object.setValue(encryptString(client.address), forKey: "address")
        object.setValue(encryptString(client.propertyDetails), forKey: "propertyDetails")
        object.setValue(encryptString(client.phone), forKey: "phone")
        object.setValue(encryptString(client.whatsappPhone), forKey: "whatsappPhone")
        object.setValue(encryptString(client.email), forKey: "email")
        object.setValue(encryptString(client.accessNotes), forKey: "accessNotes")
        object.setValue(encryptString(client.preferredSchedule), forKey: "preferredSchedule")
        let channelsRaw = client.preferredDeliveryChannels.map { $0.rawValue }.joined(separator: ",")
        object.setValue(channelsRaw, forKey: "preferredChannels")

        saveContext()
    }

    private func saveTaskToCoreData(_ task: ServiceTask) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ServiceTaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "ServiceTaskEntity", in: context) else { return }
            object = NSManagedObject(entity: entity, insertInto: context)
        }

        object.setValue(task.id, forKey: "id")
        object.setValue(task.title, forKey: "title")
        object.setValue(task.date, forKey: "date")
        object.setValue(task.startTime, forKey: "startTime")
        object.setValue(task.endTime, forKey: "endTime")
        object.setValue(task.status.rawValue, forKey: "status")
        object.setValue(task.assignedEmployee.id, forKey: "employeeId")
        object.setValue(task.assignedEmployee.name, forKey: "employeeName")
        object.setValue(task.clientId, forKey: "clientId")
        object.setValue(task.clientName, forKey: "clientName")
        object.setValue(encryptString(task.notes), forKey: "notes")
        object.setValue(encryptString(task.address), forKey: "address")
        object.setValue(task.serviceTypeId, forKey: "serviceTypeId")
        object.setValue(task.checkInTime, forKey: "checkInTime")
        object.setValue(task.checkOutTime, forKey: "checkOutTime")

        saveContext()
    }

    private func saveFinanceEntryToCoreData(_ entry: FinanceEntry) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FinanceEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "FinanceEntryEntity", in: context) else { return }
            object = NSManagedObject(entity: entity, insertInto: context)
        }

        object.setValue(entry.id, forKey: "id")
        object.setValue(entry.title, forKey: "title")
        object.setValue(entry.amount, forKey: "amount")
        object.setValue(entry.currency.rawValue, forKey: "currency")
        object.setValue(entry.type.rawValue, forKey: "type")
        object.setValue(entry.dueDate, forKey: "dueDate")
        object.setValue(entry.status.rawValue, forKey: "status")
        object.setValue(entry.method?.rawValue, forKey: "method")
        object.setValue(entry.clientId, forKey: "clientId")
        object.setValue(entry.clientName, forKey: "clientName")
        object.setValue(entry.employeeId, forKey: "employeeId")
        object.setValue(entry.employeeName, forKey: "employeeName")
        object.setValue(entry.kind.rawValue, forKey: "kind")
        object.setValue(entry.isDisputed, forKey: "isDisputed")
        object.setValue(entry.disputeReason.map(encryptString), forKey: "disputeReason")
        object.setValue(encryptData(entry.receiptData), forKey: "receiptData")

        saveContext()
    }

    private func deleteFinanceEntryFromCoreData(_ id: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FinanceEntryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try? context.fetch(request).first {
            context.delete(object)
            saveContext()
        }
    }

    private func saveServiceTypeToCoreData(_ serviceType: ServiceType) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ServiceTypeEntity")
        request.predicate = NSPredicate(format: "id == %@", serviceType.id as CVarArg)
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "ServiceTypeEntity", in: context) else { return }
            object = NSManagedObject(entity: entity, insertInto: context)
        }

        object.setValue(serviceType.id, forKey: "id")
        object.setValue(serviceType.name, forKey: "name")
        object.setValue(serviceType.description, forKey: "serviceDescription")
        object.setValue(serviceType.basePrice, forKey: "basePrice")
        object.setValue(serviceType.currency.rawValue, forKey: "currency")

        saveContext()
    }

    private func deleteServiceTypeFromCoreData(_ id: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ServiceTypeEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try? context.fetch(request).first {
            context.delete(object)
            saveContext()
        }
    }

    private func saveEmployeeToCoreData(_ employee: Employee) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "EmployeeEntity")
        request.predicate = NSPredicate(format: "id == %@", employee.id as CVarArg)
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "EmployeeEntity", in: context) else { return }
            object = NSManagedObject(entity: entity, insertInto: context)
        }

        object.setValue(employee.id, forKey: "id")
        object.setValue(employee.name, forKey: "name")
        object.setValue(employee.role, forKey: "roleTitle")
        object.setValue(employee.team, forKey: "team")
        object.setValue(employee.hourlyRate, forKey: "hourlyRate")
        object.setValue(employee.phone.map(encryptString), forKey: "phone")
        object.setValue(employee.currency?.rawValue, forKey: "currency")
        object.setValue(employee.extraEarningsDescription.map(encryptString), forKey: "extraEarningsDescription")
        object.setValue(employee.documentsDescription.map(encryptString), forKey: "documentsDescription")

        saveContext()
    }

    private func deleteEmployeeFromCoreData(_ id: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "EmployeeEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try? context.fetch(request).first {
            context.delete(object)
            saveContext()
        }
    }

    private static func clientFromManagedObject(_ object: NSManagedObject) -> Client? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let name = object.value(forKey: "name") as? String,
            let contactRaw = object.value(forKey: "contact") as? String,
            let addressRaw = object.value(forKey: "address") as? String,
            let propertyRaw = object.value(forKey: "propertyDetails") as? String
        else { return nil }

        let contact = CryptoHelper.decryptString(contactRaw)
        let address = CryptoHelper.decryptString(addressRaw)
        let propertyDetails = CryptoHelper.decryptString(propertyRaw)
        let phone = CryptoHelper.decryptString(object.value(forKey: "phone") as? String ?? "")
        let whatsappPhone = CryptoHelper.decryptString(object.value(forKey: "whatsappPhone") as? String ?? "")
        let email = CryptoHelper.decryptString(object.value(forKey: "email") as? String ?? "")
        let accessNotes = CryptoHelper.decryptString(object.value(forKey: "accessNotes") as? String ?? "")
        let preferredSchedule = CryptoHelper.decryptString(object.value(forKey: "preferredSchedule") as? String ?? "")
        let preferredChannelsRaw = object.value(forKey: "preferredChannels") as? String
        let preferredChannels: [Client.DeliveryChannel]
        if let preferredChannelsRaw, !preferredChannelsRaw.isEmpty {
            preferredChannels = preferredChannelsRaw
                .split(separator: ",")
                .compactMap { Client.DeliveryChannel.from(rawValue: String($0)) }
        } else {
            preferredChannels = [.email]
        }

        return Client(
            id: id,
            name: name,
            contact: contact,
            address: address,
            propertyDetails: propertyDetails,
            phone: phone,
            whatsappPhone: whatsappPhone,
            email: email,
            accessNotes: accessNotes,
            preferredSchedule: preferredSchedule,
            preferredDeliveryChannels: preferredChannels
        )
    }

    private func taskFromManagedObject(_ object: NSManagedObject) -> ServiceTask? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let title = object.value(forKey: "title") as? String,
            let date = object.value(forKey: "date") as? Date,
            let statusRaw = object.value(forKey: "status") as? String,
            let status = ServiceTask.Status(rawValue: statusRaw)
        else { return nil }

        let startTime = object.value(forKey: "startTime") as? Date
        let endTime = object.value(forKey: "endTime") as? Date
        let notes = decryptString(object.value(forKey: "notes") as? String ?? "")
        let address = decryptString(object.value(forKey: "address") as? String ?? "")
        let serviceTypeId = object.value(forKey: "serviceTypeId") as? UUID
        let checkIn = object.value(forKey: "checkInTime") as? Date
        let checkOut = object.value(forKey: "checkOutTime") as? Date

        let employeeId = object.value(forKey: "employeeId") as? UUID
        let employeeName = object.value(forKey: "employeeName") as? String ?? "Unassigned"
        let clientId = object.value(forKey: "clientId") as? UUID
        let clientNameStored = object.value(forKey: "clientName") as? String ?? ""

        let resolvedEmployee = employees.first { employee in
            if let employeeId {
                return employee.id == employeeId
            }
            return employee.name == employeeName
        } ?? Employee(
            id: employeeId ?? UUID(),
            name: employeeName,
            role: "",
            team: "",
            phone: nil,
            hourlyRate: nil,
            currency: nil,
            extraEarningsDescription: nil,
            documentsDescription: nil
        )

        let resolvedClient = clients.first { client in
            if let clientId {
                return client.id == clientId
            }
            if !clientNameStored.isEmpty {
                return client.name == clientNameStored
            }
            return client.address == address
        }

        return ServiceTask(
            id: id,
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            status: status,
            assignedEmployee: resolvedEmployee,
            clientId: resolvedClient?.id ?? clientId,
            clientName: resolvedClient?.name ?? clientNameStored,
            address: address,
            notes: notes,
            serviceTypeId: serviceTypeId,
            checkInTime: checkIn,
            checkOutTime: checkOut
        )
    }

    private static func employeeFromManagedObject(_ object: NSManagedObject) -> Employee? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let name = object.value(forKey: "name") as? String
        else { return nil }

        let roleTitle = object.value(forKey: "roleTitle") as? String ?? ""
        let team = object.value(forKey: "team") as? String ?? ""
        let hourlyRate = object.value(forKey: "hourlyRate") as? Double
        let phone = (object.value(forKey: "phone") as? String).map { CryptoHelper.decryptString($0) }
        let currencyRaw = object.value(forKey: "currency") as? String
        let currency = currencyRaw.flatMap { Employee.Currency(rawValue: $0) }
        let extra = (object.value(forKey: "extraEarningsDescription") as? String).map { CryptoHelper.decryptString($0) }
        let documents = (object.value(forKey: "documentsDescription") as? String).map { CryptoHelper.decryptString($0) }

        return Employee(
            id: id,
            name: name,
            role: roleTitle,
            team: team,
            phone: phone,
            hourlyRate: hourlyRate,
            currency: currency,
            extraEarningsDescription: extra,
            documentsDescription: documents
        )
    }

    private static func serviceTypeFromManagedObject(_ object: NSManagedObject) -> ServiceType? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let name = object.value(forKey: "name") as? String,
            let basePrice = object.value(forKey: "basePrice") as? Double,
            let currencyRaw = object.value(forKey: "currency") as? String,
            let currency = FinanceEntry.Currency(rawValue: currencyRaw)
        else { return nil }

        let description = object.value(forKey: "serviceDescription") as? String ?? ""

        return ServiceType(
            id: id,
            name: name,
            description: description,
            basePrice: basePrice,
            currency: currency
        )
    }

    private func financeFromManagedObject(_ object: NSManagedObject) -> FinanceEntry? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let title = object.value(forKey: "title") as? String,
            let amount = object.value(forKey: "amount") as? Double,
            let typeRaw = object.value(forKey: "type") as? String,
            let type = FinanceEntry.EntryType(rawValue: typeRaw),
            let dueDate = object.value(forKey: "dueDate") as? Date
        else { return nil }

        let statusRaw = (object.value(forKey: "status") as? String) ?? FinanceEntry.Status.pending.rawValue
        let status = FinanceEntry.Status(rawValue: statusRaw) ?? .pending

        let methodRaw = object.value(forKey: "method") as? String
        let method = methodRaw.flatMap { FinanceEntry.PaymentMethod(rawValue: $0) }

        let currencyRaw = object.value(forKey: "currency") as? String
        let currency = currencyRaw.flatMap { FinanceEntry.Currency(rawValue: $0) } ?? .usd
        let clientId = object.value(forKey: "clientId") as? UUID
        let clientName = object.value(forKey: "clientName") as? String
        let employeeId = object.value(forKey: "employeeId") as? UUID
        let employeeName = object.value(forKey: "employeeName") as? String
        let kindRaw = object.value(forKey: "kind") as? String
        let kind = kindRaw.flatMap { FinanceEntry.Kind(rawValue: $0) } ?? .general
        let isDisputed = object.value(forKey: "isDisputed") as? Bool ?? false
        let disputeReason = (object.value(forKey: "disputeReason") as? String).map { CryptoHelper.decryptString($0) }
        let receiptData = CryptoHelper.decryptData(object.value(forKey: "receiptData") as? Data)

        let resolvedClientName: String? = {
            if let clientName, !clientName.isEmpty { return clientName }
            if let clientId {
                return clients.first(where: { $0.id == clientId })?.name
            }
            return nil
        }()
        let resolvedEmployeeName: String? = {
            if let employeeName, !employeeName.isEmpty { return employeeName }
            if let employeeId {
                return employees.first(where: { $0.id == employeeId })?.name
            }
            return nil
        }()

        return FinanceEntry(
            id: id,
            title: title,
            amount: amount,
            type: type,
            dueDate: dueDate,
            status: status,
            method: method,
            currency: currency,
            clientId: clientId,
            clientName: resolvedClientName,
            employeeId: employeeId,
            employeeName: resolvedEmployeeName,
            kind: kind,
            isDisputed: isDisputed,
            disputeReason: disputeReason,
            receiptData: receiptData
        )
    }
}

struct PendingChange: Codable, Identifiable {
    enum Operation: String, Codable {
        case addClient
        case addEmployee
        case updateEmployee
        case deleteEmployee
        case addTask
        case updateTask
        case addFinanceEntry
        case markFinanceEntry
        case updateFinanceEntry
        case deleteFinanceEntry
        case addServiceType
        case updateServiceType
        case deleteServiceType
    }

    var id: UUID
    var operation: Operation
    var entityId: UUID
    var timestamp: Date

    init(operation: Operation, entityId: UUID, timestamp: Date = Date()) {
        self.id = UUID()
        self.operation = operation
        self.entityId = entityId
        self.timestamp = timestamp
    }
}

struct NotificationPreferences: Codable {
    var enableClientNotifications: Bool
    var enableTeamNotifications: Bool
    var enablePush: Bool
    var enableSiri: Bool

    init(
        enableClientNotifications: Bool = true,
        enableTeamNotifications: Bool = true,
        enablePush: Bool = true,
        enableSiri: Bool = false
    ) {
        self.enableClientNotifications = enableClientNotifications
        self.enableTeamNotifications = enableTeamNotifications
        self.enablePush = enablePush
        self.enableSiri = enableSiri
    }
}

struct ConflictLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let entity: String
    let field: String
    let summary: String
    let timestamp: Date

    init(id: UUID = UUID(), entity: String, field: String, summary: String, timestamp: Date = Date()) {
        self.id = id
        self.entity = entity
        self.field = field
        self.summary = summary
        self.timestamp = timestamp
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case enUS = "en-US"
    case esES = "es-ES"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .enUS: return NSLocalizedString("English (US)", comment: "")
        case .esES: return NSLocalizedString("Spanish (ES)", comment: "")
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

struct AppPreferences: Codable {
    var language: AppLanguage
    var preferredCurrency: FinanceEntry.Currency
    var disputeWindowDays: Int
    var enableWhatsApp: Bool
    var enableTextMessages: Bool
    var enableEmail: Bool

    init(
        language: AppLanguage = .enUS,
        preferredCurrency: FinanceEntry.Currency = .usd,
        disputeWindowDays: Int = 0,
        enableWhatsApp: Bool = true,
        enableTextMessages: Bool = true,
        enableEmail: Bool = true
    ) {
        self.language = language
        self.preferredCurrency = preferredCurrency
        self.disputeWindowDays = disputeWindowDays
        self.enableWhatsApp = enableWhatsApp
        self.enableTextMessages = enableTextMessages
        self.enableEmail = enableEmail
    }

    enum CodingKeys: String, CodingKey {
        case language
        case preferredCurrency
        case disputeWindowDays
        case enableWhatsApp
        case enableTextMessages
        case enableEmail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .enUS
        preferredCurrency = try container.decodeIfPresent(FinanceEntry.Currency.self, forKey: .preferredCurrency) ?? .usd
        disputeWindowDays = try container.decodeIfPresent(Int.self, forKey: .disputeWindowDays) ?? 0
        enableWhatsApp = try container.decodeIfPresent(Bool.self, forKey: .enableWhatsApp) ?? true
        enableTextMessages = try container.decodeIfPresent(Bool.self, forKey: .enableTextMessages) ?? true
        enableEmail = try container.decodeIfPresent(Bool.self, forKey: .enableEmail) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(preferredCurrency, forKey: .preferredCurrency)
        try container.encode(disputeWindowDays, forKey: .disputeWindowDays)
        try container.encode(enableWhatsApp, forKey: .enableWhatsApp)
        try container.encode(enableTextMessages, forKey: .enableTextMessages)
        try container.encode(enableEmail, forKey: .enableEmail)
    }
}

private struct Snapshot: Codable {
    var clients: [Client]
    var employees: [Employee]
    var tasks: [ServiceTask]
    var finance: [FinanceEntry]
    var session: UserSession?
    var lastSync: Date?
    var pendingChanges: [PendingChange]
    var notificationPreferences: NotificationPreferences
    var appPreferences: AppPreferences
    var conflictLog: [ConflictLogEntry]

    enum CodingKeys: String, CodingKey {
        case clients
        case employees
        case tasks
        case finance
        case session
        case lastSync
        case pendingChanges
        case notificationPreferences
        case appPreferences
        case conflictLog
    }

    init(
        clients: [Client],
        employees: [Employee],
        tasks: [ServiceTask],
        finance: [FinanceEntry],
        session: UserSession?,
        lastSync: Date?,
        pendingChanges: [PendingChange],
        notificationPreferences: NotificationPreferences,
        appPreferences: AppPreferences,
        conflictLog: [ConflictLogEntry]
    ) {
        self.clients = clients
        self.employees = employees
        self.tasks = tasks
        self.finance = finance
        self.session = session
        self.lastSync = lastSync
        self.pendingChanges = pendingChanges
        self.notificationPreferences = notificationPreferences
        self.appPreferences = appPreferences
        self.conflictLog = conflictLog
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clients = try container.decode([Client].self, forKey: .clients)
        employees = try container.decode([Employee].self, forKey: .employees)
        tasks = try container.decode([ServiceTask].self, forKey: .tasks)
        finance = try container.decode([FinanceEntry].self, forKey: .finance)
        session = try container.decodeIfPresent(UserSession.self, forKey: .session)
        lastSync = try container.decodeIfPresent(Date.self, forKey: .lastSync)
        pendingChanges = try container.decodeIfPresent([PendingChange].self, forKey: .pendingChanges) ?? []
        notificationPreferences = try container.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) ?? NotificationPreferences()
        appPreferences = try container.decodeIfPresent(AppPreferences.self, forKey: .appPreferences) ?? AppPreferences()
        conflictLog = try container.decodeIfPresent([ConflictLogEntry].self, forKey: .conflictLog) ?? []
    }
}
