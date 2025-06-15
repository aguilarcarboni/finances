import Foundation
import Combine

class AssetsViewModel: ObservableObject {
    @Published var assetsManager = AssetsManager.shared
    private let wealthEngine = WealthEngineManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes and update wealth engine calculations
        assetsManager.$assets
            .sink { _ in
                // The wealth engine will automatically recalculate when it observes changes
            }
            .store(in: &cancellables)
    }
    
    var totalValue: Double {
        assetsManager.totalAssetsValue
    }
    
    var totalEquity: Double {
        assetsManager.totalEquity
    }
    
    var totalDebt: Double {
        assetsManager.totalDebt
    }
    
    var summaryItems: [AccountSummaryItem] {
        [
            AccountSummaryItem(
                title: "Total Assets Value",
                subtitle: nil,
                amount: totalValue,
                trend: nil,
                icon: "house.fill",
                color: "purple"
            ),
            AccountSummaryItem(
                title: "Total Equity",
                subtitle: "Assets - Debt",
                amount: totalEquity,
                trend: nil,
                icon: "chart.line.uptrend.xyaxis",
                color: "green"
            ),
            AccountSummaryItem(
                title: "Total Debt",
                subtitle: nil,
                amount: totalDebt,
                trend: nil,
                icon: "creditcard.fill",
                color: "red"
            )
        ]
    }
} 