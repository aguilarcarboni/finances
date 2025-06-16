import Foundation
import Combine

class WealthEngineManager: ObservableObject {
    static let shared = WealthEngineManager()
    
    @Published var netWorth: Double = 0
    @Published var netWorthHistory: [NetWorthSnapshot] = []
    @Published var capitalAllocation: CapitalAllocation = CapitalAllocation()
    @Published var financialHealthScore: FinancialHealthScore = FinancialHealthScore()
    @Published var recommendations: [FinancialRecommendation] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    private let expensesAccount = ExpensesAccount.shared
    private let savingsAccount = SavingsAccount.shared
    private let investmentsAccount = InvestmentsAccount.shared
    private let assetsManager = AssetsManager.shared
    
    private init() {
        setupObservers()
        calculateNetWorth()
        calculateCapitalAllocation()
        calculateFinancialHealthScore()
        generateRecommendations()
    }
    
    private func setupObservers() {
        // Observe changes in all accounts and recalculate
        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                expensesAccount.$transactions,
                savingsAccount.$transactions,
                investmentsAccount.$_portfolioValue,
                assetsManager.$assets
            ),
            investmentsAccount.$isConnectedToIBKR
        )
        .sink { [weak self] _, _ in
            self?.calculateNetWorth()
            self?.calculateCapitalAllocation()
            self?.calculateFinancialHealthScore()
            self?.generateRecommendations()
        }
        .store(in: &cancellables)
    }
    
    private func calculateNetWorth() {
        let assets = assetsManager.totalAssetsValue + investmentsAccount.portfolioValue + savingsAccount.totalSavingsBalance + expensesAccount.netBalance
        let liabilities = assetsManager.totalDebt
        netWorth = assets - liabilities
        
        // Update net worth history (monthly snapshot)
        updateNetWorthHistory()
    }
    
    private func updateNetWorthHistory() {
        let currentMonth = Calendar.current.startOfMonth(for: Date())
        
        // Check if we already have a snapshot for this month
        if let existingIndex = netWorthHistory.firstIndex(where: { Calendar.current.isDate($0.date, equalTo: currentMonth, toGranularity: .month) }) {
            netWorthHistory[existingIndex].value = netWorth
        } else {
            netWorthHistory.append(NetWorthSnapshot(date: currentMonth, value: netWorth))
            // Keep only last 24 months
            netWorthHistory = Array(netWorthHistory.suffix(24))
        }
    }
    
    private func calculateCapitalAllocation() {
        let savings = max(savingsAccount.totalSavingsBalance, 0)
        let investments = max(investmentsAccount.portfolioValue, 0)
        let assets = max(assetsManager.totalAssetsValue, 0)
        let debt = max(assetsManager.totalDebt, 0)
        let cash = max(expensesAccount.netBalance, 0)
        let totalPositiveCapital = savings + investments + assets + cash
        
        capitalAllocation = CapitalAllocation(
            savings: savings,
            investments: investments,
            assets: assets,
            debt: debt,
            cash: cash,
            totalCapital: totalPositiveCapital // Keep actual total, even if zero
        )
    }
    
    private func calculateFinancialHealthScore() {
        let portfolioScore = calculatePortfolioHealthScore()
        let budgetScore = calculateBudgetHealthScore()
        let savingsScore = calculateSavingsHealthScore()
        let diversificationScore = calculateDiversificationScore()
        
        financialHealthScore = FinancialHealthScore(
            portfolioHealth: portfolioScore,
            budgetHealth: budgetScore,
            savingsHealth: savingsScore,
            diversificationHealth: diversificationScore
        )
    }
    
    private func calculatePortfolioHealthScore() -> Double {
        // Score based on investment performance and allocation
        let hasInvestments = investmentsAccount.portfolioValue > 0
        let investmentRatio = investmentsAccount.portfolioValue / max(netWorth, 1)
        let performanceScore = investmentsAccount.returnPercentage / 100 // Convert percentage to decimal
        
        if !hasInvestments { return 40.0 } // Low score for no investments
        
        let allocationScore = min(investmentRatio * 2, 1.0) // Prefer higher investment allocation
        let perfScore = max(min((performanceScore + 0.1) / 0.2, 1.0), 0.0) // Normalize performance (-10% to +10% range)
        
        return (allocationScore * 0.6 + perfScore * 0.4) * 100
    }
    
    private func calculateBudgetHealthScore() -> Double {
        // Score based on expense trends and emergency fund
        let monthlyExpenses = expensesAccount.averageExpensesPerPeriod // This is now monthly from the updated ExpensesAccount
        let emergencyFundMonths = savingsAccount.totalSavingsBalance / max(monthlyExpenses, 1)
        let emergencyScore = min(emergencyFundMonths / 6, 1.0) // Target 6 months
        
        // Calculate expense growth from recent periods
        let expenseGrowth: Double
        
        // Get last 6 months and previous 6 months for comparison
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        
        let recentExpenses = expensesAccount.totalDebitsForDateRange(from: sixMonthsAgo, to: Date())
        let olderExpenses = expensesAccount.totalDebitsForDateRange(from: twelveMonthsAgo, to: sixMonthsAgo)
        
        if olderExpenses > 0 {
            expenseGrowth = (recentExpenses - olderExpenses) / olderExpenses
        } else {
            expenseGrowth = 0
        }
        
        let growthScore = max(min((-expenseGrowth + 0.05) / 0.1, 1.0), 0.0) // Prefer negative growth
        
        return (emergencyScore * 0.7 + growthScore * 0.3) * 100
    }
    
    private func calculateSavingsHealthScore() -> Double {
        // Score based on savings rate and consistency
        // Calculate savings rate from account summary
        let accountSummary = savingsAccount.getAccountSummary()
        let totalIncome = max(expensesAccount.getAccountSummary().totalCredits, 1)
        let savingsRate = accountSummary.totalCredits / totalIncome
        let savingsScore = min(savingsRate / 0.2, 1.0) // Target 20% savings rate
        
        // Calculate consistency based on regular transfers over last 6 months
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let recentSavingsTransactions = savingsAccount.transactionsForDateRange(from: sixMonthsAgo, to: Date())
        
        // Check if there are regular savings (at least 4 months with transfers)
        var monthsWithSavings = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for transaction in recentSavingsTransactions where transaction.type == .credit {
            monthsWithSavings.insert(formatter.string(from: transaction.date))
        }
        
        let hasConsistentSavings = monthsWithSavings.count >= 4
        let consistencyScore = hasConsistentSavings ? 1.0 : 0.5
        
        return (savingsScore * 0.7 + consistencyScore * 0.3) * 100
    }
    
    private func calculateDiversificationScore() -> Double {
        // Score based on asset diversification
        let totalPositiveValue = max(savingsAccount.totalSavingsBalance + max(investmentsAccount.portfolioValue, 0) + max(assetsManager.totalEquity, 0), 1)
        let savingsRatio = savingsAccount.totalSavingsBalance / totalPositiveValue
        let investmentRatio = max(investmentsAccount.portfolioValue, 0) / totalPositiveValue
        let assetRatio = max(assetsManager.totalEquity, 0) / totalPositiveValue
        
        // When there are no investments, return 0 for diversification
        if investmentsAccount.portfolioValue <= 0 {
            return 0.0
        }
        
        // Ideal diversification (rough targets)
        let idealSavings = 0.1 // 10% in savings
        let idealInvestments = 0.6 // 60% in investments
        let idealAssets = 0.3 // 30% in assets
        
        let savingsDeviation = abs(savingsRatio - idealSavings)
        let investmentDeviation = abs(investmentRatio - idealInvestments)
        let assetDeviation = abs(assetRatio - idealAssets)
        
        let averageDeviation = (savingsDeviation + investmentDeviation + assetDeviation) / 3
        let diversificationScore = max(1 - averageDeviation * 2, 0.0)
        
        return diversificationScore * 100
    }
    
    private func generateRecommendations() {
        var newRecommendations: [FinancialRecommendation] = []
        
        // Payoff vs Invest recommendations
        for asset in assetsManager.assets {
            if asset.remainingLoanBalance > 0 {
                let recommendation = generatePayoffVsInvestRecommendation(for: asset)
                newRecommendations.append(recommendation)
            }
        }
        
        // Idle cash recommendations
        let currentCash = expensesAccount.netBalance
        if currentCash > savingsAccount.totalSavingsBalance * 0.5 {
            newRecommendations.append(FinancialRecommendation(
                title: "Deploy Idle Cash",
                description: "You have ₡\(currentCash.formatted(.currency(code: "CRC"))) sitting idle. Consider moving excess to investments or savings.",
                priority: .medium,
                category: .liquidityOptimization,
                action: "Transfer ₡\((currentCash - savingsAccount.totalSavingsBalance * 0.3).formatted(.currency(code: "CRC"))) to investments"
            ))
        }
        
        // Emergency fund recommendations
        let monthlyExpenses = expensesAccount.averageExpensesPerPeriod // Now monthly
        let emergencyFundMonths = savingsAccount.totalSavingsBalance / max(monthlyExpenses, 1)
        if emergencyFundMonths < 3 {
            newRecommendations.append(FinancialRecommendation(
                title: "Build Emergency Fund",
                description: "Your emergency fund covers only \(emergencyFundMonths.formatted(.number.precision(.fractionLength(1)))) months. Target 6 months.",
                priority: .high,
                category: .emergencyFund,
                action: "Increase savings by ₡\((monthlyExpenses * 6 - savingsAccount.totalSavingsBalance).formatted(.currency(code: "CRC")))"
            ))
        }
        
        // Investment rebalancing
        if investmentsAccount.portfolioValue > 0 {
            let recommendation = generateRebalancingRecommendation()
            if let recommendation = recommendation {
                newRecommendations.append(recommendation)
            }
        }
        
        recommendations = newRecommendations
    }
    
    private func generatePayoffVsInvestRecommendation(for asset: Asset) -> FinancialRecommendation {
        let loanRate = asset.interestRate / 100 // Convert to decimal
        let expectedInvestmentReturn = 0.07 // Assume 7% expected return since property doesn't exist
        
        let availableCash = expensesAccount.netBalance
        let maxPayoff = min(availableCash, asset.remainingLoanBalance)
        
        if loanRate > expectedInvestmentReturn {
            return FinancialRecommendation(
                title: "Pay Off \(asset.name) Loan",
                description: "Loan rate (\((loanRate * 100).formatted(.number.precision(.fractionLength(1))))%) > Expected investment return (\((expectedInvestmentReturn * 100).formatted(.number.precision(.fractionLength(1))))%). Pay off early to save ₡\((maxPayoff * loanRate * 0.1).formatted(.currency(code: "CRC")))/year.",
                priority: .high,
                category: .debtOptimization,
                action: "Pay ₡\(maxPayoff.formatted(.currency(code: "CRC"))) toward loan"
            )
        } else {
            return FinancialRecommendation(
                title: "Invest Instead of Paying Off \(asset.name)",
                description: "Expected investment return (\((expectedInvestmentReturn * 100).formatted(.number.precision(.fractionLength(1))))%) > Loan rate (\((loanRate * 100).formatted(.number.precision(.fractionLength(1))))%). Invest excess cash for better returns.",
                priority: .medium,
                category: .investmentOptimization,
                action: "Invest ₡\(availableCash.formatted(.currency(code: "CRC"))) instead of paying off loan"
            )
        }
    }
    
    private func generateRebalancingRecommendation() -> FinancialRecommendation? {
        // Check if portfolio needs rebalancing based on target allocations
        // This is a simplified version - you can expand based on your specific allocation targets
        return nil // Placeholder
    }
}

