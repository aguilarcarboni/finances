import SwiftUI
import Foundation
import Combine

class SavingsAccount: ObservableObject, Account {
    
    @Published var transactions: [Transaction] = []
    @Published var selectedDateFilter: DateFilterType = .oneMonth
    
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
    
    // MARK: - Filtered Data Properties
    var filteredTransactions: [Transaction] {
        let dateRange = selectedDateFilter.dateRange
        return transactions.filter { transaction in
            transaction.date >= dateRange.start && transaction.date <= dateRange.end
        }
    }
    
    var filteredDebits: [Transaction] {
        filteredTransactions.filter { $0.type == .debit }
    }
    
    var filteredCredits: [Transaction] {
        filteredTransactions.filter { $0.type == .credit }
    }
    
    var filteredTotalDebits: Double {
        filteredDebits.reduce(0) { $0 + $1.amount }
    }
    
    var filteredTotalCredits: Double {
        filteredCredits.reduce(0) { $0 + $1.amount }
    }
    
    var filteredNetBalance: Double {
        filteredTotalCredits - filteredTotalDebits
    }
    
    func filteredDebitsForCategory(_ categoryName: String) -> Double {
        filteredDebits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }
    
    func filteredCreditsForCategory(_ categoryName: String) -> Double {
        filteredCredits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Computed Financial Metrics
    var savingsGrowthData: [(month: String, balance: Double)] {
        let dateRange = selectedDateFilter.dateRange
        let calendar = Calendar.current
        var result: [(month: String, balance: Double)] = []
        var runningBalance: Double = 0
        
        // Filter transactions within the selected date range
        let filteredTransactionsForChart = transactions.filter { transaction in
            transaction.date >= dateRange.start && transaction.date <= dateRange.end
        }.sorted { $0.date < $1.date }
        
        // Determine the appropriate time intervals based on the filter
        let intervals = getTimeIntervals(for: selectedDateFilter, from: dateRange.start, to: dateRange.end)
        
        for interval in intervals {
            // Get transactions for this specific interval
            let intervalTransactions = filteredTransactionsForChart.filter { transaction in
                transaction.date >= interval.start && transaction.date < interval.end
            }
            
            // Calculate net change for this interval
            let intervalChange = intervalTransactions.reduce(0) { total, transaction in
                total + (transaction.type == .credit ? transaction.amount : -transaction.amount)
            }
            
            // Add to running balance
            runningBalance += intervalChange
            
            result.append((month: interval.label, balance: max(runningBalance, 0)))
        }
        
        return result
    }
    
    private func getTimeIntervals(for filter: DateFilterType, from start: Date, to end: Date) -> [(start: Date, end: Date, label: String)] {
        let calendar = Calendar.current
        var intervals: [(start: Date, end: Date, label: String)] = []
        
        let formatter = DateFormatter()
        
        switch filter {
        case .threeDays, .oneWeek:
            formatter.dateFormat = "MMM d"
            var currentDate = start
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
        case .twoWeeks, .oneMonth:
            formatter.dateFormat = "MMM d"
            var currentDate = start
            let intervalDays = selectedDateFilter == .twoWeeks ? 2 : 3
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .day, value: intervalDays, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
        default:
            formatter.dateFormat = "MMM yyyy"
            var currentDate = calendar.dateInterval(of: .month, for: start)?.start ?? start
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
        }
        
        return intervals
    }
    
    var totalSavingsBalance: Double {
        netBalance // This now comes from all transactions
    }
    
    var filteredSavingsBalance: Double {
        filteredNetBalance
    }
    
    var emergencyFundProgress: Double {
        min(filteredSavingsBalance / emergencyFundTarget, 1.0)
    }
    
    var emergencyFundProgressPercentage: Double {
        emergencyFundProgress * 100
    }
    
    var emergencyFundRemaining: Double {
        max(emergencyFundTarget - filteredSavingsBalance, 0)
    }
    
    var isEmergencyFundComplete: Bool {
        filteredSavingsBalance >= emergencyFundTarget
    }
    
    var excessSavings: Double {
        max(filteredSavingsBalance - emergencyFundTarget, 0)
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
        let currentDate = Date()
        var allTransactions: [Transaction] = []
        
        // Generate savings transactions for the last 8 months to match ExpensesAccount
        for monthOffset in 0...7 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            
            // Monthly savings transfer (regular savings)
            let monthlySavingsAmount = Double.random(in: 45000...55000)
            allTransactions.append(Transaction(name: "Monthly Savings Transfer", category: "Savings", amount: monthlySavingsAmount, type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -8...(-2)), to: monthDate)!))
            
