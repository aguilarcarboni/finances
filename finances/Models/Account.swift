import SwiftUI
import Foundation
import Combine

protocol Account: ObservableObject {
    var biweeklyPeriods: [BiweeklyPeriod] { get set }
    var budget: [BudgetCategory] { get set }
    var totalBudget: Double { get }
    var currentPeriod: BiweeklyPeriod? { get }
    var transactions: [Transaction] { get }
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
    func addPeriod(_ period: BiweeklyPeriod)
    func getCurrentBiweeklyPeriod() -> (start: Date, end: Date)
    func addTransaction(_ transaction: Transaction, to periodId: UUID?)
    func removeTransaction(with id: UUID, from periodId: UUID?)
    func validateDoubleEntry(for periodId: UUID?) -> Bool
    func getAccountSummary() -> (totalDebits: Double, totalCredits: Double, netBalance: Double)
    func getCategorySummary() -> [(category: String, debits: Double, credits: Double, net: Double)]
}

// MARK: - Default implementations
extension Account {
    var totalBudget: Double {
        budget.reduce(0) { $0 + $1.budget }
    }
    
    func budgetForCategory(_ categoryName: String) -> Double {
        budget.first { $0.name == categoryName }?.budget ?? 0
    }
    
    var currentPeriod: BiweeklyPeriod? {
        let today = Date()
        return biweeklyPeriods.first { period in
            today >= period.startDate && today <= period.endDate
        } ?? biweeklyPeriods.last
    }
    
    var transactions: [Transaction] {
        currentPeriod?.transactions ?? []
    }
    
    var debits: [Transaction] {
        currentPeriod?.debits ?? []
    }
    
    var credits: [Transaction] {
        currentPeriod?.credits ?? []
    }
    
    var totalDebits: Double {
        currentPeriod?.totalDebits ?? 0
    }
    
    var totalCredits: Double {
        currentPeriod?.totalCredits ?? 0
    }
    
    var netBalance: Double {
        currentPeriod?.netBalance ?? 0
    }
    
    func transactionsForCategory(_ categoryName: String) -> [Transaction] {
        currentPeriod?.transactionsForCategory(categoryName) ?? []
    }
    
    func debitsForCategory(_ categoryName: String) -> Double {
        currentPeriod?.debitsForCategory(categoryName) ?? 0
    }
    
    func creditsForCategory(_ categoryName: String) -> Double {
        currentPeriod?.creditsForCategory(categoryName) ?? 0
    }
    
    func netForCategory(_ categoryName: String) -> Double {
        currentPeriod?.netForCategory(categoryName) ?? 0
    }
    
    func addPeriod(_ period: BiweeklyPeriod) {
        biweeklyPeriods.append(period)
        biweeklyPeriods.sort { $0.startDate < $1.startDate }
    }
    
    func getCurrentBiweeklyPeriod() -> (start: Date, end: Date) {
        let today = Date()
        let calendar = Calendar.current
        
        let dayOfMonth = calendar.component(.day, from: today)
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        
        if dayOfMonth <= 15 {
            let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let endDate = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
            return (startDate, endDate)
        } else {
            let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 16))!
            let endDate = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0))!
            return (startDate, endDate)
        }
    }
    
    func validateDoubleEntry(for periodId: UUID? = nil) -> Bool {
        let period = periodId != nil 
            ? biweeklyPeriods.first { $0.id == periodId }
            : currentPeriod
        
        guard let period = period else { return false }
        return period.totalDebits > 0 && period.totalCredits > 0
    }
    
    func getAccountSummary() -> (totalDebits: Double, totalCredits: Double, netBalance: Double) {
        let allDebits = biweeklyPeriods.reduce(0) { $0 + $1.totalDebits }
        let allCredits = biweeklyPeriods.reduce(0) { $0 + $1.totalCredits }
        let netBalance = allCredits - allDebits
        
        return (allDebits, allCredits, netBalance)
    }
    
    func getCategorySummary() -> [(category: String, debits: Double, credits: Double, net: Double)] {
        var categoryTotals: [String: (debits: Double, credits: Double)] = [:]
        
        for period in biweeklyPeriods {
            for transaction in period.transactions {
                if categoryTotals[transaction.category] == nil {
                    categoryTotals[transaction.category] = (0, 0)
                }
                
                if transaction.type == .debit {
                    categoryTotals[transaction.category]?.debits += transaction.amount
                } else {
                    categoryTotals[transaction.category]?.credits += transaction.amount
                }
            }
        }
        
        return categoryTotals.map { (category, totals) in
            (category: category, debits: totals.debits, credits: totals.credits, net: totals.credits - totals.debits)
        }.sorted { $0.category < $1.category }
    }
} 