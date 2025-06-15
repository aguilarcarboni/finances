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
        BudgetCategory(name: "Futures", budget: 25000),
        BudgetCategory(name: "Options", budget: 25000),
        BudgetCategory(name: "Crypto", budget: 30000),
    ]
    
    // MARK: - Watchlist
    @Published var watchlist: [WatchlistItem] = [
        WatchlistItem(symbol: "AAPL"),
        WatchlistItem(symbol: "MSFT"),
        WatchlistItem(symbol: "GOOG"),
        WatchlistItem(symbol: "AMZN"),
        WatchlistItem(symbol: "TSLA"),
        WatchlistItem(symbol: "NVDA"),
        WatchlistItem(symbol: "META"),
        WatchlistItem(symbol: "NFLX"),
    ]
    
    // MARK: - Investment-specific Configuration
    @Published var targetAllocation: [String: Double] = [
        "Stocks": 0.6,
        "ETFs": 0.25,
        "Bonds": 0.1,
        "Futures": 0.03,
        "Options": 0.02,
        "Crypto": 0.02
    ]
    
    // MARK: - IBKR Connection and Data Properties
    @Published var isConnectedToIBKR: Bool = false
    @Published var lastSyncDate: Date?
    @Published internal var _portfolioValue: Double = 0
    @Published var dayChange: Double = 0
    @Published var dayChangePercentage: Double = 0
    @Published var investmentSummary: InvestmentSummary?
    @Published var positions: [InvestmentPosition] = []
    @Published var openOrders: [IBKROrder] = []
    @Published var completedOrders: [IBKROrder] = []
    
    private let apiManager = IBKRAPIManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties for Dashboard Integration
    
    /// Returns portfolio value only when connected to IBKR, otherwise returns 0
    /// This prevents offline/demo data from affecting real wealth calculations
    var portfolioValue: Double {
        return isConnectedToIBKR ? (investmentSummary?.netLiquidation ?? 0) : 0
    }
    
    /// Returns the raw portfolio value regardless of connection status (for display purposes)
    var rawPortfolioValue: Double {
        return investmentSummary?.netLiquidation ?? 0
    }
    
    /// Returns day change only when connected to IBKR, otherwise returns 0
    var offlineAwareDayChange: Double {
        return isConnectedToIBKR ? (investmentSummary?.dayChange ?? 0) : 0
    }
    
    /// Returns day change percentage only when connected to IBKR, otherwise returns 0
    var offlineAwareDayChangePercentage: Double {
        return isConnectedToIBKR ? (investmentSummary?.dayChangePercentage ?? 0) : 0
    }
    
    /// Returns true if we have demo/offline data that's not being used in calculations
    var hasOfflineData: Bool {
        return !isConnectedToIBKR && rawPortfolioValue > 0
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
        investmentSummary?.unrealizedPnL ?? 0
    }
    
    var realizedGains: Double {
        investmentSummary?.realizedPnL ?? 0
    }
    
    var totalPnL: Double {
        unrealizedGains + realizedGains
    }
    
    var totalPnLPercentage: Double {
        guard portfolioValue > 0 else { return 0 }
        return (totalPnL / (portfolioValue - totalPnL)) * 100
    }
    
    // MARK: - Cash & Margin Metrics
    var availableFunds: Double {
        investmentSummary?.availableFunds ?? 0
    }
    
    var buyingPower: Double {
        investmentSummary?.buyingPower ?? 0
    }
    
    var totalCashValue: Double {
        investmentSummary?.totalCashValue ?? 0
    }
    
    var marginUtilization: Double {
        guard buyingPower > 0 else { return 0 }
        let usedMargin = buyingPower - availableFunds
        return (usedMargin / buyingPower) * 100
    }
    
    var cashPercentage: Double {
        guard portfolioValue > 0 else { return 0 }
        return (totalCashValue / portfolioValue) * 100
    }
    
    // MARK: - Asset Category Breakdown
    var stocksValue: Double {
        investmentSummary?.stockMarketValue ?? 0
    }
    
    var optionsValue: Double {
        investmentSummary?.optionMarketValue ?? 0
    }
    
    var futuresValue: Double {
        positions.filter { $0.secType == "FUT" }.reduce(0) { $0 + $1.marketValue }
    }
    
    var totalSecuritiesValue: Double {
        stocksValue + optionsValue + futuresValue
    }
    
    // MARK: - Risk Metrics
    var leverageRatio: Double {
        guard portfolioValue > 0 else { return 0 }
        return totalSecuritiesValue / portfolioValue
    }
    
    var portfolioConcentration: Double {
        let topPosition = positions.max { $0.marketValue < $1.marketValue }
        guard let top = topPosition, portfolioValue > 0 else { return 0 }
        return (top.marketValue / portfolioValue) * 100
    }
    
    // MARK: - Position Analytics
    var winnersCount: Int {
        positions.filter { $0.unrealizedPnL > 0 }.count
    }
    
    var losersCount: Int {
        positions.filter { $0.unrealizedPnL < 0 }.count
    }
    
    var winnersValue: Double {
        positions.filter { $0.unrealizedPnL > 0 }.reduce(0) { $0 + $1.unrealizedPnL }
    }
    
    var losersValue: Double {
        positions.filter { $0.unrealizedPnL < 0 }.reduce(0) { $0 + $1.unrealizedPnL }
    }
    
    var winLossRatio: Double {
        guard losersValue != 0 else { return winnersValue > 0 ? Double.infinity : 0 }
        return abs(winnersValue / losersValue)
    }
    
    var portfolioAllocation: [(category: String, value: Double, percentage: Double)] {
        guard let summary = investmentSummary else {
            return []
        }
        
        let total = summary.netLiquidation
        var allocations: [String: Double] = [:]
        
        // Categorize positions by security type
        for position in positions {
            let category = mapSecTypeToCategory(position.secType)
            let value = abs(position.position) * position.currentValue * position.multiplier
            allocations[category, default: 0] += value
        }
        
        // Add cash as a category
        if summary.totalCashValue > 0 {
            allocations["Cash"] = summary.totalCashValue
        }
        
        return allocations.map { (category, value) in
            let percentage = total > 0 ? (value / total) * 100 : 0
            return (category: category, value: value, percentage: percentage)
        }.sorted { $0.category < $1.category }
    }
    
    private func mapSecTypeToCategory(_ secType: String) -> String {
        switch secType.uppercased() {
        case "STK":
            return "Stocks"
        case "OPT":
            return "Options"
        case "FUT":
            return "Futures"
        case "BOND", "CORP", "GOVT":
            return "Bonds"
        case "ETF":
            return "ETFs"
        case "CRYPTO":
            return "Crypto"
        default:
            return "Other"
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
                let amount = abs(item.variance / 100) * portfolioValue
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
        
        // Monitor API manager connection status
        apiManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnectedToIBKR = isConnected
                if !isConnected {
                    self?.clearData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func clearData() {
        investmentSummary = nil
        positions = []
        openOrders = []
        completedOrders = []
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
    
    func connectToIBKR() async throws {
        try await apiManager.authenticate()
        await syncWithIBKR()
    }
    
    func disconnectFromIBKR() {
        apiManager.disconnect()
    }
    
    func syncWithIBKR() async {
        guard apiManager.isConnected else { return }
        
        do {
            // Fetch all data in parallel for better performance
            async let summaryItems = apiManager.getAccountSummary()
            async let positionsData = apiManager.getPositions()
            async let openOrdersData = apiManager.getOpenOrders()
            async let completedOrdersData = apiManager.getCompletedOrders()
            
            // Process the data
            let summary = apiManager.processAccountSummary(try await summaryItems)
            let processedPositions = apiManager.processPositions(try await positionsData)
            let fetchedOpenOrders = try await openOrdersData
            let fetchedCompletedOrders = try await completedOrdersData
            
            await MainActor.run {
                self.investmentSummary = summary
                self.positions = processedPositions
                self.openOrders = fetchedOpenOrders
                self.completedOrders = fetchedCompletedOrders
                self._portfolioValue = summary.netLiquidation
                self.dayChange = summary.dayChange
                self.dayChangePercentage = summary.dayChangePercentage
                self.lastSyncDate = Date()
            }
            
            // Also update watchlist prices
            await updateWatchlistPrices()
        } catch {
            print("Error syncing with IBKR: \(error)")
            await MainActor.run {
                self.apiManager.lastError = error
            }
        }
    }
    
    // MARK: - Portfolio Analysis
    func getPerformanceMetrics() -> (totalReturn: Double, annualizedReturn: Double, sharpeRatio: Double) {
        guard let summary = investmentSummary else {
            return (totalReturn: 0, annualizedReturn: 0, sharpeRatio: 0)
        }
        
        let totalReturn = returnPercentage
        
        // Simplified annualized return calculation based on current data
        // For more accurate calculation, we'd need historical data over time
        let yearsInvested = max(1.0, Double(biweeklyPeriods.count) / 26.0) // 26 biweekly periods per year
        let annualizedReturn = totalReturn > 0 ? pow(1 + (totalReturn / 100), 1 / yearsInvested) - 1 : 0
        
        // Simplified Sharpe ratio using day change as volatility proxy
        let volatility = max(1.0, abs(summary.dayChangePercentage))
        let sharpeRatio = volatility > 0 ? (annualizedReturn * 100) / volatility : 0
        
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
    
    // MARK: - Watchlist Methods
    
    func updateWatchlistPrices() async {
        guard apiManager.isConnected else { return }
        
        await MainActor.run {
            for i in 0..<watchlist.count {
                watchlist[i].isLoading = true
                watchlist[i].error = nil
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<watchlist.count {
                group.addTask { [weak self] in
                    await self?.updateWatchlistItem(at: i)
                }
            }
        }
    }
    
    private func updateWatchlistItem(at index: Int) async {
        guard index < watchlist.count else { return }
        
        let symbol = watchlist[index].symbol
        
        do {
            let priceResponse = try await apiManager.getLatestStockPrice(symbol: symbol)
            
            await MainActor.run {
                let previousPrice = self.watchlist[index].currentPrice
                self.watchlist[index].currentPrice = priceResponse.latestPrice
                
                // Calculate day change if we have a previous price
                if previousPrice > 0 {
                    let change = priceResponse.latestPrice - previousPrice
                    let changePercent = (change / previousPrice) * 100
                    self.watchlist[index].dayChange = change
                    self.watchlist[index].dayChangePercent = changePercent
                } else {
                    // First time loading, no change data available
                    self.watchlist[index].dayChange = 0.0
                    self.watchlist[index].dayChangePercent = 0.0
                }
                
                self.watchlist[index].lastUpdated = Date()
                self.watchlist[index].isLoading = false
                self.watchlist[index].error = nil
            }
        } catch {
            await MainActor.run {
                self.watchlist[index].isLoading = false
                self.watchlist[index].error = error.localizedDescription
            }
        }
    }
    
    func addToWatchlist(symbol: String) {
        let newItem = WatchlistItem(symbol: symbol.uppercased())
        if !watchlist.contains(where: { $0.symbol == newItem.symbol }) {
            watchlist.append(newItem)
            Task {
                await updateWatchlistItem(at: watchlist.count - 1)
            }
        }
    }
    
    func removeFromWatchlist(symbol: String) {
        watchlist.removeAll { $0.symbol == symbol.uppercased() }
    }
} 