// MARK: - Supporting Models

struct NetWorthSnapshot: Identifiable {
    let id = UUID()
    let date: Date
    var value: Double
}

struct CapitalAllocation {
    var savings: Double = 0
    var investments: Double = 0
    var assets: Double = 0
    var debt: Double = 0
    var cash: Double = 0
    var totalCapital: Double = 0
    
    var savingsPercentage: Double { savings / max(totalCapital, 1) }
    var investmentsPercentage: Double { investments / max(totalCapital, 1) }
    var assetsPercentage: Double { assets / max(totalCapital, 1) }
    var debtPercentage: Double { debt / max(totalCapital, 1) }
    var cashPercentage: Double { cash / max(totalCapital, 1) }
}

struct FinancialHealthScore {
    var portfolioHealth: Double = 0
    var budgetHealth: Double = 0
    var savingsHealth: Double = 0
    var diversificationHealth: Double = 0
    
    var overallScore: Double {
        (portfolioHealth + budgetHealth + savingsHealth + diversificationHealth) / 4
    }
    
    var overallGrade: String {
        switch overallScore {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
}

struct FinancialRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let category: Category
    let action: String
    
    enum Priority: String, CaseIterable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
    
    enum Category: String, CaseIterable {
        case debtOptimization = "Debt Optimization"
        case investmentOptimization = "Investment Optimization"
        case liquidityOptimization = "Liquidity Optimization"
        case emergencyFund = "Emergency Fund"
        case rebalancing = "Rebalancing"
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
} 