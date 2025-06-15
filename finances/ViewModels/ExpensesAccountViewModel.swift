import Foundation
import Combine

class ExpensesAccountViewModel: ObservableObject {
    @Published var expensesAccount = ExpensesAccount.shared
    private let wealthEngine = WealthEngineManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes and update wealth engine calculations
        expensesAccount.$biweeklyPeriods
            .sink { _ in
                // The wealth engine will automatically recalculate when it observes changes
            }
            .store(in: &cancellables)
    }
    
    var currentBalance: Double {
        expensesAccount.netBalance
    }
    
    var monthlyAverage: Double {
        expensesAccount.averageExpensesPerPeriod * 2 // Convert biweekly to monthly
    }
    
    var expenseGrowthRate: Double {
        // Calculate growth rate from recent periods
        let periods = expensesAccount.biweeklyPeriods
        guard periods.count >= 2 else { return 0 }
        
        let recent = periods.suffix(3).map { $0.totalDebits }
        let older = periods.dropLast(3).suffix(3).map { $0.totalDebits }
        
        guard !recent.isEmpty && !older.isEmpty else { return 0 }
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        guard olderAvg > 0 else { return 0 }
        return (recentAvg - olderAvg) / olderAvg
    }
    
    var emergencyFundMonths: Double {
        let savings = wealthEngine.capitalAllocation.savings
        return savings / max(abs(monthlyAverage), 1)
    }
    
    var summaryItems: [AccountSummaryItem] {
        [
            AccountSummaryItem(
                title: "Current Balance",
                subtitle: "Available Cash",
                amount: currentBalance,
                trend: nil,
                icon: "dollarsign.circle.fill",
                color: "blue"
            ),
            AccountSummaryItem(
                title: "Monthly Average",
                subtitle: "Expense Trend",
                amount: abs(monthlyAverage),
                trend: expenseGrowthRate > 0 ? .up(expenseGrowthRate / 100) : 
                       expenseGrowthRate < 0 ? .down(expenseGrowthRate / 100) : .neutral,
                icon: "chart.bar.fill",
                color: "orange"
            ),
            AccountSummaryItem(
                title: "Emergency Fund",
                subtitle: "\(emergencyFundMonths.formatted(.number.precision(.fractionLength(1)))) months",
                amount: wealthEngine.capitalAllocation.savings,
                trend: emergencyFundMonths >= 6 ? .up(0.1) : 
                       emergencyFundMonths >= 3 ? .neutral : .down(-0.1),
                icon: "shield.fill",
                color: emergencyFundMonths >= 6 ? "green" : emergencyFundMonths >= 3 ? "yellow" : "red"
            )
        ]
    }
}
