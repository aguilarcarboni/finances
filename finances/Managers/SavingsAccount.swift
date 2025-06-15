import SwiftUI
import Foundation
import Combine

class SavingsAccount: ObservableObject, Account {
    @Published var biweeklyPeriods: [BiweeklyPeriod] = []
    
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
    var savingsGrowthData: [(period: String, balance: Double)] {
        var runningBalance: Double = 0
        return biweeklyPeriods.map { period in
            runningBalance += period.netBalance
            return (period: period.dateRange, balance: runningBalance)
        }
    }
    
    var totalSavingsBalance: Double {
        savingsGrowthData.last?.balance ?? 0
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
        let june15 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let june30 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 30))!

        let q2JuneTransactions: [Transaction] = []
        
        biweeklyPeriods = [
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
    
    // MARK: - Transfer Validation
    func validateTransfersWithExpenses(_ expensesAccount: ExpensesAccount) -> (isValid: Bool, message: String) {
        let expensesSavingsTransfers = expensesAccount.biweeklyPeriods.reduce(0.0) { total, period in
            total + period.debitsForCategory("Savings")
        }
        
        let savingsIncomingTransfers = biweeklyPeriods.reduce(0.0) { total, period in
            total + period.creditsForCategory("Savings") // All savings come in as generic "Savings"
        }
        
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