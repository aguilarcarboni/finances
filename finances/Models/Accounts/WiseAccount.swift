import SwiftUI
import Foundation
import Combine

class WiseAccount: ObservableObject, Account {
    // MARK: - Singleton
    static let shared = WiseAccount()
    private init() {}

    // MARK: - Account Data
    @Published var transactions: [Transaction] = []
    // Pass-through account so no budgeting applies
    @Published var budget: [BudgetCategory] = []

    // MARK: - Account Protocol Implementation
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        // Keep transactions sorted by most recent first
        transactions.sort { $0.date > $1.date }
    }

    func removeTransaction(with id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    // MARK: - CSV Import Helper
    func importTransactions(fromCSV url: URL) {
        let newTransactions = WiseCSVParser.parseCSV(at: url)
        guard !newTransactions.isEmpty else { return }

        for transaction in newTransactions {
            let exists = transactions.contains { existing in
                existing.date == transaction.date &&
                existing.name == transaction.name &&
                existing.amount == transaction.amount &&
                existing.type == transaction.type
            }
            if !exists {
                addTransaction(transaction)
            }
        }
    }

    // Convenience overload for importing multiple CSV files at once
    func importTransactions(fromCSV urls: [URL]) {
        urls.forEach { importTransactions(fromCSV: $0) }
    }

    // MARK: - Transfer Validation
    /// Validates that transfers moving FROM the Expenses account INTO the Wise account match.
    /// The category used for these transfers should be "Wise".
    /// - Parameter expensesAccount: The `ExpensesAccount` instance where outgoing transfers originate.
    /// - Returns: A tuple indicating validity and a user-friendly message.
    func validateTransfersFromExpenses(_ expensesAccount: ExpensesAccount) -> (isValid: Bool, message: String) {
        // Money leaving Expenses (debit) should equal money arriving in Wise (credit) under category "Wise".
        let wiseIncoming = creditsForCategory("Wise")
        let expensesOutgoing = expensesAccount.debitsForCategory("Wise")

        let difference = abs(wiseIncoming - expensesOutgoing)
        let isValid = difference < 1.0
        let message = isValid
            ? "✅ Expenses → Wise transfers match perfectly"
            : "⚠️ Expenses → Wise mismatch: ₡\(Int(difference).formatted()) difference"

        return (isValid, message)
    }
} 