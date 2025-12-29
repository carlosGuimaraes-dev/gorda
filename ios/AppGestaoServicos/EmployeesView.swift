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
                NavigationLink(destination: EmployeeDetailView(employee: employee)) {
                    EmployeeRow(
                        employee: employee,
                        hasPendingPayables: hasPendingPayables(for: employee)
                    )
                }
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
                    Text(String(format: NSLocalizedString("Team: %@", comment: ""), employee.team))
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
                    Text(String(format: NSLocalizedString("Hourly rate: %@ %.2f", comment: ""), currency.label, rate))
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

    private let employee: Employee?
    private let onSave: (() -> Void)?

    @State private var name: String
    @State private var roleTitle: String
    @State private var team: String
    @State private var phoneLocal: String
    @State private var phoneCode: CountryCode
    @State private var hourlyRateText: String
    @State private var currency: Employee.Currency
    @State private var extraEarnings: String
    @State private var documents: String

    private var hourlyRate: Double? {
        Double(hourlyRateText.replacingOccurrences(of: ",", with: "."))
    }

    @State private var showContactPicker = false
    private var isEditing: Bool { employee != nil }

    init(employee: Employee? = nil, onSave: (() -> Void)? = nil) {
        self.employee = employee
        self.onSave = onSave
        _name = State(initialValue: employee?.name ?? "")
        _roleTitle = State(initialValue: employee?.role ?? "")
        _team = State(initialValue: employee?.team ?? "")
        _phoneLocal = State(initialValue: employee?.phone ?? "")
        _phoneCode = State(initialValue: .defaultCode)
        if let rate = employee?.hourlyRate {
            _hourlyRateText = State(initialValue: String(format: "%.2f", rate))
        } else {
            _hourlyRateText = State(initialValue: "")
        }
        _currency = State(initialValue: employee?.currency ?? .eur)
        _extraEarnings = State(initialValue: employee?.extraEarningsDescription ?? "")
        _documents = State(initialValue: employee?.documentsDescription ?? "")
    }

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
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(store.appPreferences.preferredCurrency.code)
                            .foregroundColor(.secondary)
                    }
                    TextField("Other earnings (description)", text: $extraEarnings)
                }

                Section("Documents") {
                    TextField("Documents / notes", text: $documents)
                }
            }

            PrimaryButton(title: isEditing ? "Update" : "Save") {
                let fullPhone: String?
                if phoneLocal.isEmpty {
                    fullPhone = nil
                } else if phoneLocal.hasPrefix(phoneCode.dialCode) {
                    fullPhone = phoneLocal
                } else {
                    fullPhone = "\(phoneCode.dialCode) \(phoneLocal)"
                }

                if let employee {
                    store.updateEmployee(
                        employee,
                        name: name,
                        roleTitle: roleTitle,
                        team: team,
                        phone: fullPhone,
                        hourlyRate: hourlyRate,
                        currency: employeeCurrency(),
                        extraEarningsDescription: extraEarnings.isEmpty ? nil : extraEarnings,
                        documentsDescription: documents.isEmpty ? nil : documents
                    )
                } else {
                    store.addEmployee(
                        name: name,
                        roleTitle: roleTitle,
                        team: team,
                        phone: fullPhone,
                        hourlyRate: hourlyRate,
                        currency: employeeCurrency(),
                        extraEarningsDescription: extraEarnings.isEmpty ? nil : extraEarnings,
                        documentsDescription: documents.isEmpty ? nil : documents
                    )
                }

                onSave?()
                dismiss()
            }
            .padding()
            .disabled(name.isEmpty)
        }
        .navigationTitle(isEditing ? "Edit Employee" : "New Employee")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            currency = employeeCurrency()
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

    private func employeeCurrency() -> Employee.Currency {
        Employee.Currency(rawValue: store.appPreferences.preferredCurrency.rawValue) ?? .usd
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

struct EmployeeDetailView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    let employee: Employee
    @State private var showingEdit = false
    @State private var showDeleteAlert = false
    @State private var showDeleteBlocked = false

    private var assignedTasks: [ServiceTask] {
        store.tasks.filter { $0.assignedEmployee.id == employee.id }
    }

    private var pendingPayablesCount: Int {
        store.finance.filter { $0.employeeName == employee.name && $0.status == .pending }.count
    }

    private var canDelete: Bool {
        assignedTasks.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppCard {
                    HStack(alignment: .top, spacing: 12) {
                        ContactAvatarView(name: employee.name, phone: employee.phone, size: 56)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(employee.name)
                                .font(.title3.bold())
                            Text(employee.role)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !employee.team.isEmpty {
                                Text(String(format: NSLocalizedString("Team: %@", comment: ""), employee.team))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            if let phone = employee.phone, !phone.isEmpty {
                                Text(phone)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    if let phone = employee.phone, !phone.isEmpty {
                        HStack(spacing: 12) {
                            if let callURL = phoneURL(phone) {
                                contactButton(title: "Call", systemImage: "phone.fill") {
                                    openURL(callURL)
                                }
                            }
                            if let smsURL = smsURL(phone) {
                                contactButton(title: "Message", systemImage: "message.fill") {
                                    openURL(smsURL)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)

                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compensation")
                            .font(.headline)
                        if let rate = employee.hourlyRate, let currency = employee.currency {
                            let rateString = String(format: "%.2f", rate)
                            labeledRow(title: "Hourly rate", value: "\(currency.label) \(rateString)")
                        }
                        if let extra = employee.extraEarningsDescription, !extra.isEmpty {
                            labeledRow(title: "Extra earnings", value: extra)
                        }
                        if let docs = employee.documentsDescription, !docs.isEmpty {
                            labeledRow(title: "Documents", value: docs)
                        }
                        if pendingPayablesCount > 0 {
                            labeledRow(title: "Pending payables", value: String(pendingPayablesCount))
                        }
                    }
                }
                .padding(.horizontal)

                if !assignedTasks.isEmpty {
                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Assignments")
                                .font(.headline)
                            ForEach(assignedTasks.prefix(6)) { task in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(task.title)
                                            .font(.subheadline.bold())
                                        Spacer()
                                        StatusBadge(status: task.status)
                                    }
                                    Text(task.date, style: .date)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                if task.id != assignedTasks.prefix(6).last?.id {
                                    Divider()
                                }
                            }
                            if assignedTasks.count > 6 {
                                Text(String(format: NSLocalizedString("+ %d more", comment: ""), assignedTasks.count - 6))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if canDelete {
                    AppCard {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Remove employee", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    AppCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cannot remove")
                                .font(.headline)
                            Text("This employee has assigned services. Reassign or complete them before removing.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 12)
            }
            .padding(.vertical, 12)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(employee.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                EmployeeFormView(employee: employee) {
                    showingEdit = false
                }
            }
        }
        .alert("Remove employee?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if store.deleteEmployee(employee) {
                    dismiss()
                } else {
                    showDeleteBlocked = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Cannot remove employee", isPresented: $showDeleteBlocked) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Reassign or complete the services linked to this employee before removing.")
        }
    }

    private func phoneURL(_ phone: String) -> URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    private func smsURL(_ phone: String) -> URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms:\(digits)")
    }

    private func contactButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(AppTheme.primary.opacity(0.08))
                .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    private func labeledRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
