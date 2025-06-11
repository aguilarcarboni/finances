import SwiftUI
import Foundation

struct BiweeklyPeriod: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let transactions: [Transaction]
    
    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // MARK: - Transaction Filtering
    var debits: [Transaction] {
        transactions.filter { $0.type == .debit }
    }
    
    var credits: [Transaction] {
        transactions.filter { $0.type == .credit }
    }
    
    // MARK: - Amount Calculations
    var totalDebits: Double {
        debits.reduce(0) { $0 + $1.amount }
    }
    
    var totalCredits: Double {
        credits.reduce(0) { $0 + $1.amount }
    }
    
    var netBalance: Double {
        totalCredits - totalDebits
    }
    
    // MARK: - Category-based Methods
    func transactionsForCategory(_ categoryName: String) -> [Transaction] {
        transactions.filter { $0.category == categoryName }
    }
    
    func debitsForCategory(_ categoryName: String) -> Double {
        debits
            .filter { $0.category == categoryName }
            .reduce(0) { $0 + $1.amount }
    }
    
    func creditsForCategory(_ categoryName: String) -> Double {
        credits
            .filter { $0.category == categoryName }
            .reduce(0) { $0 + $1.amount }
    }
    
    func netForCategory(_ categoryName: String) -> Double {
        creditsForCategory(categoryName) - debitsForCategory(categoryName)
    }
} 