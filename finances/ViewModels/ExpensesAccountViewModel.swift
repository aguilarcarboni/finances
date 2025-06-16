import Foundation
import Combine

class ExpensesAccountViewModel: ObservableObject {
    @Published var expensesAccount = ExpensesAccount.shared
    private let wealthEngine = WealthEngineManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes and update wealth engine calculations
        expensesAccount.$transactions
            .sink { _ in
                // The wealth engine will automatically recalculate when it observes changes
            }
            .store(in: &cancellables)
    }
    
    var currentBalance: Double {
        expensesAccount.netBalance
    }
    
    var monthlyAverage: Double {
        expensesAccount.averageExpensesPerPeriod // Now returns monthly average
    }
    
    var expenseGrowthRate: Double {
        // Calculate growth rate from recent periods using date-based filtering
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        let recentExpenses = expensesAccount.totalDebitsForDateRange(from: threeMonthsAgo, to: Date())
        let olderExpenses = expensesAccount.totalDebitsForDateRange(from: sixMonthsAgo, to: threeMonthsAgo)
        
        guard olderExpenses > 0 else { return 0 }
        return (recentExpenses - olderExpenses) / olderExpenses
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
