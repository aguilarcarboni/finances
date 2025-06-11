import SwiftUI
import Foundation
import Combine

class SavingsAccount: ObservableObject, Account {
    @Published var biweeklyPeriods: [BiweeklyPeriod] = []
    
    static let shared = SavingsAccount()

    @Published var budget: [BudgetCategory] = [
        BudgetCategory(name: "Emergency Fund", budget: 50000),
        BudgetCategory(name: "Investment", budget: 80000),
        BudgetCategory(name: "Vacation Fund", budget: 30000),
        BudgetCategory(name: "Home Down Payment", budget: 40000),
        BudgetCategory(name: "Retirement", budget: 50000),
    ]
    
    private init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Create calendar and date components
        let calendar = Calendar.current
        
        let may1 = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1))!
        let may15 = calendar.date(from: DateComponents(year: 2024, month: 5, day: 15))!
        let may31 = calendar.date(from: DateComponents(year: 2024, month: 5, day: 31))!
        let june1 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let june15 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let june30 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 30))!

        
        let q1MayTransactions = [
            Transaction(name: "Transfer from Expenses", category: "Emergency Fund", amount: 100000, type: .credit, date: may15), // Matches ExpensesAccount debit
        ]

        let q2MayTransactions = [
            Transaction(name: "Transfer from Expenses", category: "Emergency Fund", amount: 100000, type: .credit, date: may31), // Matches ExpensesAccount debit
        ]

        let q1JuneTransactions = [
            Transaction(name: "Transfer from Expenses", category: "Emergency Fund", amount: 100000, type: .credit, date: june1), // Matches ExpensesAccount debit
        ]

        let q2JuneTransactions = [
            Transaction(name: "Transfer from Expenses", category: "Emergency Fund", amount: 100000, type: .credit, date: june15), // Matches ExpensesAccount debit
        ]
        
        biweeklyPeriods = [
            BiweeklyPeriod(startDate: may15, endDate: may31, transactions: q1MayTransactions),
            BiweeklyPeriod(startDate: may31, endDate: june1, transactions: q2MayTransactions),
            BiweeklyPeriod(startDate: june1, endDate: june15, transactions: q1JuneTransactions),
            BiweeklyPeriod(startDate: june15, endDate: june30, transactions: q2JuneTransactions),
        ]
    }
    
    // MARK: - Account Protocol Implementation
    func addTransaction(_ transaction: Transaction, to periodId: UUID? = nil) {
        if let periodId = periodId,
           let periodIndex = biweeklyPeriods.firstIndex(where: { $0.id == periodId }) {
            var updatedPeriod = biweeklyPeriods[periodIndex]
            var updatedTransactions = updatedPeriod.transactions
            updatedTransactions.append(transaction)
            updatedPeriod = BiweeklyPeriod(
                startDate: updatedPeriod.startDate,
                endDate: updatedPeriod.endDate,
                transactions: updatedTransactions
            )
            biweeklyPeriods[periodIndex] = updatedPeriod
        } else if var currentPeriod = currentPeriod,
                  let currentIndex = biweeklyPeriods.firstIndex(where: { $0.id == currentPeriod.id }) {
            var updatedTransactions = currentPeriod.transactions
            updatedTransactions.append(transaction)
            let updatedPeriod = BiweeklyPeriod(
                startDate: currentPeriod.startDate,
                endDate: currentPeriod.endDate,
                transactions: updatedTransactions
            )
            biweeklyPeriods[currentIndex] = updatedPeriod
        }
    }
    
    func removeTransaction(with id: UUID, from periodId: UUID? = nil) {
        if let periodId = periodId,
           let periodIndex = biweeklyPeriods.firstIndex(where: { $0.id == periodId }) {
            var updatedPeriod = biweeklyPeriods[periodIndex]
            var updatedTransactions = updatedPeriod.transactions
            updatedTransactions.removeAll { $0.id == id }
            updatedPeriod = BiweeklyPeriod(
                startDate: updatedPeriod.startDate,
                endDate: updatedPeriod.endDate,
                transactions: updatedTransactions
            )
            biweeklyPeriods[periodIndex] = updatedPeriod
        } else if var currentPeriod = currentPeriod,
                  let currentIndex = biweeklyPeriods.firstIndex(where: { $0.id == currentPeriod.id }) {
            var updatedTransactions = currentPeriod.transactions
            updatedTransactions.removeAll { $0.id == id }
            let updatedPeriod = BiweeklyPeriod(
                startDate: currentPeriod.startDate,
                endDate: currentPeriod.endDate,
                transactions: updatedTransactions
            )
            biweeklyPeriods[currentIndex] = updatedPeriod
        }
    }
    
    // MARK: - Savings-specific Methods
    var totalSavingsGrowth: Double {
        let summary = getAccountSummary()
        return summary.netBalance
    }
    
    var investmentPerformance: Double {
        netForCategory("Investment")
    }
    
    var emergencyFundBalance: Double {
        netForCategory("Emergency Fund")
    }
} 