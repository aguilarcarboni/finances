import SwiftUI

/// Displays detailed information about a `Transaction`.
struct TransactionDetailView: View {
    // MARK: - Dependencies
    @ObservedObject private var account = ExpensesAccount.shared

    // The transaction to inspect / edit
    let transaction: Transaction

    // View is read-only; no local editable state needed

    // MARK: - Init
    init(transaction: Transaction) {
        self.transaction = transaction
    }

    // MARK: - Formatters
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    // Removed allCategories since editing is disabled

    // MARK: - View
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(transaction.name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Amount")
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "")
                        .foregroundColor(transaction.isDebit ? .red : .green)
                }

                HStack {
                    Text("Date")
                    Spacer()
                    Text(dateFormatter.string(from: transaction.date))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Type")
                    Spacer()
                    Text(transaction.type.rawValue)
                        .foregroundColor(.secondary)
                }
            }

            // Static Category row
            Section(header: Text("Category")) {
                HStack {
                    Text("Category")
                    Spacer()
                    Text(transaction.category)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Transaction")
    }
}

#if DEBUG
struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock transaction for preview
        let sample = Transaction(name: "Coffee", category: "Food", amount: 2500, type: .debit, date: Date())
        NavigationStack {
            TransactionDetailView(transaction: sample)
        }
    }
}
#endif 