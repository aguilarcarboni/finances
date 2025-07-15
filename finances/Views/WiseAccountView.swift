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

    var body: some View {
        NavigationStack {
            List {
                // Account summary section
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Wise Account Balance")
                            .font(.headline)
                        Text(currencyFormatter.string(from: NSNumber(value: account.netBalance)) ?? "-")
                            .font(.title2.monospacedDigit())
                            .fontWeight(.bold)
                            .foregroundColor(account.netBalance >= 0 ? .green : .red)
                        // Expenses transfer validation indicator
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

                // Transactions Section
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