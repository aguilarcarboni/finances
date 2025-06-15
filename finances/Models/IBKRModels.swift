import Foundation

// MARK: - IBKR API Response Models

struct IBKRAccountSummaryItem: Codable {
    let account: String
    let currency: String
    let modelCode: String
    let tag: String
    let value: String
}

struct IBKRPosition: Codable {
    let avgCost: Double
    let contract: IBKRContract
    let position: Double
}

struct IBKRContract: Codable {
    let comboLegs: [ComboLeg]
    let comboLegsDescrip: String
    let conId: Int
    let currency: String
    let deltaNeutralContract: DeltaNeutralContract?
    let description: String
    let exchange: String
    let includeExpired: Bool
    let issuerId: String
    let lastTradeDateOrContractMonth: String
    let localSymbol: String
    let multiplier: String
    let primaryExchange: String
    let right: String
    let secId: String
    let secIdType: String
    let secType: String
    let strike: Double
    let symbol: String
    let tradingClass: String
}

// Simple structs to handle nested objects without recursion
struct ComboLeg: Codable {
    // Empty for now as the API returns empty arrays
}

struct DeltaNeutralContract: Codable {
    let conId: Int?
    let delta: Double?
    let price: Double?
}

struct IBKROrder: Codable {
    let contract: IBKRContract
    let filled: Double
    let isActive: Bool
    let isDone: Bool
    let orderStatus: IBKROrderStatus
    let remaining: Double
}

struct IBKROrderStatus: Codable {
    let avgFillPrice: Double
    let clientId: Int
    let filled: Double
    let lastFillPrice: Double
    let mktCapPrice: Double
    let orderId: Int
    let parentId: Int
    let permId: Int
    let remaining: Double
    let status: String
    let whyHeld: String
}

// MARK: - Market Data API Response Models

struct StockPriceResponse: Codable {
    let latestPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case latestPrice = "latest_price"
    }
}

struct WatchlistItem: Identifiable {
    let id = UUID()
    let symbol: String
    var currentPrice: Double = 0.0
    var dayChange: Double = 0.0
    var dayChangePercent: Double = 0.0
    var lastUpdated: Date?
    var isLoading: Bool = false
    var error: String?
    
    init(symbol: String) {
        self.symbol = symbol
    }
}

// MARK: - Processed Investment Data Models

struct InvestmentPosition: Identifiable {
    let id = UUID()
    let symbol: String
    let localSymbol: String
    let secType: String
    let position: Double
    let avgCost: Double
    let currentValue: Double
    let unrealizedPnL: Double
    let currency: String
    let multiplier: Double
    
    var marketValue: Double {
        abs(position) * currentValue * multiplier
    }
    
    var pnLPercentage: Double {
        guard avgCost > 0 else { return 0 }
        return (unrealizedPnL / (abs(position) * avgCost * multiplier)) * 100
    }
}

struct InvestmentSummary {
    let netLiquidation: Double
    let totalCashValue: Double
    let stockMarketValue: Double
    let optionMarketValue: Double
    let futuresPNL: Double
    let unrealizedPnL: Double
    let realizedPnL: Double
    let availableFunds: Double
    let buyingPower: Double
    let dayChange: Double
    
    var totalMarketValue: Double {
        stockMarketValue + optionMarketValue
    }
    
    var dayChangePercentage: Double {
        let previousValue = netLiquidation - dayChange
        guard previousValue > 0 else { return 0 }
        return (dayChange / previousValue) * 100
    }
} 