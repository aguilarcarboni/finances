import SwiftUI
import Foundation
import Combine

struct BudgetCategory: Identifiable {
    let id = UUID()
    let name: String
    let budget: Double
}

protocol Account: ObservableObject {
    var transactions: [Transaction] { get set }
    var budget: [BudgetCategory] { get set }
    var totalBudget: Double { get }
    var debits: [Transaction] { get }
    var credits: [Transaction] { get }
    var totalDebits: Double { get }
    var totalCredits: Double { get }
    var netBalance: Double { get }
    
    func budgetForCategory(_ categoryName: String) -> Double
    func transactionsForCategory(_ categoryName: String) -> [Transaction]
    func debitsForCategory(_ categoryName: String) -> Double
    func creditsForCategory(_ categoryName: String) -> Double
    func netForCategory(_ categoryName: String) -> Double
    func addTransaction(_ transaction: Transaction)
    func removeTransaction(with id: UUID)
    func getAccountSummary() -> (totalDebits: Double, totalCredits: Double, netBalance: Double)
    func getCategorySummary() -> [(category: String, debits: Double, credits: Double, net: Double)]
    
    // Date-based filtering methods
    func transactionsForDateRange(from startDate: Date, to endDate: Date) -> [Transaction]
    func transactionsForMonth(_ date: Date) -> [Transaction]
    func transactionsForWeek(_ date: Date) -> [Transaction]
    func transactionsForCurrentMonth() -> [Transaction]
    func transactionsForCurrentWeek() -> [Transaction]
    func transactionsForLast30Days() -> [Transaction]
}

// MARK: - Default implementations
extension Account {
    var totalBudget: Double {
        budget.reduce(0) { $0 + $1.budget }
    }
    
    func budgetForCategory(_ categoryName: String) -> Double {
        budget.first { $0.name == categoryName }?.budget ?? 0
    }
    
    var debits: [Transaction] {
        transactions.filter { $0.type == .debit }
    }
    
    var credits: [Transaction] {
        transactions.filter { $0.type == .credit }
    }
    
    var totalDebits: Double {
        debits.reduce(0) { $0 + $1.amount }
    }
    
    var totalCredits: Double {
        credits.reduce(0) { $0 + $1.amount }
    }
    
    var netBalance: Double {
        totalCredits - totalDebits
    }
    
    func transactionsForCategory(_ categoryName: String) -> [Transaction] {
        transactions.filter { $0.category == categoryName }
    }
    
    func debitsForCategory(_ categoryName: String) -> Double {
        transactions
            .filter { $0.category == categoryName && $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }
    
    func creditsForCategory(_ categoryName: String) -> Double {
        transactions
            .filter { $0.category == categoryName && $0.type == .credit }
            .reduce(0) { $0 + $1.amount }
    }
    
    func netForCategory(_ categoryName: String) -> Double {
        creditsForCategory(categoryName) - debitsForCategory(categoryName)
    }
    
    func getAccountSummary() -> (totalDebits: Double, totalCredits: Double, netBalance: Double) {
        let allDebits = totalDebits
        let allCredits = totalCredits
        let netBalance = allCredits - allDebits
        
        return (allDebits, allCredits, netBalance)
    }
    
    func getCategorySummary() -> [(category: String, debits: Double, credits: Double, net: Double)] {
        var categoryTotals: [String: (debits: Double, credits: Double)] = [:]
        
        for transaction in transactions {
            if categoryTotals[transaction.category] == nil {
                categoryTotals[transaction.category] = (0, 0)
            }
            
            if transaction.type == .debit {
                categoryTotals[transaction.category]?.debits += transaction.amount
            } else {
                categoryTotals[transaction.category]?.credits += transaction.amount
            }
        }
        
        return categoryTotals.map { (category, totals) in
            (category: category, debits: totals.debits, credits: totals.credits, net: totals.credits - totals.debits)
        }.sorted { $0.category < $1.category }
    }
    
    // MARK: - Date-based filtering implementations
    func transactionsForDateRange(from startDate: Date, to endDate: Date) -> [Transaction] {
        return transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }.sorted { $0.date > $1.date } // Most recent first
    }
    
    func transactionsForMonth(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        return transactionsForDateRange(from: startOfMonth, to: endOfMonth)
    }
    
    func transactionsForWeek(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.end ?? date
        return transactionsForDateRange(from: startOfWeek, to: endOfWeek)
    }
    
    func transactionsForCurrentMonth() -> [Transaction] {
        return transactionsForMonth(Date())
    }
    
    func transactionsForCurrentWeek() -> [Transaction] {
        return transactionsForWeek(Date())
    }
    
    func transactionsForLast30Days() -> [Transaction] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return transactionsForDateRange(from: thirtyDaysAgo, to: Date())
    }
    
    // Helper methods for date-based calculations
    func totalDebitsForDateRange(from startDate: Date, to endDate: Date) -> Double {
        return transactionsForDateRange(from: startDate, to: endDate)
            .filter { $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }
    
    func totalCreditsForDateRange(from startDate: Date, to endDate: Date) -> Double {
        return transactionsForDateRange(from: startDate, to: endDate)
            .filter { $0.type == .credit }
            .reduce(0) { $0 + $1.amount }
    }
    
    func netBalanceForDateRange(from startDate: Date, to endDate: Date) -> Double {
        return totalCreditsForDateRange(from: startDate, to: endDate) - totalDebitsForDateRange(from: startDate, to: endDate)
    }
} 