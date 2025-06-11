import SwiftUI
import Foundation
import Combine

class ExpensesAccount: ObservableObject, Account {
    @Published var biweeklyPeriods: [BiweeklyPeriod] = []
    
    static let shared = ExpensesAccount()

    @Published var budget: [BudgetCategory] = [
        BudgetCategory(name: "Debt", budget: 90000),
        BudgetCategory(name: "Subscriptions", budget: 50000),
        BudgetCategory(name: "Transportation", budget: 40000),
        BudgetCategory(name: "Savings", budget: 100000),
        BudgetCategory(name: "Misc", budget: 65000),
    ]
    
    var totalBudget: Double {
        budget.reduce(0) { $0 + $1.budget }
    }

    func budgetForCategory(_ categoryName: String) -> Double {
        budget.first { $0.name == categoryName }?.budget ?? 0
    }   
    
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
            // May 1-15, 2024

            // Debits (Expenses)
            Transaction(name: "Car Payment", category: "Debt", amount: 90000, type: .debit, date: may1),
            Transaction(name: "Savings Transfer", category: "Savings", amount: 100000, type: .debit, date: may1),
            Transaction(name: "Gas", category: "Transportation", amount: 35000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: may1)!),
            Transaction(name: "Seguro BAC", category: "Subscriptions", amount: 1800, type: .debit, date: calendar.date(byAdding: .day, value: 5, to: may1)!),
            Transaction(name: "ChatGPT", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: may1)!),
            Transaction(name: "Cursor", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: may1)!),
            Transaction(name: "IPTV", category: "Subscriptions", amount: 9000, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: may1)!),
            Transaction(name: "Uber One", category: "Subscriptions", amount: 2999, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: may1)!),
            Transaction(name: "KFC", category: "Misc", amount: 3500, type: .debit, date: calendar.date(byAdding: .day, value: 7, to: may1)!),
            Transaction(name: "Coffee", category: "Misc", amount: 4000, type: .debit, date: calendar.date(byAdding: .day, value: 8, to: may1)!),
            Transaction(name: "Movie Tickets", category: "Misc", amount: 12000, type: .debit, date: calendar.date(byAdding: .day, value: 10, to: may1)!),
            Transaction(name: "Books", category: "Misc", amount: 15000, type: .debit, date: calendar.date(byAdding: .day, value: 12, to: may1)!),
            
            // Credits (Income/Deposits)
            Transaction(name: "Salary", category: "Income", amount: 200000, type: .credit, date: may1),
            Transaction(name: "Mesada", category: "Income", amount: 140000, type: .credit, date: calendar.date(byAdding: .day, value: 14, to: may1)!),

        ]

        let q2MayTransactions = [
            // May 16-31, 2024

            // Debits (Expenses)
            Transaction(name: "Car Payment", category: "Debt", amount: 90000, type: .debit, date: may15),
            Transaction(name: "Savings Transfer", category: "Savings", amount: 100000, type: .debit, date: may15),
            Transaction(name: "Gas", category: "Transportation", amount: 35000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: may15)!),
            Transaction(name: "Seguro BAC", category: "Subscriptions", amount: 1800, type: .debit, date: calendar.date(byAdding: .day, value: 5, to: may15)!),
            Transaction(name: "ChatGPT", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: may15)!),
            Transaction(name: "Cursor", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: may15)!),
            Transaction(name: "IPTV", category: "Subscriptions", amount: 9000, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: may15)!),
            Transaction(name: "Uber One", category: "Subscriptions", amount: 2999, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: may15)!),
            Transaction(name: "KFC", category: "Misc", amount: 3500, type: .debit, date: calendar.date(byAdding: .day, value: 7, to: may15)!),
            Transaction(name: "Coffee", category: "Misc", amount: 4000, type: .debit, date: calendar.date(byAdding: .day, value: 8, to: may15)!),
            Transaction(name: "Movie Tickets", category: "Misc", amount: 12000, type: .debit, date: calendar.date(byAdding: .day, value: 10, to: may15)!),
            Transaction(name: "Books", category: "Misc", amount: 15000, type: .debit, date: calendar.date(byAdding: .day, value: 12, to: may15)!),
            
            // Credits (Income/Deposits)
            Transaction(name: "Salary", category: "Income", amount: 200000, type: .credit, date: may15),
            Transaction(name: "Mesada", category: "Income", amount: 140000, type: .credit, date: calendar.date(byAdding: .day, value: 14, to: may15)!),
        ]
        
        let q1JuneTransactions = [

            // June 1-15, 2024

            // Debits (Expenses)
            Transaction(name: "Car Payment", category: "Debt", amount: 90000, type: .debit, date: june1),
            Transaction(name: "Savings Transfer", category: "Savings", amount: 100000, type: .debit, date: june1),
            Transaction(name: "Gas", category: "Transportation", amount: 40000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june1)!),
            Transaction(name: "Seguro BAC", category: "Subscriptions", amount: 1800, type: .debit, date: calendar.date(byAdding: .day, value: 5, to: june1)!),
            Transaction(name: "ChatGPT", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: june1)!),
            Transaction(name: "Cursor", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: june1)!),
            Transaction(name: "IPTV", category: "Subscriptions", amount: 9000, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: june1)!),
            Transaction(name: "Uber One", category: "Subscriptions", amount: 2999, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: june1)!),
            Transaction(name: "Admin Compass", category: "Subscriptions", amount: 2500, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june1)!),
            Transaction(name: "Apple One", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june1)!),
            Transaction(name: "Restaurants", category: "Misc", amount: 8000, type: .debit, date: calendar.date(byAdding: .day, value: 6, to: june1)!),
            Transaction(name: "Coffee", category: "Misc", amount: 3000, type: .debit, date: calendar.date(byAdding: .day, value: 7, to: june1)!),
            Transaction(name: "Haircut", category: "Misc", amount: 15000, type: .debit, date: calendar.date(byAdding: .day, value: 9, to: june1)!),
            Transaction(name: "Groceries", category: "Misc", amount: 18000, type: .debit, date: calendar.date(byAdding: .day, value: 11, to: june1)!),
            
            // Credits (Income/Deposits)
            Transaction(name: "Salary", category: "Income", amount: 200000, type: .credit, date: june1),
            Transaction(name: "Mesada", category: "Income", amount: 140000, type: .credit, date: calendar.date(byAdding: .day, value: 14, to: june1)!)
        ]

        let q2JuneTransactions = [

            // June 16-30, 2024

            // Debits (Expenses)
            Transaction(name: "Car Payment", category: "Debt", amount: 90000, type: .debit, date: june15),
            Transaction(name: "Savings Transfer", category: "Savings", amount: 100000, type: .debit, date: june15),
            Transaction(name: "Gas", category: "Transportation", amount: 40000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june15)!),
            Transaction(name: "Seguro BAC", category: "Subscriptions", amount: 1800, type: .debit, date: calendar.date(byAdding: .day, value: 5, to: june15)!),
            Transaction(name: "ChatGPT", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: june15)!),
            Transaction(name: "Cursor", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 1, to: june15)!),
            Transaction(name: "IPTV", category: "Subscriptions", amount: 9000, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: june15)!),
            Transaction(name: "Uber One", category: "Subscriptions", amount: 2999, type: .debit, date: calendar.date(byAdding: .day, value: 2, to: june15)!),
            Transaction(name: "Admin Compass", category: "Subscriptions", amount: 2500, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june15)!),
            Transaction(name: "Apple One", category: "Subscriptions", amount: 10000, type: .debit, date: calendar.date(byAdding: .day, value: 3, to: june15)!),
            Transaction(name: "Restaurants", category: "Misc", amount: 8000, type: .debit, date: calendar.date(byAdding: .day, value: 6, to: june15)!),

            // Credits (Income/Deposits)
            Transaction(name: "Salary", category: "Income", amount: 200000, type: .credit, date: june15),
            Transaction(name: "Mesada", category: "Income", amount: 140000, type: .credit, date: calendar.date(byAdding: .day, value: 14, to: june15)!),
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
}
