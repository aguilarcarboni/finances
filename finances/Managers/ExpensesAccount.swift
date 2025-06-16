import SwiftUI
import Foundation
import Combine

class ExpensesAccount: ObservableObject, Account {
    @Published var transactions: [Transaction] = []
    
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
    
    // MARK: - Financial Analysis Methods
    var budgetUtilization: Double {
        guard totalBudget > 0 else { return 0 }
        return totalDebits / totalBudget
    }
    
    var budgetUtilizationPercentage: Double {
        budgetUtilization * 100
    }
    
    var remainingBudget: Double {
        max(totalBudget - totalDebits, 0)
    }
    
    var isOverBudget: Bool {
        totalDebits > totalBudget
    }
    
    var budgetOverrun: Double {
        max(totalDebits - totalBudget, 0)
    }
    
    func categoryBudgetUtilization(_ categoryName: String) -> Double {
        let categoryBudget = budgetForCategory(categoryName)
        let categorySpent = debitsForCategory(categoryName)
        guard categoryBudget > 0 else { return 0 }
        return categorySpent / categoryBudget
    }
    
    func categoryBudgetUtilizationPercentage(_ categoryName: String) -> Double {
        categoryBudgetUtilization(categoryName) * 100
    }
    
    func categoryRemainingBudget(_ categoryName: String) -> Double {
        let categoryBudget = budgetForCategory(categoryName)
        let categorySpent = debitsForCategory(categoryName)
        return max(categoryBudget - categorySpent, 0)
    }
    
    func isCategoryOverBudget(_ categoryName: String) -> Bool {
        let categoryBudget = budgetForCategory(categoryName)
        let categorySpent = debitsForCategory(categoryName)
        return categorySpent > categoryBudget
    }
    
    func categoryBudgetOverrun(_ categoryName: String) -> Double {
        let categoryBudget = budgetForCategory(categoryName)
        let categorySpent = debitsForCategory(categoryName)
        return max(categorySpent - categoryBudget, 0)
    }
    
    var topSpendingCategories: [(category: String, amount: Double, percentage: Double)] {
        let categorySummary = getCategorySummary()
        let totalSpent = totalDebits
        
        return categorySummary
            .filter { $0.debits > 0 }
            .map { (category: $0.category, amount: $0.debits, percentage: totalSpent > 0 ? ($0.debits / totalSpent) * 100 : 0) }
            .sorted { $0.amount > $1.amount }
    }
    
    var budgetHealthScore: Double {
        let overBudgetCategories = budget.filter { isCategoryOverBudget($0.name) }.count
        let totalCategories = budget.count
        guard totalCategories > 0 else { return 1.0 }
        
        let categoryScore = Double(totalCategories - overBudgetCategories) / Double(totalCategories)
        let utilizationScore = min(1.0, max(0.0, 1.0 - (budgetUtilization - 0.8) / 0.2)) // Optimal at 80% utilization
        
        return (categoryScore + utilizationScore) / 2.0
    }
    
    var budgetHealthScorePercentage: Double {
        budgetHealthScore * 100
    }
    
    // MARK: - Income Analysis
    var averageIncomePerPeriod: Double {
        // Calculate average income per month (30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCredits = totalCreditsForDateRange(from: thirtyDaysAgo, to: Date())
        return recentCredits
    }
    
    var averageExpensesPerPeriod: Double {
        // Calculate average expenses per month (30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentDebits = totalDebitsForDateRange(from: thirtyDaysAgo, to: Date())
        return recentDebits
    }
    
    var savingsRate: Double {
        guard totalCredits > 0 else { return 0 }
        return netBalance / totalCredits
    }
    
    var savingsRatePercentage: Double {
        savingsRate * 100
    }
    
    var expenseRatio: Double {
        guard totalCredits > 0 else { return 0 }
        return totalDebits / totalCredits
    }
    
    var expenseRatioPercentage: Double {
        expenseRatio * 100
    }
    
    // MARK: - Trend Analysis
    func getSpendingTrend() -> [(period: String, amount: Double)] {
        // Get spending by month for the last 12 months
        var result: [(period: String, amount: Double)] = []
        let calendar = Calendar.current
        
        for i in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let monthTransactions = transactionsForMonth(monthDate)
            let monthDebits = monthTransactions.filter { $0.type == .debit }.reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            result.append((period: formatter.string(from: monthDate), amount: monthDebits))
        }
        
        return result.reversed() // Most recent last
    }
    
    func getIncomeTrend() -> [(period: String, amount: Double)] {
        // Get income by month for the last 12 months
        var result: [(period: String, amount: Double)] = []
        let calendar = Calendar.current
        
        for i in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let monthTransactions = transactionsForMonth(monthDate)
            let monthCredits = monthTransactions.filter { $0.type == .credit }.reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            result.append((period: formatter.string(from: monthDate), amount: monthCredits))
        }
        
        return result.reversed() // Most recent last
    }
    
    func getCategoryTrend(for categoryName: String) -> [(period: String, amount: Double)] {
        // Get category spending by month for the last 12 months
        var result: [(period: String, amount: Double)] = []
        let calendar = Calendar.current
        
        for i in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let monthTransactions = transactionsForMonth(monthDate)
            let categoryAmount = monthTransactions
                .filter { $0.category == categoryName && $0.type == .debit }
                .reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            result.append((period: formatter.string(from: monthDate), amount: categoryAmount))
        }
        
        return result.reversed() // Most recent last
    }
    
    // MARK: - Budget Management
    func updateBudget(for categoryName: String, newBudget: Double) {
        if let index = budget.firstIndex(where: { $0.name == categoryName }) {
            budget[index] = BudgetCategory(name: categoryName, budget: newBudget)
        }
    }
    
    func addBudgetCategory(_ category: BudgetCategory) {
        if !budget.contains(where: { $0.name == category.name }) {
            budget.append(category)
        }
    }
    
    func removeBudgetCategory(_ categoryName: String) {
        budget.removeAll { $0.name == categoryName }
    }
    
    private init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Create calendar and date components
        let calendar = Calendar.current
        let june15 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let june16 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 16))!
        let june17 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 17))!
        let june18 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 18))!
        let june19 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 19))!
        let june20 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 20))!
        let june21 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 21))!
        
        transactions = [
            Transaction(name: "Salary", category: "Income", amount: 198000, type: .credit, date: june15),
            Transaction(name: "BASIS GOURMET SAN J", category: "Misc", amount: 800, type: .debit, date: june16),
            Transaction(name: "WALMART ESCAZU", category: "Misc", amount: 3950, type: .debit, date: june17),
            Transaction(name: "Mesada", category: "Income", amount: 80000, type: .credit, date: june18),
            Transaction(name: "MCDONALD'S ESCAZU", category: "Misc", amount: 2690, type: .debit, date: june19),
            Transaction(name: "WALMART ESCAZU", category: "Misc", amount: 1617, type: .debit, date: june20),
            Transaction(name: "WALMART ESCAZU", category: "Misc", amount: 2650, type: .debit, date: june21),
            Transaction(name: "PARQUEO AVENIDA ESC", category: "Transportation", amount: 4000, type: .debit, date: june21),
        ]
        
        // Sort transactions by date (most recent first)
        transactions.sort { $0.date > $1.date }
    }
    
    // MARK: - Account Protocol Implementation
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        // Keep transactions sorted by date (most recent first)
        transactions.sort { $0.date > $1.date }
    }
    
    func removeTransaction(with id: UUID) {
        transactions.removeAll { $0.id == id }
    }
}
