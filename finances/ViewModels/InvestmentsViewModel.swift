import Foundation
import Combine

@MainActor
class InvestmentsViewModel: ObservableObject {
    @Published var investmentsAccount = InvestmentsAccount.shared
    @Published var isLoading = false
    @Published var error: String?
    
    // Legacy properties for backward compatibility with the UI
    @Published var items: [AccountSummaryItem] = []
    
    init() {
        // Create account summary items from investment account data
        updateItems()
        
        // Listen for changes in investment account
        investmentsAccount.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateItems()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateItems() {
        items = [
            AccountSummaryItem(
                title: "Portfolio Value",
                subtitle: investmentsAccount.isConnectedToIBKR ? "Live Data" : "Offline",
                amount: investmentsAccount.rawPortfolioValue,
                trend: getTrend(for: investmentsAccount.offlineAwareDayChangePercentage),
                icon: "chart.line.uptrend.xyaxis",
                color: "green"
            ),
            AccountSummaryItem(
                title: "Unrealized P&L",
                subtitle: "Current Positions",
                amount: investmentsAccount.unrealizedGains,
                trend: getTrend(for: investmentsAccount.returnPercentage),
                icon: "arrow.up.right.circle",
                color: investmentsAccount.unrealizedGains >= 0 ? "green" : "red"
            )
        ]
    }
    
    private func getTrend(for percentage: Double) -> AccountSummaryItem.Trend {
        if percentage > 0 {
            return .up(percentage / 100)
        } else if percentage < 0 {
            return .down(percentage / 100)
        } else {
            return .neutral
        }
    }
    
    // MARK: - IBKR API Methods
    func connectToIBKR() async {
        isLoading = true
        error = nil
        
        do {
            try await investmentsAccount.connectToIBKR()
        } catch {
            self.error = "Failed to connect to IBKR: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func disconnectFromIBKR() {
        investmentsAccount.disconnectFromIBKR()
    }
    
    func refreshData() async {
        isLoading = true
        error = nil
        
        await investmentsAccount.syncWithIBKR()
        
        isLoading = false
    }
}
