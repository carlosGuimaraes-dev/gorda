import Foundation

struct Client: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var contact: String
    var address: String
    var propertyDetails: String
    var phone: String
    var whatsappPhone: String
    var email: String
    var accessNotes: String
    var preferredSchedule: String
    var preferredDeliveryChannels: [DeliveryChannel]

    enum DeliveryChannel: String, Codable, CaseIterable, Identifiable {
        case email
        case whatsapp
        case sms

        var id: String { rawValue }

        var label: String {
            switch self {
            case .email: return NSLocalizedString("Email", comment: "")
            case .whatsapp: return NSLocalizedString("WhatsApp", comment: "")
            case .sms: return NSLocalizedString("Text Message", comment: "")
            }
        }

        static func from(rawValue: String) -> DeliveryChannel? {
            switch rawValue {
            case "email": return .email
            case "whatsapp": return .whatsapp
            case "sms": return .sms
            case "imessage": return .sms
            default: return nil
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let mapped = DeliveryChannel.from(rawValue: raw) {
                self = mapped
            } else {
                self = .email
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        contact: String,
        address: String,
        propertyDetails: String,
        phone: String = "",
        whatsappPhone: String = "",
        email: String = "",
        accessNotes: String = "",
        preferredSchedule: String = "",
        preferredDeliveryChannels: [DeliveryChannel] = [.email]
    ) {
        self.id = id
        self.name = name
        self.contact = contact
        self.address = address
        self.propertyDetails = propertyDetails
        self.phone = phone
        self.whatsappPhone = whatsappPhone
        self.email = email
        self.accessNotes = accessNotes
        self.preferredSchedule = preferredSchedule
        self.preferredDeliveryChannels = preferredDeliveryChannels
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contact
        case address
        case propertyDetails
        case phone
        case whatsappPhone
        case email
        case accessNotes
        case preferredSchedule
        case preferredDeliveryChannels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.contact = try container.decode(String.self, forKey: .contact)
        self.address = try container.decode(String.self, forKey: .address)
        self.propertyDetails = try container.decode(String.self, forKey: .propertyDetails)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        self.whatsappPhone = try container.decodeIfPresent(String.self, forKey: .whatsappPhone) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.accessNotes = try container.decodeIfPresent(String.self, forKey: .accessNotes) ?? ""
        self.preferredSchedule = try container.decodeIfPresent(String.self, forKey: .preferredSchedule) ?? ""
        self.preferredDeliveryChannels = try container.decodeIfPresent([DeliveryChannel].self, forKey: .preferredDeliveryChannels) ?? [.email]
    }
}

struct Employee: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var team: String
    var phone: String?
    var hourlyRate: Double?
    var currency: Currency?
    var extraEarningsDescription: String?
    var documentsDescription: String?

    enum Currency: String, Codable, CaseIterable, Identifiable {
        case usd
        case eur

        var id: String { rawValue }

        var label: String {
            switch self {
            case .usd: return "USD"
            case .eur: return "EUR"
            }
        }
    }
}

struct ServiceType: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var basePrice: Double
    var currency: FinanceEntry.Currency
    var pricingModel: PricingModel

    enum PricingModel: String, Codable, CaseIterable, Identifiable {
        case perTask
        case perHour

        var id: String { rawValue }

        var label: String {
            switch self {
            case .perTask: return NSLocalizedString("Per task", comment: "")
            case .perHour: return NSLocalizedString("Per hour", comment: "")
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        basePrice: Double,
        currency: FinanceEntry.Currency,
        pricingModel: PricingModel = .perTask
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.basePrice = basePrice
        self.currency = currency
        self.pricingModel = pricingModel
    }
}

struct ServiceTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var status: Status
    var assignedEmployee: Employee
    var clientId: UUID?
    var clientName: String
    var address: String
    var notes: String
    var serviceTypeId: UUID?
    var checkInTime: Date?
    var checkOutTime: Date?
    var checkInPhotoData: Data?
    var checkOutPhotoData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        status: Status,
        assignedEmployee: Employee,
        clientId: UUID? = nil,
        clientName: String,
        address: String,
        notes: String,
        serviceTypeId: UUID? = nil,
        checkInTime: Date? = nil,
        checkOutTime: Date? = nil,
        checkInPhotoData: Data? = nil,
        checkOutPhotoData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.assignedEmployee = assignedEmployee
        self.clientId = clientId
        self.clientName = clientName
        self.address = address
        self.notes = notes
        self.serviceTypeId = serviceTypeId
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.checkInPhotoData = checkInPhotoData
        self.checkOutPhotoData = checkOutPhotoData
    }

    enum Status: String, Codable, CaseIterable, Identifiable {
        case scheduled
        case inProgress
        case completed
        case canceled

        var id: String { rawValue }
        var label: String {
            switch self {
            case .scheduled: return NSLocalizedString("Scheduled", comment: "")
            case .inProgress: return NSLocalizedString("In progress", comment: "")
            case .completed: return NSLocalizedString("Completed", comment: "")
            case .canceled: return NSLocalizedString("Canceled", comment: "")
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
        case clientId
        case clientName
        case address
        case notes
        case serviceTypeId
        case checkInTime
        case checkOutTime
        case checkInPhotoData
        case checkOutPhotoData
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
        self.clientId = try container.decodeIfPresent(UUID.self, forKey: .clientId)
        self.clientName = try container.decodeIfPresent(String.self, forKey: .clientName) ?? ""
        self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.serviceTypeId = try container.decodeIfPresent(UUID.self, forKey: .serviceTypeId)
        self.checkInTime = try container.decodeIfPresent(Date.self, forKey: .checkInTime)
        self.checkOutTime = try container.decodeIfPresent(Date.self, forKey: .checkOutTime)
        self.checkInPhotoData = try container.decodeIfPresent(Data.self, forKey: .checkInPhotoData)
        self.checkOutPhotoData = try container.decodeIfPresent(Data.self, forKey: .checkOutPhotoData)
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
    var currency: Currency
    var clientId: UUID?
    var clientName: String?
    var employeeId: UUID?
    var employeeName: String?
    var kind: Kind
    var isDisputed: Bool
    var disputeReason: String?
    var receiptData: Data?
    var supersededById: UUID?
    var supersedesId: UUID?
    var supersededAt: Date?
    var payrollPeriodStart: Date?
    var payrollPeriodEnd: Date?
    var payrollHoursWorked: Double
    var payrollDaysWorked: Int
    var payrollHourlyRate: Double
    var payrollBasePay: Double
    var payrollBonus: Double
    var payrollDeductions: Double
    var payrollTaxes: Double
    var payrollReimbursements: Double
    var payrollNetPay: Double
    var payrollNotes: String?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: EntryType,
        dueDate: Date,
        status: Status = .pending,
        method: PaymentMethod? = nil,
        currency: Currency = .usd,
        clientId: UUID? = nil,
        clientName: String? = nil,
        employeeId: UUID? = nil,
        employeeName: String? = nil,
        kind: Kind = .general,
        isDisputed: Bool = false,
        disputeReason: String? = nil,
        receiptData: Data? = nil,
        supersededById: UUID? = nil,
        supersedesId: UUID? = nil,
        supersededAt: Date? = nil,
        payrollPeriodStart: Date? = nil,
        payrollPeriodEnd: Date? = nil,
        payrollHoursWorked: Double = 0,
        payrollDaysWorked: Int = 0,
        payrollHourlyRate: Double = 0,
        payrollBasePay: Double = 0,
        payrollBonus: Double = 0,
        payrollDeductions: Double = 0,
        payrollTaxes: Double = 0,
        payrollReimbursements: Double = 0,
        payrollNetPay: Double = 0,
        payrollNotes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.dueDate = dueDate
        self.status = status
        self.method = method
        self.currency = currency
        self.clientId = clientId
        self.clientName = clientName
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.kind = kind
        self.isDisputed = isDisputed
        self.disputeReason = disputeReason
        self.receiptData = receiptData
        self.supersededById = supersededById
        self.supersedesId = supersedesId
        self.supersededAt = supersededAt
        self.payrollPeriodStart = payrollPeriodStart
        self.payrollPeriodEnd = payrollPeriodEnd
        self.payrollHoursWorked = payrollHoursWorked
        self.payrollDaysWorked = payrollDaysWorked
        self.payrollHourlyRate = payrollHourlyRate
        self.payrollBasePay = payrollBasePay
        self.payrollBonus = payrollBonus
        self.payrollDeductions = payrollDeductions
        self.payrollTaxes = payrollTaxes
        self.payrollReimbursements = payrollReimbursements
        self.payrollNetPay = payrollNetPay
        self.payrollNotes = payrollNotes
    }

    enum EntryType: String, Codable {
        case payable
        case receivable
    }

    enum Kind: String, Codable {
        case general
        case invoiceClient
        case payrollEmployee
        case expenseOutOfPocket
    }

    enum Status: String, Codable {
        case pending
        case paid

        var label: String {
            switch self {
            case .pending: return NSLocalizedString("Pending", comment: "")
            case .paid: return NSLocalizedString("Paid", comment: "")
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
            case .pix: return NSLocalizedString("Pix", comment: "")
            case .card: return NSLocalizedString("Card", comment: "")
            case .cash: return NSLocalizedString("Cash", comment: "")
            }
        }
    }

    enum Currency: String, Codable, CaseIterable, Identifiable {
        case usd
        case eur

        var id: String { rawValue }

        var code: String {
            switch self {
            case .usd: return "USD"
            case .eur: return "EUR"
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
        case currency
        case clientId
        case clientName
        case employeeId
        case employeeName
        case kind
        case isDisputed
        case disputeReason
        case receiptData
        case supersededById
        case supersedesId
        case supersededAt
        case payrollPeriodStart
        case payrollPeriodEnd
        case payrollHoursWorked
        case payrollDaysWorked
        case payrollHourlyRate
        case payrollBasePay
        case payrollBonus
        case payrollDeductions
        case payrollTaxes
        case payrollReimbursements
        case payrollNetPay
        case payrollNotes
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
        self.currency = try container.decodeIfPresent(Currency.self, forKey: .currency) ?? .usd
        self.clientId = try container.decodeIfPresent(UUID.self, forKey: .clientId)
        self.clientName = try container.decodeIfPresent(String.self, forKey: .clientName)
        self.employeeId = try container.decodeIfPresent(UUID.self, forKey: .employeeId)
        self.employeeName = try container.decodeIfPresent(String.self, forKey: .employeeName)
        self.kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .general
        self.isDisputed = try container.decodeIfPresent(Bool.self, forKey: .isDisputed) ?? false
        self.disputeReason = try container.decodeIfPresent(String.self, forKey: .disputeReason)
        self.receiptData = try container.decodeIfPresent(Data.self, forKey: .receiptData)
        self.supersededById = try container.decodeIfPresent(UUID.self, forKey: .supersededById)
        self.supersedesId = try container.decodeIfPresent(UUID.self, forKey: .supersedesId)
        self.supersededAt = try container.decodeIfPresent(Date.self, forKey: .supersededAt)
        self.payrollPeriodStart = try container.decodeIfPresent(Date.self, forKey: .payrollPeriodStart)
        self.payrollPeriodEnd = try container.decodeIfPresent(Date.self, forKey: .payrollPeriodEnd)
        self.payrollHoursWorked = try container.decodeIfPresent(Double.self, forKey: .payrollHoursWorked) ?? 0
        self.payrollDaysWorked = try container.decodeIfPresent(Int.self, forKey: .payrollDaysWorked) ?? 0
        self.payrollHourlyRate = try container.decodeIfPresent(Double.self, forKey: .payrollHourlyRate) ?? 0
        self.payrollBasePay = try container.decodeIfPresent(Double.self, forKey: .payrollBasePay) ?? 0
        self.payrollBonus = try container.decodeIfPresent(Double.self, forKey: .payrollBonus) ?? 0
        self.payrollDeductions = try container.decodeIfPresent(Double.self, forKey: .payrollDeductions) ?? 0
        self.payrollTaxes = try container.decodeIfPresent(Double.self, forKey: .payrollTaxes) ?? 0
        self.payrollReimbursements = try container.decodeIfPresent(Double.self, forKey: .payrollReimbursements) ?? 0
        self.payrollNetPay = try container.decodeIfPresent(Double.self, forKey: .payrollNetPay) ?? self.amount
        self.payrollNotes = try container.decodeIfPresent(String.self, forKey: .payrollNotes)
    }
}

struct UserSession: Codable {
    var token: String
    var name: String

    enum Role: String, Codable {
        case employee
        case manager
    }

    var role: Role
}
