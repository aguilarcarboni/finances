import SwiftUI

struct WiseAccountView: View {
    @ObservedObject private var account = WiseAccount.shared

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

    private var dateRangeDisplay: String {
        let startDate = account.transactions.first?.date ?? Date()
        let endDate = account.transactions.last?.date ?? Date()
        return "\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))"
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
                    if account.transactions.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No transactions yet")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(account.transactions.sorted { $0.date > $1.date }) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRow(transaction: transaction, isDebit: transaction.type == .debit)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wise Account")
        }
    }
}

#Preview {
    WiseAccountView()
} 