            // Emergency Fund transfers (not every month)
            if Bool.random() && monthOffset <= 6 {
                let emergencyAmount = Double.random(in: 25000...40000)
                allTransactions.append(Transaction(name: "Emergency Fund Transfer", category: "Emergency Fund", amount: emergencyAmount, type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -15...(-3)), to: monthDate)!))
            }
            
            // Occasional larger savings (bonuses, windfalls, etc.)
            if monthOffset == 1 {
                allTransactions.append(Transaction(name: "Bonus Savings", category: "Savings", amount: 75000, type: .credit, date: calendar.date(byAdding: .day, value: -12, to: monthDate)!))
            }
            
            if monthOffset == 2 {
                allTransactions.append(Transaction(name: "Tax Refund Savings", category: "Savings", amount: 85000, type: .credit, date: calendar.date(byAdding: .day, value: -10, to: monthDate)!))
            }
            
            if monthOffset == 3 {
                allTransactions.append(Transaction(name: "Freelance Project Savings", category: "Savings", amount: 35000, type: .credit, date: calendar.date(byAdding: .day, value: -18, to: monthDate)!))
            }
            
            if monthOffset == 5 {
                allTransactions.append(Transaction(name: "Investment Profit Savings", category: "Savings", amount: 28000, type: .credit, date: calendar.date(byAdding: .day, value: -22, to: monthDate)!))
            }
            
            if monthOffset == 6 {
                allTransactions.append(Transaction(name: "Year-end Bonus Savings", category: "Savings", amount: 120000, type: .credit, date: calendar.date(byAdding: .day, value: -8, to: monthDate)!))
            }
            
            // Occasional withdrawals for trips or major purchases (debits)
            if monthOffset == 4 {
                allTransactions.append(Transaction(name: "Vacation Fund Withdrawal", category: "Trips", amount: 80000, type: .debit, date: calendar.date(byAdding: .day, value: -15, to: monthDate)!))
            }
            
            if monthOffset == 7 {
                allTransactions.append(Transaction(name: "Home Improvement Withdrawal", category: "Long term", amount: 45000, type: .debit, date: calendar.date(byAdding: .day, value: -20, to: monthDate)!))
            }
            
            // Additional emergency fund contributions in certain months
            if monthOffset % 2 == 0 && monthOffset <= 4 {
                let additionalEmergency = Double.random(in: 15000...25000)
                allTransactions.append(Transaction(name: "Additional Emergency Fund", category: "Emergency Fund", amount: additionalEmergency, type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -25...(-10)), to: monthDate)!))
            }
            
            // Quarterly investment contributions
            if monthOffset % 3 == 0 {
                let investmentAmount = Double.random(in: 30000...50000)
                allTransactions.append(Transaction(name: "Investment Account Transfer", category: "Long term", amount: investmentAmount, type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -20...(-5)), to: monthDate)!))
            }
            
            // Special savings goals
            if monthOffset <= 3 {
                let goalAmount = Double.random(in: 10000...20000)
                allTransactions.append(Transaction(name: "Travel Fund", category: "Trips", amount: goalAmount, type: .credit, date: calendar.date(byAdding: .day, value: Int.random(in: -28...(-1)), to: monthDate)!))
            }
        }
        
        // Add some interest earned (small amounts monthly)
        for monthOffset in 0...7 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            let interestAmount = Double.random(in: 800...1500)
            allTransactions.append(Transaction(name: "Savings Interest", category: "Interest", amount: interestAmount, type: .credit, date: calendar.date(byAdding: .day, value: -1, to: monthDate)!))
        }
        
        transactions = allTransactions
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