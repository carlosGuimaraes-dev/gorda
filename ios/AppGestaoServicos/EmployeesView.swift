import SwiftUI

struct EmployeesView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var showingForm = false

    var body: some View {
        List {
            ForEach(store.employees) { employee in
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
                    if let rate = employee.hourlyRate, let currency = employee.currency {
                        Text("Hourly rate: \(currency.label) \(rate, specifier: "%.2f")")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let extra = employee.extraEarningsDescription, !extra.isEmpty {
                        Text("Extra earnings: \(extra)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let docs = employee.documentsDescription, !docs.isEmpty {
                        Text("Documents: \(docs)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
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
}

struct EmployeeFormView: View {
    @EnvironmentObject private var store: OfflineStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var roleTitle: String = ""
    @State private var team: String = ""
    @State private var hourlyRateText: String = ""
    @State private var currency: Employee.Currency = .eur
    @State private var extraEarnings: String = ""
    @State private var documents: String = ""

    private var hourlyRate: Double? {
        Double(hourlyRateText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        Form {
            Section("Basic info") {
                TextField("Name", text: $name)
                TextField("Role / Title", text: $roleTitle)
                TextField("Team", text: $team)
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
        .navigationTitle("New Employee")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.addEmployee(
                        name: name,
                        roleTitle: roleTitle,
                        team: team,
                        hourlyRate: hourlyRate,
                        currency: currency,
                        extraEarningsDescription: extraEarnings.isEmpty ? nil : extraEarnings,
                        documentsDescription: documents.isEmpty ? nil : documents
                    )
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

