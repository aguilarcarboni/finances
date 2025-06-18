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
        setupMockData()
    }
    
    private func setupMockData() {
        let calendar = Calendar.current
        let currentDate = Date()
        var allTransactions: [Transaction] = []
        
        // Generate transactions for the last 8 months
        for monthOffset in 0...7 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            
            // Income (monthly salary + occasional extras)
            allTransactions.append(Transaction(name: "Salary", category: "Income", amount: Double.random(in: 450000...500000), type: .credit, date: calendar.date(byAdding: .day, value: -5, to: monthDate)!))
            
            // Monthly recurring expenses
            // Savings
            allTransactions.append(Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 100000, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -8...(-2)), to: monthDate)!))
            
            // Groceries (3-4 times per month)
            let groceryStores = ["Walmart Escazu", "AutoMercado", "Maxi Pali", "Fresh Market"]
            for _ in 0...Int.random(in: 2...4) {
                allTransactions.append(Transaction(name: "Groceries - \(groceryStores.randomElement()!)", category: "Groceries", amount: Double.random(in: 8000...25000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Dining (variable frequency)
            let restaurants = ["McDonald's", "Starbucks", "Olive Garden", "Pizza Hut", "Coffee Shop", "Subway", "KFC", "Burger King"]
            for _ in 0...Int.random(in: 3...8) {
                allTransactions.append(Transaction(name: restaurants.randomElement()!, category: "Dining", amount: Double.random(in: 1500...15000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Monthly subscriptions
            if monthOffset <= 1 {
                allTransactions.append(Transaction(name: "Netflix Subscription", category: "Subscriptions", amount: 3900, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -10...(-1)), to: monthDate)!))
                allTransactions.append(Transaction(name: "Spotify Subscription", category: "Subscriptions", amount: 3000, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -12...(-1)), to: monthDate)!))
                allTransactions.append(Transaction(name: "Gym Membership", category: "Subscriptions", amount: 15000, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -15...(-1)), to: monthDate)!))
            }
            
            // Gas every 2 weeks
            for week in [1, 3] {
                allTransactions.append(Transaction(name: "Gasoline", category: "Transportation", amount: Double.random(in: 20000...25000), type: .debit, date: calendar.date(byAdding: .day, value: -(week * 7), to: monthDate)!))
            }
            
            // Monthly debt payments
            allTransactions.append(Transaction(name: "Car Loan Payment", category: "Debt", amount: Double.random(in: 10000...15000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -5...(-1)), to: monthDate)!))
            
            // Occasional expenses
            if Bool.random() && monthOffset <= 5 {
                let entertainmentOptions = [("Cinema Tickets", 5000.0...8000.0), ("Concert Tickets", 20000.0...35000.0), ("Theater Show", 15000.0...25000.0)]
                let (name, range) = entertainmentOptions.randomElement()!
                allTransactions.append(Transaction(name: name, category: "Entertainment", amount: Double.random(in: range), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            if Bool.random() {
                let healthcareOptions = [("Doctor Appointment", 20000.0...30000.0), ("Pharmacy - Medications", 6000.0...12000.0), ("Dental Cleaning", 15000.0...25000.0)]
                let (name, range) = healthcareOptions.randomElement()!
                allTransactions.append(Transaction(name: name, category: "Healthcare", amount: Double.random(in: range), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Shopping (variable)
            if Bool.random() {
                let shoppingOptions = [("Amazon Purchase", 10000.0...20000.0), ("Clothing Store", 20000.0...50000.0), ("Electronics", 30000.0...80000.0), ("Household Items", 8000.0...18000.0)]
                let (name, range) = shoppingOptions.randomElement()!
                allTransactions.append(Transaction(name: name, category: "Shopping", amount: Double.random(in: range), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Miscellaneous
            let miscOptions = [("Haircut", 6000.0...10000.0), ("Pet Supplies", 8000.0...18000.0), ("Gift", 8000.0...25000.0), ("Bank Fees", 1500.0...3500.0)]
            if Bool.random() {
                let (name, range) = miscOptions.randomElement()!
                allTransactions.append(Transaction(name: name, category: "Misc", amount: Double.random(in: range), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Special one-time events
            if monthOffset == 2 {
                allTransactions.append(Transaction(name: "Tax Refund Savings", category: "Savings", amount: 85000, type: .debit, date: calendar.date(byAdding: .day, value: -10, to: monthDate)!))
            }
            
            if monthOffset == 4 {
                allTransactions.append(Transaction(name: "Car Maintenance", category: "Transportation", amount: 45000, type: .debit, date: calendar.date(byAdding: .day, value: -12, to: monthDate)!))
            }
            
            if monthOffset == 6 {
                allTransactions.append(Transaction(name: "Vacation Expenses", category: "Entertainment", amount: 120000, type: .debit, date: calendar.date(byAdding: .day, value: -8, to: monthDate)!))
            }
        }
        
        transactions = allTransactions
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

