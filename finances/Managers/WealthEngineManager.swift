import Foundation
import Combine

class WealthEngineManager: ObservableObject {
    static let shared = WealthEngineManager()
    
    @Published var netWorth: Double = 0
    @Published var netWorthHistory: [NetWorthSnapshot] = []
    @Published var capitalAllocation: CapitalAllocation = CapitalAllocation()
    
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
        }
        .store(in: &cancellables)
    }
    
    private func calculateNetWorth() {
        let assets = assetsManager.totalAssetsValue + savingsAccount.totalSavingsBalance + expensesAccount.netBalance
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
        let assets = max(assetsManager.totalAssetsValue, 0)
        let debt = max(assetsManager.totalDebt, 0)
        let cash = max(expensesAccount.netBalance, 0)
        let totalPositiveCapital = savings + assets + cash
        
        capitalAllocation = CapitalAllocation(
            savings: savings,
            assets: assets,
            debt: debt,
            cash: cash,
            totalCapital: totalPositiveCapital // Keep actual total, even if zero
        )
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
    var budgetHealth: Double = 0
    var savingsHealth: Double = 0
    
    var overallScore: Double {
        (budgetHealth + savingsHealth) / 4
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
