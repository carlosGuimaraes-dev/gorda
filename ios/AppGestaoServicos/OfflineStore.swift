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
    @Published var notificationPreferences = NotificationPreferences()
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
            clientName: clientName,
            address: address,
            notes: notes,
            serviceTypeId: serviceTypeId
        )
        tasks.append(task)
        pendingChanges.append(PendingChange(operation: .addTask, entityId: task.id))
        saveTaskToCoreData(task)

        if let typeId = serviceTypeId, let serviceType = serviceTypes.first(where: { $0.id == typeId }) {
            let financeEntry = FinanceEntry(
                title: serviceType.name,
                amount: serviceType.basePrice,
                type: .receivable,
                dueDate: date,
                status: .pending,
                method: nil,
                currency: serviceType.currency,
                clientName: clientName,
                employeeName: employee.name,
                kind: .invoiceClient
            )
            finance.append(financeEntry)
            pendingChanges.append(PendingChange(operation: .addFinanceEntry, entityId: financeEntry.id))
            saveFinanceEntryToCoreData(financeEntry)
        }
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
        email: String,
        accessNotes: String,
        preferredSchedule: String,
        preferredDeliveryChannels: [Client.DeliveryChannel]
    ) {
        let client = Client(
            id: UUID(),
            name: name,
            contact: contact,
            address: address,
            propertyDetails: propertyDetails,
            phone: phone,
            email: email,
            accessNotes: accessNotes,
            preferredSchedule: preferredSchedule,
            preferredDeliveryChannels: preferredDeliveryChannels
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
        clientName: String? = nil,
        employeeName: String? = nil,
        kind: FinanceEntry.Kind = .general,
        receiptData: Data? = nil,
        isDisputed: Bool = false,
        disputeReason: String? = nil
    ) {
        let entry = FinanceEntry(
            title: title,
            amount: amount,
            type: type,
            dueDate: dueDate,
            status: .pending,
            method: method,
            currency: currency,
            clientName: clientName,
            employeeName: employeeName,
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
        pendingChanges.append(PendingChange(operation: .updateFinanceEntry, entityId: entry.id))
        saveFinanceEntryToCoreData(finance[index])
        persist()
    }

    func markInvoiceDisputed(_ entry: FinanceEntry, reason: String?) {
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
        let calendar = Calendar.current

        let relevantTasks = tasks.filter { task in
            guard task.status != .canceled else { return false }
            guard calendar.isDate(task.date, inSameDayAs: task.date) else { return false }
            return (task.date >= startDate && task.date <= endDate)
        }

        let groupedByClient = Dictionary(grouping: relevantTasks) { $0.clientName }
        let targetClientNames: [String]
        if let specific = clientName {
            targetClientNames = [specific]
        } else {
            targetClientNames = Array(groupedByClient.keys)
        }

        for name in targetClientNames {
            guard let clientTasks = groupedByClient[name], !clientTasks.isEmpty else { continue }

            var total: Double = 0
            var currency: FinanceEntry.Currency = .eur

            for task in clientTasks {
                guard let typeId = task.serviceTypeId,
                      let serviceType = serviceTypes.first(where: { $0.id == typeId }) else { continue }
                total += serviceType.basePrice
                currency = serviceType.currency
            }

            guard total > 0 else { continue }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let periodLabel = formatter.string(from: startDate)

            let title = "Invoice \(name) \(periodLabel)"

            let entry = FinanceEntry(
                title: title,
                amount: total,
                type: .receivable,
                dueDate: dueDate,
                status: .pending,
                method: nil,
                currency: currency,
                clientName: name,
                employeeName: nil,
                kind: .invoiceClient
            )
            finance.append(entry)
            pendingChanges.append(PendingChange(operation: .addFinanceEntry, entityId: entry.id))
            saveFinanceEntryToCoreData(entry)
        }

        persist()
    }

    func generatePayrolls(from startDate: Date, to endDate: Date, dueDate: Date, employeeName: String? = nil) {
        let calendar = Calendar.current

        let targetEmployees: [Employee]
        if let specific = employeeName {
            targetEmployees = employees.filter { $0.name == specific }
        } else {
            targetEmployees = employees
        }

        for employee in targetEmployees {
            guard let rate = employee.hourlyRate, let currency = employee.currency else { continue }

            let employeeTasks = tasks.filter { task in
                task.assignedEmployee.name == employee.name &&
                task.date >= startDate && task.date <= endDate &&
                task.checkInTime != nil && task.checkOutTime != nil
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
                currency: currency,
                clientName: nil,
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
        let employee = Employee(
            id: UUID(),
            name: name,
            role: roleTitle,
            team: team,
            phone: phone,
            hourlyRate: hourlyRate,
            currency: currency,
            extraEarningsDescription: extraEarningsDescription,
            documentsDescription: documentsDescription
        )
        employees.append(employee)
        pendingChanges.append(PendingChange(operation: .addClient, entityId: employee.id))
        saveEmployeeToCoreData(employee)
        persist()
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
        activity.title = "Create service"
        activity.userInfo = [
            "title": task.title,
            "clientName": task.clientName
        ]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Create service for \(task.clientName)"
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
                notificationPreferences: notificationPreferences
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: persistenceURL, options: .atomic)
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
                self.tasks = taskObjects.compactMap(Self.taskFromManagedObject)
                self.finance = financeObjects.compactMap(Self.financeFromManagedObject)
            }
        } catch {
            // Se der erro, tenta fallback em JSON.
        }

        if clients.isEmpty && employees.isEmpty && tasks.isEmpty && finance.isEmpty {
            // Fallback para snapshot antigo, se Core Data estiver vazio.
            do {
                let data = try Data(contentsOf: persistenceURL)
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
                self.clients = snapshot.clients
                self.employees = snapshot.employees
                self.tasks = snapshot.tasks
                self.finance = snapshot.finance
                self.session = snapshot.session
                self.lastSync = snapshot.lastSync
                self.pendingChanges = snapshot.pendingChanges
                self.notificationPreferences = snapshot.notificationPreferences
            } catch {
                // Primeiro uso ou dados indisponíveis; segue vazio.
            }
        }

        if let secureSession = KeychainHelper.loadSession() {
            self.session = secureSession
        }
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
            email: "lucia@example.com",
            accessNotes: "Entrance B, 4th floor",
            preferredSchedule: "Tuesday and Thursday mornings",
            preferredDeliveryChannels: [.imessage, .email]
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
        object.setValue(client.contact, forKey: "contact")
        object.setValue(client.address, forKey: "address")
        object.setValue(client.propertyDetails, forKey: "propertyDetails")
        object.setValue(client.phone, forKey: "phone")
        object.setValue(client.email, forKey: "email")
        object.setValue(client.accessNotes, forKey: "accessNotes")
        object.setValue(client.preferredSchedule, forKey: "preferredSchedule")
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
        object.setValue(task.notes, forKey: "notes")
        object.setValue(task.address, forKey: "address")
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
        object.setValue(entry.clientName, forKey: "clientName")
        object.setValue(entry.employeeName, forKey: "employeeName")
        object.setValue(entry.kind.rawValue, forKey: "kind")
        object.setValue(entry.isDisputed, forKey: "isDisputed")
        object.setValue(entry.disputeReason, forKey: "disputeReason")
        object.setValue(entry.receiptData, forKey: "receiptData")

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
        object.setValue(employee.phone, forKey: "phone")
        object.setValue(employee.currency?.rawValue, forKey: "currency")
        object.setValue(employee.extraEarningsDescription, forKey: "extraEarningsDescription")
        object.setValue(employee.documentsDescription, forKey: "documentsDescription")

        saveContext()
    }

    private static func clientFromManagedObject(_ object: NSManagedObject) -> Client? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let name = object.value(forKey: "name") as? String,
            let contact = object.value(forKey: "contact") as? String,
            let address = object.value(forKey: "address") as? String,
            let propertyDetails = object.value(forKey: "propertyDetails") as? String
        else { return nil }

        let phone = object.value(forKey: "phone") as? String ?? ""
        let email = object.value(forKey: "email") as? String ?? ""
        let accessNotes = object.value(forKey: "accessNotes") as? String ?? ""
        let preferredSchedule = object.value(forKey: "preferredSchedule") as? String ?? ""
        let preferredChannelsRaw = object.value(forKey: "preferredChannels") as? String
        let preferredChannels: [Client.DeliveryChannel]
        if let preferredChannelsRaw, !preferredChannelsRaw.isEmpty {
            preferredChannels = preferredChannelsRaw
                .split(separator: ",")
                .compactMap { Client.DeliveryChannel(rawValue: String($0)) }
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
            email: email,
            accessNotes: accessNotes,
            preferredSchedule: preferredSchedule,
            preferredDeliveryChannels: preferredChannels
        )
    }

    private static func taskFromManagedObject(_ object: NSManagedObject) -> ServiceTask? {
        guard
            let id = object.value(forKey: "id") as? UUID,
            let title = object.value(forKey: "title") as? String,
            let date = object.value(forKey: "date") as? Date,
            let statusRaw = object.value(forKey: "status") as? String,
            let status = ServiceTask.Status(rawValue: statusRaw)
        else { return nil }

        let startTime = object.value(forKey: "startTime") as? Date
        let endTime = object.value(forKey: "endTime") as? Date
        let notes = object.value(forKey: "notes") as? String ?? ""
        let address = object.value(forKey: "address") as? String ?? ""
        let serviceTypeId = object.value(forKey: "serviceTypeId") as? UUID
        let checkIn = object.value(forKey: "checkInTime") as? Date
        let checkOut = object.value(forKey: "checkOutTime") as? Date

        let dummyEmployee = Employee(id: UUID(), name: "Unassigned", role: "", team: "", phone: nil, hourlyRate: nil, currency: nil, extraEarningsDescription: nil, documentsDescription: nil)

        return ServiceTask(
            id: id,
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            status: status,
            assignedEmployee: dummyEmployee,
            clientName: "",
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
        let phone = object.value(forKey: "phone") as? String
        let currencyRaw = object.value(forKey: "currency") as? String
        let currency = currencyRaw.flatMap { Employee.Currency(rawValue: $0) }
        let extra = object.value(forKey: "extraEarningsDescription") as? String
        let documents = object.value(forKey: "documentsDescription") as? String

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

    private static func financeFromManagedObject(_ object: NSManagedObject) -> FinanceEntry? {
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
        let clientName = object.value(forKey: "clientName") as? String
        let employeeName = object.value(forKey: "employeeName") as? String
        let kindRaw = object.value(forKey: "kind") as? String
        let kind = kindRaw.flatMap { FinanceEntry.Kind(rawValue: $0) } ?? .general
        let isDisputed = object.value(forKey: "isDisputed") as? Bool ?? false
        let disputeReason = object.value(forKey: "disputeReason") as? String
        let receiptData = object.value(forKey: "receiptData") as? Data

        return FinanceEntry(
            id: id,
            title: title,
            amount: amount,
            type: type,
            dueDate: dueDate,
            status: status,
            method: method,
            currency: currency,
            clientName: clientName,
            employeeName: employeeName,
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
        case addTask
        case updateTask
        case addFinanceEntry
        case markFinanceEntry
        case updateFinanceEntry
        case deleteFinanceEntry
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

private struct Snapshot: Codable {
    var clients: [Client]
    var employees: [Employee]
    var tasks: [ServiceTask]
    var finance: [FinanceEntry]
    var session: UserSession?
    var lastSync: Date?
    var pendingChanges: [PendingChange]
    var notificationPreferences: NotificationPreferences

    enum CodingKeys: String, CodingKey {
        case clients
        case employees
        case tasks
        case finance
        case session
        case lastSync
        case pendingChanges
        case notificationPreferences
    }

    init(
        clients: [Client],
        employees: [Employee],
        tasks: [ServiceTask],
        finance: [FinanceEntry],
        session: UserSession?,
        lastSync: Date?,
        pendingChanges: [PendingChange],
        notificationPreferences: NotificationPreferences
    ) {
        self.clients = clients
        self.employees = employees
        self.tasks = tasks
        self.finance = finance
        self.session = session
        self.lastSync = lastSync
        self.pendingChanges = pendingChanges
        self.notificationPreferences = notificationPreferences
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
    }
}
