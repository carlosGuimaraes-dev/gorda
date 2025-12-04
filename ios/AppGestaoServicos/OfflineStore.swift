import Foundation
import SwiftUI

@MainActor
final class OfflineStore: ObservableObject {
    @Published private(set) var clients: [Client] = []
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var tasks: [ServiceTask] = []
    @Published private(set) var finance: [FinanceEntry] = []
    @Published var session: UserSession?
    @Published var lastSync: Date?

    private let persistenceURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("offline_data.json")
    }()

    init() {
        load()
        seedDemoDataIfNeeded()
    }

    func login(user: String, password: String) {
        guard !user.isEmpty, !password.isEmpty else { return }
        session = UserSession(token: UUID().uuidString, name: user)
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
        persist()
    }

    func markFinanceEntry(_ entry: FinanceEntry, status: FinanceEntry.Status, method: FinanceEntry.PaymentMethod?) {
        guard let index = finance.firstIndex(where: { $0.id == entry.id }) else { return }
        finance[index].status = status
        finance[index].method = method
        persist()
    }

    func syncPendingChanges() {
        // Ponto para integrar com backend; aqui apenas registra timestamp local.
        lastSync = Date()
        persist()
    }

    private func persist() {
        do {
            let snapshot = Snapshot(
                clients: clients,
                employees: employees,
                tasks: tasks,
                finance: finance,
                session: session,
                lastSync: lastSync
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Falha ao persistir: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            self.clients = snapshot.clients
            self.employees = snapshot.employees
            self.tasks = snapshot.tasks
            self.finance = snapshot.finance
            self.session = snapshot.session
            self.lastSync = snapshot.lastSync
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
}

private struct Snapshot: Codable {
    var clients: [Client]
    var employees: [Employee]
    var tasks: [ServiceTask]
    var finance: [FinanceEntry]
    var session: UserSession?
    var lastSync: Date?
}
