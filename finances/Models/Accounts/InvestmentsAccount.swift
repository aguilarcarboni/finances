import SwiftUI
import Foundation
import Combine

class InvestmentsAccount: ObservableObject, Account {
    
    @Published var transactions: [Transaction] = []
    
    static let shared = InvestmentsAccount()

    @Published var budget: [BudgetCategory] = [
        BudgetCategory(name: "Stocks", budget: 150000),
        BudgetCategory(name: "ETFs", budget: 100000),
        BudgetCategory(name: "Bonds", budget: 50000),
        BudgetCategory(name: "Futures", budget: 25000),
        BudgetCategory(name: "Options", budget: 25000),
        BudgetCategory(name: "Crypto", budget: 30000),
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

    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize with empty data - will only be populated when connected to IBKR
        transactions = []
        _portfolioValue = 0
        dayChange = 0
        dayChangePercentage = 0
        lastSyncDate = nil
    }
    
    private func clearData() {
        _portfolioValue = 0
        dayChange = 0
        dayChangePercentage = 0
        lastSyncDate = nil
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
    
    // MARK: - Investment-specific Methods
    func updatePortfolioValue(_ newValue: Double) {
        let previousValue = _portfolioValue
        _portfolioValue = newValue
        dayChange = newValue - previousValue
        dayChangePercentage = previousValue > 0 ? ((newValue - previousValue) / previousValue) * 100 : 0
        lastSyncDate = Date()
    }

} 
