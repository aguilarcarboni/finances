import SwiftUI
import Foundation
import Combine

class InvestmentsAccount: ObservableObject, Account {
    @Published var biweeklyPeriods: [BiweeklyPeriod] = []
    
    static let shared = InvestmentsAccount()

    @Published var budget: [BudgetCategory] = [
        BudgetCategory(name: "Stocks", budget: 150000),
        BudgetCategory(name: "ETFs", budget: 100000),
        BudgetCategory(name: "Bonds", budget: 50000),
        BudgetCategory(name: "Options", budget: 25000),
        BudgetCategory(name: "Crypto", budget: 30000),
    ]
    
    // MARK: - Investment-specific Configuration
    @Published var targetAllocation: [String: Double] = [
        "Stocks": 0.6,
        "ETFs": 0.25,
        "Bonds": 0.1,
        "Options": 0.03,
        "Crypto": 0.02
    ]
    
    // MARK: - IBKR Connection Properties (for future API integration)
    @Published var isConnectedToIBKR: Bool = false
    @Published var lastSyncDate: Date?
    @Published internal var _portfolioValue: Double = 0
    @Published var dayChange: Double = 0
    @Published var dayChangePercentage: Double = 0
    
    // MARK: - Computed Properties for Dashboard Integration
    
    /// Returns portfolio value only when connected to IBKR, otherwise returns 0
    /// This prevents offline/demo data from affecting real wealth calculations
    var portfolioValue: Double {
        return isConnectedToIBKR ? _portfolioValue : 0
    }
    
    /// Returns the raw portfolio value regardless of connection status (for display purposes)
    var rawPortfolioValue: Double {
        return _portfolioValue
    }
    
    /// Returns day change only when connected to IBKR, otherwise returns 0
    var offlineAwareDayChange: Double {
        return isConnectedToIBKR ? dayChange : 0
    }
    
    /// Returns day change percentage only when connected to IBKR, otherwise returns 0
    var offlineAwareDayChangePercentage: Double {
        return isConnectedToIBKR ? dayChangePercentage : 0
    }
    
    /// Returns true if we have demo/offline data that's not being used in calculations
    var hasOfflineData: Bool {
        return !isConnectedToIBKR && _portfolioValue > 0
    }
    
    // MARK: - Investment Performance Metrics
    var totalInvested: Double {
        totalDebits // Money transferred in for investments
    }
    
    var totalReturns: Double {
        portfolioValue - totalInvested
    }
    
    var returnPercentage: Double {
        guard totalInvested > 0 else { return 0 }
        return (totalReturns / totalInvested) * 100
    }
    
    var unrealizedGains: Double {
        totalReturns
    }
    
    var portfolioAllocation: [(category: String, value: Double, percentage: Double)] {
        let summary = getCategorySummary()
        let total = portfolioValue // Use portfolioValue instead of _portfolioValue to respect offline state
        
        return summary.map { item in
            let currentValue = item.net // Assuming net represents current position value
            let percentage = total > 0 ? (currentValue / total) * 100 : 0
            return (category: item.category, value: currentValue, percentage: percentage)
        }
    }
    
    var allocationVariance: [(category: String, target: Double, actual: Double, variance: Double)] {
        let currentAllocation = portfolioAllocation
        
        return targetAllocation.map { (category, targetPercentage) in
            let actualPercentage = currentAllocation.first { $0.category == category }?.percentage ?? 0
            let variance = actualPercentage - (targetPercentage * 100)
            return (category: category, target: targetPercentage * 100, actual: actualPercentage, variance: variance)
        }
    }
    
    var needsRebalancing: Bool {
        allocationVariance.contains { abs($0.variance) > 5.0 } // 5% tolerance
    }
    
    var rebalancingRecommendations: [(category: String, action: String, amount: Double)] {
        return allocationVariance.compactMap { item in
            if abs(item.variance) > 5.0 {
                let action = item.variance > 0 ? "Sell" : "Buy"
                let amount = abs(item.variance / 100) * portfolioValue // Use portfolioValue instead of _portfolioValue
                return (category: item.category, action: action, amount: amount)
            }
            return nil
        }
    }
    
    private init() {
        // Initialize with empty data - will only be populated when connected to IBKR
        biweeklyPeriods = []
        _portfolioValue = 0
        dayChange = 0
        dayChangePercentage = 0
        lastSyncDate = nil
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
        } else if let currentPeriod = currentPeriod,
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
    
    // MARK: - Investment-specific Methods
    func updatePortfolioValue(_ newValue: Double) {
        let previousValue = _portfolioValue
        _portfolioValue = newValue
        dayChange = newValue - previousValue
        dayChangePercentage = previousValue > 0 ? ((newValue - previousValue) / previousValue) * 100 : 0
        lastSyncDate = Date()
    }
    
    func connectToIBKR() {
        // Only set connected state - actual data will come from successful API calls
        isConnectedToIBKR = true
    }
    
    func disconnectFromIBKR() {
        isConnectedToIBKR = false
        lastSyncDate = nil
        // Clear all data when disconnecting
        _portfolioValue = 0
        dayChange = 0
        dayChangePercentage = 0
        biweeklyPeriods = []
    }
    
    func syncWithIBKR() async {
        // Placeholder for IBKR API sync
        // This would fetch real portfolio data, positions, and transactions
        guard isConnectedToIBKR else { return }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Update portfolio value and sync date
        lastSyncDate = Date()
    }
    
    // MARK: - Portfolio Analysis
    func getPerformanceMetrics() -> (totalReturn: Double, annualizedReturn: Double, sharpeRatio: Double) {
        let totalReturn = returnPercentage
        
        // Simplified annualized return calculation (would be more complex with real data)
        let yearsInvested = max(1.0, Double(biweeklyPeriods.count) / 26.0) // 26 biweekly periods per year
        let annualizedReturn = pow(1 + (totalReturn / 100), 1 / yearsInvested) - 1
        
        // Simplified Sharpe ratio (would need risk-free rate and volatility data)
        let sharpeRatio = annualizedReturn * 100 / max(10.0, abs(offlineAwareDayChangePercentage)) // Use offline-aware version
        
        return (totalReturn: totalReturn, annualizedReturn: annualizedReturn * 100, sharpeRatio: sharpeRatio)
    }
    
    func getDiversificationScore() -> Double {
        let allocation = portfolioAllocation
        guard !allocation.isEmpty else { return 0 }
        
        // Simple diversification score based on number of categories and distribution
        let numberOfCategories = allocation.filter { $0.percentage > 1 }.count
        let maxPercentage = allocation.map { $0.percentage }.max() ?? 100
        
        let categoryScore = min(1.0, Double(numberOfCategories) / 5.0) // Optimal at 5 categories
        let distributionScore = min(1.0, max(0.0, 1.0 - (maxPercentage - 60) / 40)) // Penalize over-concentration
        
        return (categoryScore + distributionScore) / 2.0
    }
    
    func getDiversificationScorePercentage() -> Double {
        getDiversificationScore() * 100
    }
} 
