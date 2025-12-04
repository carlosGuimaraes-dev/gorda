import Foundation

struct Client: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var contact: String
    var address: String
    var propertyDetails: String
    var phone: String
    var email: String
    var accessNotes: String
    var preferredSchedule: String

    init(
        id: UUID = UUID(),
        name: String,
        contact: String,
        address: String,
        propertyDetails: String,
        phone: String = "",
        email: String = "",
        accessNotes: String = "",
        preferredSchedule: String = ""
    ) {
        self.id = id
        self.name = name
        self.contact = contact
        self.address = address
        self.propertyDetails = propertyDetails
        self.phone = phone
        self.email = email
        self.accessNotes = accessNotes
        self.preferredSchedule = preferredSchedule
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contact
        case address
        case propertyDetails
        case phone
        case email
        case accessNotes
        case preferredSchedule
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.contact = try container.decode(String.self, forKey: .contact)
        self.address = try container.decode(String.self, forKey: .address)
        self.propertyDetails = try container.decode(String.self, forKey: .propertyDetails)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.accessNotes = try container.decodeIfPresent(String.self, forKey: .accessNotes) ?? ""
        self.preferredSchedule = try container.decodeIfPresent(String.self, forKey: .preferredSchedule) ?? ""
    }
}

struct Employee: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var team: String
}

struct ServiceTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var status: Status
    var assignedEmployee: Employee
    var clientName: String
    var address: String
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        status: Status,
        assignedEmployee: Employee,
        clientName: String,
        address: String,
        notes: String
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.assignedEmployee = assignedEmployee
        self.clientName = clientName
        self.address = address
        self.notes = notes
    }

    enum Status: String, Codable, CaseIterable, Identifiable {
        case scheduled
        case inProgress
        case completed
        case canceled

        var id: String { rawValue }
        var label: String {
            switch self {
            case .scheduled: return "Agendado"
            case .inProgress: return "Em andamento"
            case .completed: return "Concluído"
            case .canceled: return "Cancelado"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case startTime
        case endTime
        case status
        case assignedEmployee
        case clientName
        case address
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.date = try container.decode(Date.self, forKey: .date)
        self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .scheduled
        self.assignedEmployee = try container.decode(Employee.self, forKey: .assignedEmployee)
        self.clientName = try container.decodeIfPresent(String.self, forKey: .clientName) ?? ""
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct FinanceEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var type: EntryType
    var dueDate: Date
    var status: Status
    var method: PaymentMethod?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: EntryType,
        dueDate: Date,
        status: Status = .pending,
        method: PaymentMethod? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.dueDate = dueDate
        self.status = status
        self.method = method
    }

    enum EntryType: String, Codable {
        case payable
        case receivable
    }

    enum Status: String, Codable {
        case pending
        case paid

        var label: String {
            switch self {
            case .pending: return "Pendente"
            case .paid: return "Pago"
            }
        }
    }

    enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
        case pix
        case card
        case cash

        var id: String { rawValue }
        var label: String {
            switch self {
            case .pix: return "Pix"
            case .card: return "Cartão"
            case .cash: return "Dinheiro"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case type
        case dueDate
        case status
        case method
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.type = try container.decode(EntryType.self, forKey: .type)
        self.dueDate = try container.decode(Date.self, forKey: .dueDate)
        self.status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .pending
        self.method = try container.decodeIfPresent(PaymentMethod.self, forKey: .method)
    }
}

struct UserSession: Codable {
    var token: String
    var name: String
}
