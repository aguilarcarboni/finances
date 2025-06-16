import SwiftUI
import Foundation
import Combine

class SavingsAccount: ObservableObject, Account {
    
    @Published var transactions: [Transaction] = []
    
    static let shared = SavingsAccount()

    // MARK: - Savings-specific Configuration
    @Published var emergencyFundTarget: Double = 250_000
    
    // Percentage-based categories for excess savings (after emergency fund is met)
    @Published var savingsAllocationCategories: [(name: String, percentage: Double)] = [
        ("Trips", 0.5),
        ("Long term", 0.5)
    ]
    
    // Emergency fund is the only "budget" category - others are percentage-based
    @Published var budget: [BudgetCategory] = []
    
    // MARK: - Computed Financial Metrics
    var savingsGrowthData: [(month: String, balance: Double)] {
        // Get monthly balances for the last 12 months
        var result: [(month: String, balance: Double)] = []
        let calendar = Calendar.current
        var runningBalance: Double = 0
        
        // Sort transactions by date for cumulative calculation
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        
        // Get the last 12 months
        for i in stride(from: 11, through: 0, by: -1) {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let endOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            // Get transactions for this specific month only
            let monthTransactions = sortedTransactions.filter { transaction in
                transaction.date >= startOfMonth && transaction.date < endOfMonth
            }
            
            // Calculate net change for this month
            let monthChange = monthTransactions.reduce(0) { total, transaction in
                total + (transaction.type == .credit ? transaction.amount : -transaction.amount)
            }
            
            // Add to running balance
            runningBalance += monthChange
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            result.append((month: formatter.string(from: monthDate), balance: max(runningBalance, 0)))
        }
        
        return result
    }
    
    var totalSavingsBalance: Double {
        netBalance // This now comes from all transactions
    }
    
    var emergencyFundProgress: Double {
        min(totalSavingsBalance / emergencyFundTarget, 1.0)
    }
    
    var emergencyFundProgressPercentage: Double {
        emergencyFundProgress * 100
    }
    
    var emergencyFundRemaining: Double {
        max(emergencyFundTarget - totalSavingsBalance, 0)
    }
    
    var isEmergencyFundComplete: Bool {
        totalSavingsBalance >= emergencyFundTarget
    }
    
    var excessSavings: Double {
        max(totalSavingsBalance - emergencyFundTarget, 0)
    }
    
    var savingsCategories: [(name: String, amount: Double, percentage: Double)] {
        guard isEmergencyFundComplete && excessSavings > 0 else { return [] }
        
        return savingsAllocationCategories.map { (name, percentage) in
            let amount = excessSavings * percentage
            return (name: name, amount: amount, percentage: percentage)
        }
    }
    
    // MARK: - Emergency Fund Specific Properties
    var emergencyFundBalance: Double {
        min(totalSavingsBalance, emergencyFundTarget)
    }
    
    // MARK: - Account Protocol Implementation for Savings-specific Logic
    func budgetForCategory(_ categoryName: String) -> Double {
        if categoryName == "Emergency Fund" {
            return emergencyFundTarget
        }
        // For percentage-based categories, return the calculated amount
        return savingsCategories.first { $0.name == categoryName }?.amount ?? 0
    }
    
    private init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Create calendar and date components
        let calendar = Calendar.current
        
        // Add some mock savings transactions over the past few months
        let currentDate = Date()
        
        transactions = [
            // Recent savings transfers
            Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 50000, type: .credit, date: calendar.date(byAdding: .day, value: -5, to: currentDate)!),
            Transaction(name: "Emergency Fund Transfer", category: "Emergency Fund", amount: 30000, type: .credit, date: calendar.date(byAdding: .day, value: -15, to: currentDate)!),
            
            // Previous month
            Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 50000, type: .credit, date: calendar.date(byAdding: .month, value: -1, to: currentDate)!),
            Transaction(name: "Bonus Savings", category: "Savings", amount: 75000, type: .credit, date: calendar.date(byAdding: .day, value: -35, to: currentDate)!),
            
            // 2 months ago
            Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 50000, type: .credit, date: calendar.date(byAdding: .month, value: -2, to: currentDate)!),
            Transaction(name: "Emergency Fund Transfer", category: "Emergency Fund", amount: 40000, type: .credit, date: calendar.date(byAdding: .day, value: -55, to: currentDate)!),
            
            // 3 months ago
            Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 45000, type: .credit, date: calendar.date(byAdding: .month, value: -3, to: currentDate)!),
            
            // 4 months ago
            Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: 45000, type: .credit, date: calendar.date(byAdding: .month, value: -4, to: currentDate)!),
            Transaction(name: "Tax Refund Savings", category: "Savings", amount: 100000, type: .credit, date: calendar.date(byAdding: .day, value: -110, to: currentDate)!),
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
    
    // MARK: - Savings-specific Methods
    var totalSavingsGrowth: Double {
        let summary = getAccountSummary()
        return summary.netBalance
    }
    
    // MARK: - Transfer Validation
    func validateTransfersWithExpenses(_ expensesAccount: ExpensesAccount) -> (isValid: Bool, message: String) {
        let expensesSavingsTransfers = expensesAccount.debitsForCategory("Savings")
        let savingsIncomingTransfers = creditsForCategory("Savings") // All savings come in as generic "Savings"
        
        let isValid = abs(expensesSavingsTransfers - savingsIncomingTransfers) < 1.0 // Allow for rounding
        let message = isValid 
            ? "✅ Transfers match perfectly" 
            : "⚠️ Transfer mismatch: ₡\(Int(abs(expensesSavingsTransfers - savingsIncomingTransfers)).formatted()) difference"
        
        return (isValid, message)
    }
    
    // MARK: - Financial Goal Management
    func updateEmergencyFundTarget(_ newTarget: Double) {
        emergencyFundTarget = newTarget
    }
    
    func getGoalProgress(for category: String) -> Double {
        if category == "Emergency Fund" {
            return emergencyFundProgress
        }
        // For percentage-based categories, they don't have fixed goals
        // Their "progress" is just whether they have allocated amounts (100% when emergency fund is complete)
        return isEmergencyFundComplete ? 1.0 : 0.0
    }
    
    func getGoalProgressPercentage(for category: String) -> Double {
        getGoalProgress(for: category) * 100
    }
    
    // MARK: - Category Management
    func updateSavingsAllocation(_ categories: [(name: String, percentage: Double)]) {
        // Ensure percentages add up to 1.0
        let totalPercentage = categories.reduce(0) { $0 + $1.percentage }
        guard abs(totalPercentage - 1.0) < 0.001 else {
            print("Warning: Savings allocation percentages should add up to 100%")
            return
        }
        savingsAllocationCategories = categories
    }
    
    func addSavingsCategory(name: String, percentage: Double) {
        // Adjust existing percentages to accommodate new category
        let existingTotal = savingsAllocationCategories.reduce(0) { $0 + $1.percentage }
        let remainingPercentage = 1.0 - existingTotal
        
        if remainingPercentage >= percentage {
            savingsAllocationCategories.append((name: name, percentage: percentage))
        } else {
            print("Warning: Cannot add category, insufficient remaining percentage allocation")
        }
    }
    
    func removeSavingsCategory(name: String) {
        savingsAllocationCategories.removeAll { $0.name == name }
    }
} 