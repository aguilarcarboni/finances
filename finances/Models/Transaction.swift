import Foundation

enum TransactionType: String, CaseIterable {
    case debit = "Debit"
    case credit = "Credit"
}

struct Transaction: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let amount: Double
    let type: TransactionType
    let date: Date
    
    init(name: String, category: String, amount: Double, type: TransactionType, date: Date = Date()) {
        self.name = name
        self.category = category
        self.amount = amount
        self.type = type
        self.date = date
    }
    
    // Helper computed properties
    var isDebit: Bool {
        return type == .debit
    }
    
    var isCredit: Bool {
        return type == .credit
    }
    
    // For double-entry display purposes
    var displayAmount: Double {
        return amount
    }
    
    // For balance calculations (debits reduce account balance, credits increase it)
    var accountImpact: Double {
        switch type {
        case .debit:
            return -amount  // Debits reduce the account balance
        case .credit:
            return amount   // Credits increase the account balance
        }
    }
} 