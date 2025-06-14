import Foundation
import Combine

@MainActor
class FinancialSystemViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var expensesAccount = ExpensesAccount.shared
    @Published var savingsAccount = SavingsAccount.shared
    @Published var assetsViewModel = AssetsViewModel()
    @Published var investmentsViewModel = InvestmentsViewModel()
    
    // MARK: - Financial Health Metrics
    var netWorth: Double {
        let assetsValue = assetsViewModel.totalAssetsValue
        let assetsDebt = assetsViewModel.totalDebt
        let savingsValue = savingsAccount.getAccountSummary().netBalance
        let investmentsValue = totalInvestmentValue
        let cashBalance = expensesAccount.getAccountSummary().netBalance
        
        return assetsValue + savingsValue + investmentsValue + cashBalance - assetsDebt
    }
    
    var totalInvestmentValue: Double {
        guard let netLiqValue = investmentsViewModel.items.first(where: { $0.tag.lowercased() == "netliquidationvalue" }) else {
            return 0
        }
        return Double(netLiqValue.value) ?? 0
    }
    
    var monthlyIncome: Double {
        // Calculate average monthly income from recent periods
        let recentPeriods = Array(expensesAccount.biweeklyPeriods.suffix(6)) // Last 3 months
        let totalIncome = recentPeriods.reduce(0) { total, period in
            total + period.creditsForCategory("Income")
        }
        guard !recentPeriods.isEmpty else { return 0 }
        return (totalIncome / Double(recentPeriods.count)) * 2 // Convert biweekly to monthly
    }
    
    var monthlyExpenses: Double {
        // Calculate average monthly expenses (excluding savings transfers)
        let recentPeriods = Array(expensesAccount.biweeklyPeriods.suffix(6))
        let totalExpenses = recentPeriods.reduce(0) { total, period in
            let periodExpenses = period.totalDebits - period.debitsForCategory("Savings")
            return total + periodExpenses
        }
        guard !recentPeriods.isEmpty else { return 0 }
        return (totalExpenses / Double(recentPeriods.count)) * 2
    }
    
    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        let monthlySavings = monthlyIncome - monthlyExpenses
        return (monthlySavings / monthlyIncome) * 100
    }
    
    var debtPressureIndex: Double {
        guard monthlyIncome > 0 else { return 0 }
        let monthlyDebtPayments = (expensesAccount.budgetForCategory("Debt") * 2) // Biweekly to monthly
        return (monthlyDebtPayments / monthlyIncome) * 100
    }
    
    var emergencyBufferMonths: Double {
        guard monthlyExpenses > 0 else { return 0 }
        let totalLiquidSavings = savingsAccount.getAccountSummary().netBalance
        return totalLiquidSavings / monthlyExpenses
    }
    
    // MARK: - Capital Allocation
    var capitalAllocation: [(category: String, amount: Double, percentage: Double)] {
        let totalCapital = max(netWorth, 1) // Avoid division by zero
        
        let categories = [
            ("Cash", savingsAccount.getAccountSummary().netBalance),
            ("Investments", totalInvestmentValue),
            ("Asset Equity", assetsViewModel.totalAssetsValue - assetsViewModel.totalDebt),
            ("Liquid Cash", expensesAccount.getAccountSummary().netBalance)
        ]
        
        return categories.map { (name, amount) in
            let percentage = (amount / totalCapital) * 100
            return (category: name, amount: amount, percentage: percentage)
        }
    }
    
    // MARK: - Financial Health Score
    var financialHealthScore: (score: Int, components: [(name: String, score: Int, weight: Double)]) {
        let components = [
            ("Savings Rate", calculateSavingsRateScore(), 0.25),
            ("Emergency Buffer", calculateEmergencyBufferScore(), 0.25),
            ("Debt Pressure", calculateDebtPressureScore(), 0.20),
            ("Asset Allocation", calculateAllocationScore(), 0.15),
            ("Investment Performance", calculateInvestmentScore(), 0.15)
        ]
        
        let totalScore = components.reduce(into: 0.0) { total, component in
            total + (Double(component.1) * component.2)
        }
        
        return (score: Int(totalScore), components: components.map { (name: $0.0, score: $0.1, weight: $0.2) })
    }
    
    // MARK: - Intelligent Recommendations
    var dailyRecommendation: (title: String, description: String, action: String, priority: String) {
        // Logic to determine the most important action for today
        if emergencyBufferMonths < 3 {
            return (
                title: "⚠️ Emergency Fund Critical",
                description: "You only have \(String(format: "%.1f", emergencyBufferMonths)) months of expenses saved",
                action: "Transfer ₡50,000 to emergency fund",
                priority: "HIGH"
            )
        } else if savingsRate < 20 {
            return (
                title: "💰 Boost Savings Rate",
                description: "Current savings rate: \(String(format: "%.1f", savingsRate))%",
                action: "Review expenses and increase savings by ₡25,000/month",
                priority: "MEDIUM"
            )
        } else if debtPressureIndex > 30 {
            return (
                title: "📉 High Debt Pressure",
                description: "\(String(format: "%.1f", debtPressureIndex))% of income goes to debt",
                action: "Consider debt consolidation or extra payments",
                priority: "HIGH"
            )
        } else {
            return (
                title: "🚀 Deploy Idle Capital",
                description: "Consider investing excess cash for growth",
                action: "Review investment allocation",
                priority: "LOW"
            )
        }
    }
    
    // MARK: - Private Helper Methods
    private func calculateSavingsRateScore() -> Int {
        switch savingsRate {
        case 30...: return 100
        case 20..<30: return 80
        case 10..<20: return 60
        case 5..<10: return 40
        default: return 20
        }
    }
    
    private func calculateEmergencyBufferScore() -> Int {
        switch emergencyBufferMonths {
        case 6...: return 100
        case 4..<6: return 80
        case 3..<4: return 60
        case 1..<3: return 40
        default: return 20
        }
    }
    
    private func calculateDebtPressureScore() -> Int {
        switch debtPressureIndex {
        case 0..<20: return 100
        case 20..<30: return 80
        case 30..<40: return 60
        case 40..<50: return 40
        default: return 20
        }
    }
    
    private func calculateAllocationScore() -> Int {
        let investmentAllocation = capitalAllocation.first { $0.category == "Investments" }?.percentage ?? 0
        switch investmentAllocation {
        case 60...: return 100
        case 40..<60: return 80
        case 20..<40: return 60
        case 10..<20: return 40
        default: return 20
        }
    }
    
    private func calculateInvestmentScore() -> Int {
        // For now, return a moderate score - could be enhanced with actual performance metrics
        return 70
    }
    
    // MARK: - Async Data Loading
    func refreshInvestmentData() async {
        await investmentsViewModel.fetchAccountSummary()
    }
} 
