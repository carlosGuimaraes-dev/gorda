import Foundation
import SwiftUI
import UserNotifications
import CoreData

@MainActor
final class OfflineStore: ObservableObject {
    @Published private(set) var clients: [Client] = []
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var tasks: [ServiceTask] = []
    @Published private(set) var finance: [FinanceEntry] = []
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
        persist()
    }

    func logout() {
        session = nil
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
        status: ServiceTask.Status = .scheduled
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
            notes: notes
        )
        tasks.append(task)
        pendingChanges.append(PendingChange(operation: .addTask, entityId: task.id))
        saveTaskToCoreData(task)
        persist()
    }

    func updateTask(
        _ task: ServiceTask,
        status: ServiceTask.Status,
        startTime: Date? = nil,
        endTime: Date? = nil,
        notes: String? = nil
    ) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
        tasks[index].startTime = startTime ?? tasks[index].startTime
        tasks[index].endTime = endTime ?? tasks[index].endTime
        tasks[index].notes = notes ?? tasks[index].notes
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
        preferredSchedule: String
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
            preferredSchedule: preferredSchedule
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
        method: FinanceEntry.PaymentMethod? = nil
    ) {
        let entry = FinanceEntry(title: title, amount: amount, type: type, dueDate: dueDate, method: method)
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

    private func persist() {
        do {
            let snapshot = Snapshot(
                clients: clients,
                employees: employees,
                tasks: tasks,
                finance: finance,
                session: session,
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
        let requestTasks = NSFetchRequest<NSManagedObject>(entityName: "ServiceTaskEntity")
        let requestFinance = NSFetchRequest<NSManagedObject>(entityName: "FinanceEntryEntity")

        do {
            let clientObjects = try context.fetch(requestClients)
            let taskObjects = try context.fetch(requestTasks)
            let financeObjects = try context.fetch(requestFinance)

            if !clientObjects.isEmpty || !taskObjects.isEmpty || !financeObjects.isEmpty {
                self.clients = clientObjects.compactMap(Self.clientFromManagedObject)
                self.tasks = taskObjects.compactMap(Self.taskFromManagedObject)
                self.finance = financeObjects.compactMap(Self.financeFromManagedObject)
                return
            }
        } catch {
            // Se der erro, tenta fallback em JSON.
        }

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

    private func seedDemoDataIfNeeded() {
        guard clients.isEmpty, employees.isEmpty else { return }
        let employee = Employee(id: UUID(), name: "Ana Souza", role: "Supervisora", team: "Equipe A")
        employees = [employee]
        let client = Client(
            id: UUID(),
            name: "Carla Lima",
            contact: "Contato principal: Carla",
            address: "Rua das Flores, 123",
            propertyDetails: "Apartamento 302, 90m²",
            phone: "+55 11 99999-1000",
            email: "carla@example.com",
            accessNotes: "Avisar portaria e solicitar vaga de visitante",
            preferredSchedule: "Seg–Sex 8h-12h"
        )
        clients = [client]
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
        let end = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
        let task = ServiceTask(
            title: "Limpeza pós-evento",
            date: Date(),
            startTime: start,
            endTime: end,
            status: .scheduled,
            assignedEmployee: employee,
            clientName: client.name,
            address: client.address,
            notes: "Levar materiais de piso vinílico"
        )
        tasks = [task]
        let entry = FinanceEntry(
            title: "Pagamento equipe A",
            amount: 1200,
            type: .payable,
            dueDate: Date(),
            status: .pending,
            method: .pix
        )
        finance = [entry]
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
        object.setValue("USD", forKey: "currency") // placeholder até multi-moeda completo
        object.setValue(entry.type.rawValue, forKey: "type")
        object.setValue(entry.dueDate, forKey: "dueDate")
        object.setValue(entry.status.rawValue, forKey: "status")
        object.setValue(entry.method?.rawValue, forKey: "method")

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

        return Client(
            id: id,
            name: name,
            contact: contact,
            address: address,
            propertyDetails: propertyDetails,
            phone: phone,
            email: email,
            accessNotes: accessNotes,
            preferredSchedule: preferredSchedule
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

        let dummyEmployee = Employee(id: UUID(), name: "Unassigned", role: "", team: "")

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
            notes: notes
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

        return FinanceEntry(id: id, title: title, amount: amount, type: type, dueDate: dueDate, status: status, method: method)
    }
}

private struct PendingChange: Codable, Identifiable {
    enum Operation: String, Codable {
        case addClient
        case addTask
        case updateTask
        case addFinanceEntry
        case markFinanceEntry
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
