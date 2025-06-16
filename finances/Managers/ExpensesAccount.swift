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
        let calendar = Calendar.current
        let currentDate = Date()
        var allTransactions: [Transaction] = []
        
        // Generate transactions for the last 8 months
        for monthOffset in 0...7 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            
            // Income (monthly salary + occasional extras)
            allTransactions.append(Transaction(name: "Salary", category: "Income", amount: Double.random(in: 195000...205000), type: .credit, date: calendar.date(byAdding: .day, value: -5, to: monthDate)!))
            
            if monthOffset < 3 && Bool.random() {
                allTransactions.append(Transaction(name: "Freelance Income", category: "Income", amount: Double.random(in: 40000...60000), type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -25...(-1)), to: monthDate)!))
            }
            
            if monthOffset % 3 == 0 {
                allTransactions.append(Transaction(name: "Investment Dividend", category: "Income", amount: Double.random(in: 12000...18000), type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -20...(-5)), to: monthDate)!))
            }
            
            // Monthly recurring expenses
            // Savings
            allTransactions.append(Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: Double.random(in: 45000...55000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -8...(-2)), to: monthDate)!))
            
            if Bool.random() {
                allTransactions.append(Transaction(name: "Emergency Fund Transfer", category: "Emergency Fund", amount: Double.random(in: 25000...40000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -15...(-3)), to: monthDate)!))
            }
            
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
            
            if monthOffset <= 2 {
                allTransactions.append(Transaction(name: "Adobe Creative Cloud", category: "Subscriptions", amount: 8500, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -20...(-1)), to: monthDate)!))
            }
            
            if monthOffset <= 0 {
                allTransactions.append(Transaction(name: "Amazon Prime", category: "Subscriptions", amount: 4200, type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -25...(-1)), to: monthDate)!))
            }
            
            // Transportation
            for _ in 0...Int.random(in: 2...5) {
                let transportTypes = [("Uber Ride", 2500.0...8000.0), ("Taxi Ride", 3000.0...6000.0), ("Parking Fee", 1000.0...4000.0)]
                let (name, range) = transportTypes.randomElement()!
                allTransactions.append(Transaction(name: name, category: "Transportation", amount: Double.random(in: range), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
            
            // Gas every 2 weeks
            for week in [1, 3] {
                allTransactions.append(Transaction(name: "Gasoline", category: "Transportation", amount: Double.random(in: 15000...22000), type: .debit, date: calendar.date(byAdding: .day, value: -(week * 7), to: monthDate)!))
            }
            
            // Monthly debt payments
            allTransactions.append(Transaction(name: "Car Loan Payment", category: "Debt", amount: Double.random(in: 10000...15000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -5...(-1)), to: monthDate)!))
            
            if monthOffset <= 4 {
                allTransactions.append(Transaction(name: "Credit Card Payment", category: "Debt", amount: Double.random(in: 35000...55000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -20...(-10)), to: monthDate)!))
            }
            
            if monthOffset <= 6 {
                allTransactions.append(Transaction(name: "Student Loan Payment", category: "Debt", amount: Double.random(in: 28000...35000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-20)), to: monthDate)!))
            }
            
            // Monthly utilities
            allTransactions.append(Transaction(name: "Electricity Bill - ICE", category: "Utilities", amount: Double.random(in: 18000...28000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -15...(-5)), to: monthDate)!))
            allTransactions.append(Transaction(name: "Water Bill - AyA", category: "Utilities", amount: Double.random(in: 6000...12000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -18...(-8)), to: monthDate)!))
            allTransactions.append(Transaction(name: "Internet - Kolbi", category: "Utilities", amount: Double.random(in: 16000...22000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -12...(-2)), to: monthDate)!))
            allTransactions.append(Transaction(name: "Mobile Phone Bill", category: "Utilities", amount: Double.random(in: 10000...15000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -25...(-15)), to: monthDate)!))
            
            // Quarterly expenses
            if monthOffset % 3 == 0 {
                allTransactions.append(Transaction(name: "Car Insurance", category: "Transportation", amount: Double.random(in: 25000...35000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -20...(-5)), to: monthDate)!))
                allTransactions.append(Transaction(name: "Health Insurance", category: "Healthcare", amount: Double.random(in: 30000...40000), type: .debit, date: calendar.date(byAdding: .day, value: Int.random(in: -25...(-10)), to: monthDate)!))
            }
            
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

