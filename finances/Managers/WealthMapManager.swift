import Foundation
import SwiftUI
import Combine

class WealthMapManager: ObservableObject {
    static let shared = WealthMapManager()
    
    @Published var wealthMapData: WealthMapData = WealthMapData()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    private let expensesAccount = ExpensesAccount.shared
    private let savingsAccount = SavingsAccount.shared
    private let investmentsAccount = InvestmentsAccount.shared
    private let assetsManager = AssetsManager.shared
    
    private init() {
        setupObservers()
        generateWealthMap()
    }
    
    private func setupObservers() {
        // Observe changes in all accounts and regenerate wealth map
        Publishers.CombineLatest4(
            expensesAccount.$transactions,
            savingsAccount.$transactions,
            investmentsAccount.$_portfolioValue,
            assetsManager.$assets
        )
        .sink { [weak self] _, _, _, _ in
            self?.generateWealthMap()
        }
        .store(in: &cancellables)
    }
    
    private func generateWealthMap() {
        var nodes: [WealthMapNode] = []
        var connections: [WealthMapConnection] = []
        
        // Generate nodes and connections
        let accountNodes = generateAccountNodes()
        let assetNodes = generateAssetNodes()
        let debtNodes = generateDebtNodes()
        let incomeNodes = generateIncomeNodes()
        
        nodes.append(contentsOf: accountNodes)
        nodes.append(contentsOf: assetNodes)
        nodes.append(contentsOf: debtNodes)
        nodes.append(contentsOf: incomeNodes)
        
        // Generate connections
        connections.append(contentsOf: generateAccountConnections(nodes: nodes))
        connections.append(contentsOf: generateAssetConnections(nodes: nodes))
        connections.append(contentsOf: generateDebtConnections(nodes: nodes))
        connections.append(contentsOf: generateIncomeConnections(nodes: nodes))
        
        wealthMapData = WealthMapData(nodes: nodes, connections: connections)
    }
    
    // MARK: - Node Generation
    
    private func generateAccountNodes() -> [WealthMapNode] {
        var nodes: [WealthMapNode] = []
        
        // Expenses Account - Central position
        let expensesNode = WealthMapNode(
            title: "Expenses Account",
            subtitle: "Main Flow",
            amount: expensesAccount.netBalance,
            type: .account,
            position: CGPoint(x: 600, y: 400), // More central
            category: "Primary"
        )
        nodes.append(expensesNode)
        
        // Savings Account - To the right
        let savingsNode = WealthMapNode(
            title: "Savings Account",
            subtitle: "Emergency Fund",
            amount: savingsAccount.totalSavingsBalance,
            type: .account,
            position: CGPoint(x: 900, y: 400), // More spacing
            category: "Savings"
        )
        nodes.append(savingsNode)
        
        return nodes
    }
    
    private func generateAssetNodes() -> [WealthMapNode] {
        var nodes: [WealthMapNode] = []
        
        // Position assets in a row above the accounts, with proper spacing
        let startX: CGFloat = 300
        let spacing: CGFloat = 300 // Increased spacing
        
        for (index, asset) in assetsManager.assets.enumerated() {
            let assetNode = WealthMapNode(
                title: asset.name,
                subtitle: asset.type,
                amount: asset.currentValue,
                type: .asset,
                position: CGPoint(x: startX + CGFloat(index) * spacing, y: 200), // Higher up
                category: asset.category.rawValue
            )
            nodes.append(assetNode)
        }
        
        return nodes
    }
    
    private func generateDebtNodes() -> [WealthMapNode] {
        var nodes: [WealthMapNode] = []
        
        // Position debt nodes to the left of corresponding assets
        let startX: CGFloat = 150
        let spacing: CGFloat = 300 // Match asset spacing
        
        var debtIndex = 0
        for (assetIndex, asset) in assetsManager.assets.enumerated() {
            if asset.hasActiveLoan {
                let debtNode = WealthMapNode(
                    title: "\(asset.name) Debt",
                    subtitle: "Loan",
                    amount: asset.remainingLoanBalance,
                    type: .debt,
                    position: CGPoint(x: startX + CGFloat(assetIndex) * spacing, y: 80), // Above assets
                    category: "Debt"
                )
                nodes.append(debtNode)
                debtIndex += 1
            }
        }
        
        return nodes
    }
    
    private func generateIncomeNodes() -> [WealthMapNode] {
        var nodes: [WealthMapNode] = []
        
        // Position income nodes below accounts with proper spacing
        let startX: CGFloat = 300
        let spacing: CGFloat = 250 // Good spacing
        
        for (index, category) in expensesAccount.incomeBudget.enumerated() {
            if category.budget > 0 {
                let incomeNode = WealthMapNode(
                    title: category.name,
                    subtitle: "Income",
                    amount: category.budget,
                    type: .income,
                    position: CGPoint(x: startX + CGFloat(index) * spacing, y: 600), // Below accounts
                    category: "Income"
                )
                nodes.append(incomeNode)
            }
        }
        
        return nodes
    }
    
    // MARK: - Connection Generation
    
