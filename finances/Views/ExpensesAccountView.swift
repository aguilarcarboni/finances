import SwiftUI

struct ExpensesAccountView: View {
    @ObservedObject private var account = PlannerStore.shared
    @State private var editingExpense: PlannedExpense?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Pay period", selection: $account.selectedPeriod) {
                        ForEach(PlannerPayPeriod.allCases) { period in Text(period.rawValue).tag(period) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Rolling expenses") {
                    ForEach(account.rollingExpenses) { item in
                        RollingPlannerRow(item: item, account: account)
                    }
                }

                Section("Regular expenses — \(account.selectedPeriod.rawValue)") {
                    ForEach(account.activeExpenses) { item in
                        PlannedExpenseRow(item: item, account: account) { editingExpense = item }
                    }
                }

                Section("This half overview") {
                    PlannerMoneyRow(label: "Salary", amount: account.activeSalary, account: account, bold: true)
                    PlannerMoneyRow(label: "Regular expenses paid", amount: account.activePaid, account: account)
                    PlannerMoneyRow(label: "Rolling contribution added", amount: account.activeRollingContributions, account: account)
                    PlannerMoneyRow(label: "Minimum needed to pay all expenses", amount: account.activeMinimumNeeded, account: account)
                    Divider()
                    PlannerMoneyRow(label: "Leftover now", amount: account.activeLeftoverAfterActuals, account: account, bold: true)
                    PlannerMoneyRow(label: "Leftover if fully paid", amount: account.activeLeftoverAfterPlanned, account: account, bold: true)
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem() {
                    Menu {
                        Picker("Currency", selection: $account.currency) {
                            ForEach(PlannerCurrency.allCases) { currency in Text(currency.rawValue).tag(currency) }
                        }
                        Text("1 USD = \(account.usdToCrcRate, specifier: "%.0f") CRC")
                    } label: { Label(account.currencyLabel, systemImage: "dollarsign.circle") }
                }
            }
            .sheet(item: $editingExpense) { item in
                PlannedExpenseEditor(item: item, account: account)
            }
        }
    }
}

private struct RollingPlannerRow: View {
    let item: RollingExpensePlan
    @ObservedObject var account: PlannerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name).font(.headline)
                    Text("\(account.money(item.savedAmount)) saved of \(account.money(item.targetAmount))")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(item.recurrence) · due \(item.dueDate, format: .dateTime.day().month().year())")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button(account.isFunded(item) ? "Added" : "+\(account.money(item.contributionPerPeriod))") {
                    account.addContribution(to: item)
                }
                .buttonStyle(.borderedProminent)
                .disabled(account.isFunded(item))
            }
            if item.savedAmount > 0 {
                Button("Mark paid — reset saved amount") { account.markRollingPaid(item) }
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PlannedExpenseRow: View {
    let item: PlannedExpense
    @ObservedObject var account: PlannerStore
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name).foregroundStyle(.primary)
                    Text(item.category).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(account.money(item.paidAmount)).foregroundStyle(item.status == .paid ? .green : .primary)
                    Text("of \(account.money(item.plannedAmount))").font(.caption).foregroundStyle(.secondary)
                }
                Image(systemName: item.status == .paid ? "checkmark.circle.fill" : "pencil.circle")
                    .foregroundStyle(item.status == .paid ? .green : .secondary)
            }
        }
    }
}

private struct PlannedExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var account: PlannerStore
    @State private var item: PlannedExpense
    @State private var plannedText = ""
    @State private var paidText = ""

    init(item: PlannedExpense, account: PlannerStore) {
        self.account = account
        _item = State(initialValue: item)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(item.name) {
                    TextField("Planned amount", text: $plannedText)
                    TextField("Paid amount", text: $paidText)
                }
            }
            .navigationTitle("Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.plannedAmount = account.amountFromDisplay(plannedText)
                        item.paidAmount = min(account.amountFromDisplay(paidText), item.plannedAmount)
                        account.update(item)
                        dismiss()
                    }
                }
            }
            .onAppear {
                plannedText = account.inputText(item.plannedAmount)
                paidText = account.inputText(item.paidAmount)
            }
        }
    }
}

private struct PlannerMoneyRow: View {
    let label: String
    let amount: Double
    @ObservedObject var account: PlannerStore
    var bold = false

    var body: some View {
        HStack {
            Text(label).fontWeight(bold ? .semibold : .regular)
            Spacer()
            Text(account.money(amount)).fontWeight(bold ? .semibold : .regular).monospacedDigit()
        }
    }
}

#Preview { ExpensesAccountView() }
