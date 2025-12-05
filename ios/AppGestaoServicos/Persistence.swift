import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "AppGestaoServicos", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Employee
        let employee = NSEntityDescription()
        employee.name = "EmployeeEntity"
        employee.managedObjectClassName = "NSManagedObject"

        let employeeId = NSAttributeDescription()
        employeeId.name = "id"
        employeeId.attributeType = .UUIDAttributeType
        employeeId.isOptional = false

        let employeeName = NSAttributeDescription()
        employeeName.name = "name"
        employeeName.attributeType = .stringAttributeType
        employeeName.isOptional = false

        let employeeRoleTitle = NSAttributeDescription()
        employeeRoleTitle.name = "roleTitle"
        employeeRoleTitle.attributeType = .stringAttributeType
        employeeRoleTitle.isOptional = true

        let employeeTeam = NSAttributeDescription()
        employeeTeam.name = "team"
        employeeTeam.attributeType = .stringAttributeType
        employeeTeam.isOptional = true

        let employeeHourlyRate = NSAttributeDescription()
        employeeHourlyRate.name = "hourlyRate"
        employeeHourlyRate.attributeType = .doubleAttributeType
        employeeHourlyRate.isOptional = true

        let employeePhone = NSAttributeDescription()
        employeePhone.name = "phone"
        employeePhone.attributeType = .stringAttributeType
        employeePhone.isOptional = true

        let employeeCurrency = NSAttributeDescription()
        employeeCurrency.name = "currency"
        employeeCurrency.attributeType = .stringAttributeType
        employeeCurrency.isOptional = true

        let employeeExtra = NSAttributeDescription()
        employeeExtra.name = "extraEarningsDescription"
        employeeExtra.attributeType = .stringAttributeType
        employeeExtra.isOptional = true

        let employeeDocuments = NSAttributeDescription()
        employeeDocuments.name = "documentsDescription"
        employeeDocuments.attributeType = .stringAttributeType
        employeeDocuments.isOptional = true

        employee.properties = [
            employeeId,
            employeeName,
            employeeRoleTitle,
            employeeTeam,
            employeeHourlyRate,
            employeePhone,
            employeeCurrency,
            employeeExtra,
            employeeDocuments
        ]

        // Client
        let client = NSEntityDescription()
        client.name = "ClientEntity"
        client.managedObjectClassName = "NSManagedObject"

        let clientId = NSAttributeDescription()
        clientId.name = "id"
        clientId.attributeType = .UUIDAttributeType
        clientId.isOptional = false

        let clientName = NSAttributeDescription()
        clientName.name = "name"
        clientName.attributeType = .stringAttributeType
        clientName.isOptional = false

        let clientContact = NSAttributeDescription()
        clientContact.name = "contact"
        clientContact.attributeType = .stringAttributeType
        clientContact.isOptional = false

        let clientAddress = NSAttributeDescription()
        clientAddress.name = "address"
        clientAddress.attributeType = .stringAttributeType
        clientAddress.isOptional = false

        let clientPropertyDetails = NSAttributeDescription()
        clientPropertyDetails.name = "propertyDetails"
        clientPropertyDetails.attributeType = .stringAttributeType
        clientPropertyDetails.isOptional = false

        let clientPhone = NSAttributeDescription()
        clientPhone.name = "phone"
        clientPhone.attributeType = .stringAttributeType
        clientPhone.isOptional = true

        let clientEmail = NSAttributeDescription()
        clientEmail.name = "email"
        clientEmail.attributeType = .stringAttributeType
        clientEmail.isOptional = true

        let clientAccessNotes = NSAttributeDescription()
        clientAccessNotes.name = "accessNotes"
        clientAccessNotes.attributeType = .stringAttributeType
        clientAccessNotes.isOptional = true

        let clientPreferredSchedule = NSAttributeDescription()
        clientPreferredSchedule.name = "preferredSchedule"
        clientPreferredSchedule.attributeType = .stringAttributeType
        clientPreferredSchedule.isOptional = true

        client.properties = [
            clientId,
            clientName,
            clientContact,
            clientAddress,
            clientPropertyDetails,
            clientPhone,
            clientEmail,
            clientAccessNotes,
            clientPreferredSchedule
        ]

        // ServiceType
        let serviceType = NSEntityDescription()
        serviceType.name = "ServiceTypeEntity"
        serviceType.managedObjectClassName = "NSManagedObject"

        let serviceTypeId = NSAttributeDescription()
        serviceTypeId.name = "id"
        serviceTypeId.attributeType = .UUIDAttributeType
        serviceTypeId.isOptional = false

        let serviceTypeName = NSAttributeDescription()
        serviceTypeName.name = "name"
        serviceTypeName.attributeType = .stringAttributeType
        serviceTypeName.isOptional = false

        let serviceTypeDescription = NSAttributeDescription()
        serviceTypeDescription.name = "serviceDescription"
        serviceTypeDescription.attributeType = .stringAttributeType
        serviceTypeDescription.isOptional = true

        let serviceTypePrice = NSAttributeDescription()
        serviceTypePrice.name = "basePrice"
        serviceTypePrice.attributeType = .decimalAttributeType
        serviceTypePrice.isOptional = false

        let serviceTypeCurrency = NSAttributeDescription()
        serviceTypeCurrency.name = "currency"
        serviceTypeCurrency.attributeType = .stringAttributeType
        serviceTypeCurrency.isOptional = false

        serviceType.properties = [
            serviceTypeId,
            serviceTypeName,
            serviceTypeDescription,
            serviceTypePrice,
            serviceTypeCurrency
        ]

        // ServiceTask
        let serviceTask = NSEntityDescription()
        serviceTask.name = "ServiceTaskEntity"
        serviceTask.managedObjectClassName = "NSManagedObject"

        let serviceTaskId = NSAttributeDescription()
        serviceTaskId.name = "id"
        serviceTaskId.attributeType = .UUIDAttributeType
        serviceTaskId.isOptional = false

        let serviceTaskTitle = NSAttributeDescription()
        serviceTaskTitle.name = "title"
        serviceTaskTitle.attributeType = .stringAttributeType
        serviceTaskTitle.isOptional = false

        let serviceTaskDate = NSAttributeDescription()
        serviceTaskDate.name = "date"
        serviceTaskDate.attributeType = .dateAttributeType
        serviceTaskDate.isOptional = false

        let serviceTaskStart = NSAttributeDescription()
        serviceTaskStart.name = "startTime"
        serviceTaskStart.attributeType = .dateAttributeType
        serviceTaskStart.isOptional = true

        let serviceTaskEnd = NSAttributeDescription()
        serviceTaskEnd.name = "endTime"
        serviceTaskEnd.attributeType = .dateAttributeType
        serviceTaskEnd.isOptional = true

        let serviceTaskStatus = NSAttributeDescription()
        serviceTaskStatus.name = "status"
        serviceTaskStatus.attributeType = .stringAttributeType
        serviceTaskStatus.isOptional = false

        let serviceTaskNotes = NSAttributeDescription()
        serviceTaskNotes.name = "notes"
        serviceTaskNotes.attributeType = .stringAttributeType
        serviceTaskNotes.isOptional = true

        let serviceTaskAddress = NSAttributeDescription()
        serviceTaskAddress.name = "address"
        serviceTaskAddress.attributeType = .stringAttributeType
        serviceTaskAddress.isOptional = true

        let serviceTaskServiceTypeId = NSAttributeDescription()
        serviceTaskServiceTypeId.name = "serviceTypeId"
        serviceTaskServiceTypeId.attributeType = .UUIDAttributeType
        serviceTaskServiceTypeId.isOptional = true

        let serviceTaskCheckIn = NSAttributeDescription()
        serviceTaskCheckIn.name = "checkInTime"
        serviceTaskCheckIn.attributeType = .dateAttributeType
        serviceTaskCheckIn.isOptional = true

        let serviceTaskCheckOut = NSAttributeDescription()
        serviceTaskCheckOut.name = "checkOutTime"
        serviceTaskCheckOut.attributeType = .dateAttributeType
        serviceTaskCheckOut.isOptional = true

        serviceTask.properties = [
            serviceTaskId,
            serviceTaskTitle,
            serviceTaskDate,
            serviceTaskStart,
            serviceTaskEnd,
            serviceTaskStatus,
            serviceTaskNotes,
            serviceTaskAddress,
            serviceTaskServiceTypeId,
            serviceTaskCheckIn,
            serviceTaskCheckOut
        ]

        // FinanceEntry
        let finance = NSEntityDescription()
        finance.name = "FinanceEntryEntity"
        finance.managedObjectClassName = "NSManagedObject"

        let financeId = NSAttributeDescription()
        financeId.name = "id"
        financeId.attributeType = .UUIDAttributeType
        financeId.isOptional = false

        let financeTitle = NSAttributeDescription()
        financeTitle.name = "title"
        financeTitle.attributeType = .stringAttributeType
        financeTitle.isOptional = false

        let financeAmount = NSAttributeDescription()
        financeAmount.name = "amount"
        financeAmount.attributeType = .doubleAttributeType
        financeAmount.isOptional = false

        let financeCurrency = NSAttributeDescription()
        financeCurrency.name = "currency"
        financeCurrency.attributeType = .stringAttributeType
        financeCurrency.isOptional = false

        let financeType = NSAttributeDescription()
        financeType.name = "type"
        financeType.attributeType = .stringAttributeType
        financeType.isOptional = false

        let financeDueDate = NSAttributeDescription()
        financeDueDate.name = "dueDate"
        financeDueDate.attributeType = .dateAttributeType
        financeDueDate.isOptional = false

        let financeStatus = NSAttributeDescription()
        financeStatus.name = "status"
        financeStatus.attributeType = .stringAttributeType
        financeStatus.isOptional = false

        let financeMethod = NSAttributeDescription()
        financeMethod.name = "method"
        financeMethod.attributeType = .stringAttributeType
        financeMethod.isOptional = true

        let financeClientName = NSAttributeDescription()
        financeClientName.name = "clientName"
        financeClientName.attributeType = .stringAttributeType
        financeClientName.isOptional = true

        let financeEmployeeName = NSAttributeDescription()
        financeEmployeeName.name = "employeeName"
        financeEmployeeName.attributeType = .stringAttributeType
        financeEmployeeName.isOptional = true

        finance.properties = [
            financeId,
            financeTitle,
            financeAmount,
            financeCurrency,
            financeType,
            financeDueDate,
            financeStatus,
            financeMethod,
            financeClientName,
            financeEmployeeName
        ]

        model.entities = [employee, client, serviceType, serviceTask, finance]
        return model
    }
}