    private func generateAccountConnections(nodes: [WealthMapNode]) -> [WealthMapConnection] {
        var connections: [WealthMapConnection] = []
        
        guard let expensesNode = nodes.first(where: { $0.title == "Expenses Account" }),
              let savingsNode = nodes.first(where: { $0.title == "Savings Account" }),
              let investmentsNode = nodes.first(where: { $0.title == "Investments" }) else {
            return connections
        }
        
        // Expenses to Savings (based on "Savings" category transactions)
        let savingsAmount = expensesAccount.creditsForCategory("Savings")
        if savingsAmount > 0 {
            let savingsConnection = WealthMapConnection(
                fromNodeId: expensesNode.id,
                toNodeId: savingsNode.id,
                amount: savingsAmount,
                type: .transfer,
                frequency: "monthly",
                description: "Monthly Savings"
            )
            connections.append(savingsConnection)
        }
        
        // Savings to Investments
        let investmentTransfers = savingsAccount.totalDebits // Money going out of savings
        if investmentTransfers > 0 {
            let investmentConnection = WealthMapConnection(
                fromNodeId: savingsNode.id,
                toNodeId: investmentsNode.id,
                amount: investmentTransfers,
                type: .investment,
                frequency: "monthly",
                description: "Investment Transfers"
            )
            connections.append(investmentConnection)
        }
        
        return connections
    }
    
    private func generateAssetConnections(nodes: [WealthMapNode]) -> [WealthMapConnection] {
        var connections: [WealthMapConnection] = []
        
        guard let expensesNode = nodes.first(where: { $0.title == "Expenses Account" }) else {
            return connections
        }
        
        for asset in assetsManager.assets {
            if let assetNode = nodes.first(where: { $0.title == asset.name }) {
                // Asset payments (monthly loan payments)
                if asset.hasActiveLoan {
                    let paymentConnection = WealthMapConnection(
                        fromNodeId: expensesNode.id,
                        toNodeId: assetNode.id,
                        amount: asset.monthlyPayment,
                        type: .payment,
                        frequency: "monthly",
                        description: "Monthly Payment"
                    )
                    connections.append(paymentConnection)
                }
                
                // Asset appreciation/depreciation
                if asset.totalAppreciation != 0 {
                    let appreciationConnection = WealthMapConnection(
                        fromNodeId: assetNode.id,
                        toNodeId: assetNode.id, // Self-connection for value change
                        amount: asset.totalAppreciation,
                        type: asset.totalAppreciation > 0 ? .appreciation : .depreciation,
                        frequency: "annual",
                        description: asset.totalAppreciation > 0 ? "Value Appreciation" : "Value Depreciation"
                    )
                    connections.append(appreciationConnection)
                }
            }
        }
        
        return connections
    }
    
    private func generateDebtConnections(nodes: [WealthMapNode]) -> [WealthMapConnection] {
        var connections: [WealthMapConnection] = []
        
        for asset in assetsManager.assets {
            if asset.hasActiveLoan {
                if let debtNode = nodes.first(where: { $0.title == "\(asset.name) Debt" }),
                   let assetNode = nodes.first(where: { $0.title == asset.name }) {
                    
                    // Debt creates asset
                    let loanConnection = WealthMapConnection(
                        fromNodeId: debtNode.id,
                        toNodeId: assetNode.id,
                        amount: asset.loanAmount,
                        type: .loan,
                        frequency: "one-time",
                        description: "Loan Purchase"
                    )
                    connections.append(loanConnection)
                }
            }
        }
        
        return connections
    }
    
    private func generateIncomeConnections(nodes: [WealthMapNode]) -> [WealthMapConnection] {
        var connections: [WealthMapConnection] = []
        
        guard let expensesNode = nodes.first(where: { $0.title == "Expenses Account" }) else {
            return connections
        }
        
        for category in expensesAccount.incomeBudget {
            if category.budget > 0,
               let incomeNode = nodes.first(where: { $0.title == category.name && $0.type == .income }) {
                
                let incomeConnection = WealthMapConnection(
                    fromNodeId: incomeNode.id,
                    toNodeId: expensesNode.id,
                    amount: category.budget,
                    type: .income,
                    frequency: "monthly",
                    description: "Monthly Income"
                )
                connections.append(incomeConnection)
            }
        }
        
        return connections
    }
    
    // MARK: - Helper Methods
    
    func refreshWealthMap() {
        generateWealthMap()
    }
    
    func getNodeSummary() -> (totalAssets: Double, totalDebt: Double, monthlyIncome: Double, monthlyExpenses: Double) {
        let totalAssets = wealthMapData.nodes.filter { $0.type == .asset }.reduce(0) { $0 + $1.amount }
        let totalDebt = wealthMapData.nodes.filter { $0.type == .debt }.reduce(0) { $0 + $1.amount }
        let monthlyIncome = wealthMapData.nodes.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let monthlyExpenses = wealthMapData.connections.filter { $0.type == .payment }.reduce(0) { $0 + $1.amount }
        
        return (totalAssets: totalAssets, totalDebt: totalDebt, monthlyIncome: monthlyIncome, monthlyExpenses: monthlyExpenses)
    }
} 
