import SwiftUI

#if canImport(Contacts)
import Contacts
#endif

struct EmployeesView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingForm = false

    var body: some View {
        List {
            ForEach(store.employees) { employee in
                EmployeeRow(
                    employee: employee,
                    hasPendingPayables: hasPendingPayables(for: employee)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Employees")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            NavigationStack {
                EmployeeFormView()
            }
        }
    }

    private func hasPendingPayables(for employee: Employee) -> Bool {
        store.finance.contains {
            $0.employeeName == employee.name &&
            $0.type == .payable &&
            $0.status == .pending
        }
    }
}

private struct EmployeeRow: View {
    let employee: Employee
    let hasPendingPayables: Bool

    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(name: employee.name, phone: employee.phone, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name).bold()
                Text(employee.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !employee.team.isEmpty {
                    Text("Team: \(employee.team)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let phone = employee.phone, !phone.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                        Text(phone)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                if let rate = employee.hourlyRate, let currency = employee.currency {
                    Text("Hourly rate: \(currency.label) \(rate, specifier: "%.2f")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            PaymentStatusIcon(hasPending: hasPendingPayables)
        }
        .padding(10)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct EmployeeFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var roleTitle: String = ""
    @State private var team: String = ""
    @State private var phoneLocal: String = ""
    @State private var phoneCode: CountryCode = .defaultCode
    @State private var hourlyRateText: String = ""
    @State private var currency: Employee.Currency = .eur
    @State private var extraEarnings: String = ""
    @State private var documents: String = ""

    private var hourlyRate: Double? {
        Double(hourlyRateText.replacingOccurrences(of: ",", with: "."))
    }

    @State private var showContactPicker = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Basic info") {
                    TextField("Name", text: $name)
                    TextField("Role / Title", text: $roleTitle)
                    TextField("Team", text: $team)
                    HStack {
                        CountryCodePicker(selection: $phoneCode)
                        TextField("Phone", text: $phoneLocal)
                            .keyboardType(.phonePad)
                    }
                    Button {
                        showContactPicker = true
                    } label: {
                        Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                Section("Compensation") {
                    TextField("Hourly rate", text: $hourlyRateText)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        ForEach(Employee.Currency.allCases) { curr in
                            Text(curr.label).tag(curr)
                        }
                    }
                    TextField("Other earnings (description)", text: $extraEarnings)
                }

                Section("Documents") {
                    TextField("Documents / notes", text: $documents)
                }
            }

            PrimaryButton(title: "Save") {
                let fullPhone = phoneLocal.isEmpty ? nil : "\(phoneCode.dialCode) \(phoneLocal)"
                store.addEmployee(
                    name: name,
                    roleTitle: roleTitle,
                    team: team,
                    phone: fullPhone,
                    hourlyRate: hourlyRate,
                    currency: currency,
                    extraEarningsDescription: extraEarnings.isEmpty ? nil : extraEarnings,
                    documentsDescription: documents.isEmpty ? nil : documents
                )
                dismiss()
            }
            .padding()
            .disabled(name.isEmpty)
        }
        .navigationTitle("New Employee")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
#if canImport(ContactsUI) && canImport(UIKit)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { contact in
                apply(contact: contact)
                showContactPicker = false
            } onCancel: {
                showContactPicker = false
            }
        }
#endif
    }

#if canImport(Contacts)
    private func apply(contact: CNContact) {
        if name.isEmpty {
            if let fullName = CNContactFormatter.string(from: contact, style: .fullName) {
                name = fullName
            } else {
                let composed = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if !composed.isEmpty { name = composed }
            }
        }

        if phoneLocal.isEmpty, let phoneValue = contact.phoneNumbers.first?.value.stringValue, !phoneValue.isEmpty {
            let normalized = phoneValue.replacingOccurrences(of: " ", with: "")
            if let match = CountryCode.all.first(where: { normalized.hasPrefix($0.dialCode) }) {
                phoneCode = match
                let local = normalized.dropFirst(match.dialCode.count)
                phoneLocal = String(local)
            } else {
                phoneLocal = phoneValue
            }
        }
    }
#endif
}
