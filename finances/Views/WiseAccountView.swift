import SwiftUI

struct WiseAccountView: View {
    @ObservedObject private var account = WiseAccount.shared
    @State private var selectedDate: Date = Date()

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }

    private var expensesTransferValidation: (isValid: Bool, message: String) {
        account.validateTransfersFromExpenses(ExpensesAccount.shared)
    }

    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: selectedDate)
        let monthStart = calendar.date(from: comps) ?? selectedDate
        let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate
        return (start: monthStart, end: dayEnd)
    }

    private var filteredTransactions: [Transaction] {
        account.transactions.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
    }

    private var dateRangeDisplay: String {
        "\(dateRange.start.formatted(date: .abbreviated, time: .omitted)) - \(dateRange.end.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(dateRangeDisplay)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currencyFormatter.string(from: NSNumber(value: account.netBalance)) ?? "-")
                                .font(.title2.monospacedDigit())
                                .fontWeight(.bold)
                                .foregroundColor(account.netBalance >= 0 ? .green : .red)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: expensesTransferValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(expensesTransferValidation.isValid ? .green : .orange)
                                .font(.caption)
                            Text(expensesTransferValidation.isValid ? "Expenses Credits Validated" : "Check Expenses Credits")
                                .font(.caption)
                                .foregroundColor(expensesTransferValidation.isValid ? .green : .orange)
                        }
                    }
                }

                Section(header: Text("Transactions")) {
                    if filteredTransactions.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No transactions yet")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredTransactions.sorted { $0.date > $1.date }) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRow(transaction: transaction, isDebit: transaction.type == .debit)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wise Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
        }
    }
}

#Preview {
    WiseAccountView()
} 