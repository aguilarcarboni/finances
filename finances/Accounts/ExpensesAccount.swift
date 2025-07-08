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
    
    // MARK: - Data Properties
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
    
    func debitsForCategory(_ categoryName: String) -> Double {
        debits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }
    
    func creditsForCategory(_ categoryName: String) -> Double {
        credits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }

    var topSpendingCategories: [(category: String, amount: Double, percentage: Double)] {
        let categorySummary = getCategorySummary()
        let totalSpent = totalDebits
        
        return categorySummary
            .filter { $0.debits > 0 }
            .map { (category: $0.category, amount: $0.debits, percentage: totalSpent > 0 ? ($0.debits / totalSpent) * 100 : 0) }
            .sorted { $0.amount > $1.amount }
    }
    
    func getCategorySummary() -> [(category: String, debits: Double, credits: Double, netBalance: Double)] {
        let categories = Set(transactions.map { $0.category })
        
        return categories.map { category in
            let categoryDebits = debitsForCategory(category)
            let categoryCredits = creditsForCategory(category)
            return (
                category: category,
                debits: categoryDebits,
                credits: categoryCredits,
                netBalance: categoryCredits - categoryDebits
            )
        }.sorted { $0.category < $1.category }
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
    
    // MARK: - Asset Revenue Management
    func addAssetRevenue(_ transaction: Transaction) {
        addTransaction(transaction)
    }
    
    func getAssetRevenueForMonth(assetName: String, month: Date) -> Double {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: month)
        
        return transactions
            .filter { transaction in
                transaction.type == .credit &&
                transaction.category == "Asset Income" &&
                transaction.name.contains(assetName) &&
                (monthInterval?.contains(transaction.date) ?? false)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getTotalAssetRevenue(assetName: String) -> Double {
        return transactions
            .filter { transaction in
                transaction.type == .credit &&
                transaction.category == "Asset Income" &&
                transaction.name.contains(assetName)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalAssetRevenue: Double {
        return transactions
            .filter { transaction in
                transaction.type == .credit &&
                transaction.category == "Asset Income"
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var assetRevenueByAsset: [(assetName: String, totalRevenue: Double)] {
        let assetTransactions = transactions.filter { 
            $0.type == .credit && $0.category == "Asset Income" 
        }
        
        var assetRevenues: [String: Double] = [:]
        
        for transaction in assetTransactions {
            // Extract asset name from transaction name (assumes format "AssetName Revenue")
            let assetName = transaction.name.replacingOccurrences(of: " Revenue", with: "")
            assetRevenues[assetName, default: 0] += transaction.amount
        }
        
        return assetRevenues.map { (assetName: $0.key, totalRevenue: $0.value) }
            .sorted { $0.totalRevenue > $1.totalRevenue }
    }
    
    func getAssetRevenueHistory(assetName: String) -> [(month: String, revenue: Double)] {
        var result: [(month: String, revenue: Double)] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        // Get revenue for the last 12 months
        for i in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let monthString = formatter.string(from: monthDate)
            let revenue = getAssetRevenueForMonth(assetName: assetName, month: monthDate)
            
            result.append((month: monthString, revenue: revenue))
        }
        
        return result.reversed()
    }
    
    private init() {
        // Data is loaded via CSV import (ExpensesCSVImportManager)
    }
    
    // Removed mock data generation; transactions are now supplied exclusively by CSV import.
    
    // MARK: - Account Protocol Implementation
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        // Keep transactions sorted by date (most recent first)
        transactions.sort { $0.date > $1.date }
    }

    // NEW: Import transactions from a CSV file located at the given URL.
    func importTransactions(fromCSV url: URL) {
        let newTransactions = ExpensesCSVParser.parseCSV(at: url)
        guard !newTransactions.isEmpty else { return }
        // Avoid duplicates by checking for same date, name, amount, and type
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

    // Convenience overload to handle multiple URLs at once.
    func importTransactions(fromCSV urls: [URL]) {
        urls.forEach { importTransactions(fromCSV: $0) }
    }
    
    func removeTransaction(with id: UUID) {
        transactions.removeAll { $0.id == id }
    }
}

