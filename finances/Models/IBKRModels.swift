import Foundation

// Custom Models
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

struct ComboLeg: Codable {
    // Empty for now as the API returns empty arrays
}

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

// IBKR Basic Models
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

struct IBKROrder: Codable {
    let contract: IBKRContract
    let filled: Double?
    let isActive: Bool?
    let isDone: Bool?
    let orderStatus: IBKROrderStatus
    let remaining: Double?
    
    // Computed properties with safe defaults
    var safefilled: Double {
        return filled ?? 0.0
    }
    
    var safeIsActive: Bool {
        return isActive ?? false
    }
    
    var safeIsDone: Bool {
        return isDone ?? false
    }
    
    var safeRemaining: Double {
        return remaining ?? 0.0
    }
}

struct IBKRPosition: Codable {
    let account: String
    let contract: IBKRContract
    let position: Double
    let avgCost: Double
}

// Market Data API Response Models  
struct IBKRBarData: Codable {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let average: Double
    let barCount: Int
}

struct StockPriceResponse: Codable {
    let ask: Double
    let askSize: Double
    let bid: Double
    let bidSize: Double
    let last: Double
    
    // Computed property to get the latest price (using 'last' as the latest traded price)
    var latestPrice: Double {
        return last
    }
}

// Account API Response Models
struct IBKRAccountSummaryItem: Codable {
    let account: String
    let currency: String
    let modelCode: String
    let tag: String
    let value: String
}

struct IBKRPortfolioItem: Codable {
    let contract: IBKRContract
    let position: Double
    let marketPrice: Double
    let marketValue: Double
    let averageCost: Double
    let unrealizedPNL: Double
    let realizedPNL: Double
    let account: String
}

struct IBKRPnlItem: Codable {
    let account: String
    let modelCode: String
    let dailyPnL: Double
    let unrealizedPnL: Double
    let realizedPnL: Double
}

struct IBKRPnLSingleItem: Codable {
    let account: String
    let modelCode: String
    let conId: Int
    let dailyPnL: Double
    let unrealizedPnL: Double
    let realizedPnL: Double
    let position: Int
    let value: Double
}

// Orders API Response Models
struct DeltaNeutralContract: Codable {
    let conId: Int?
    let delta: Double?
    let price: Double?
}

struct IBKROrderStatus: Codable {
    let avgFillPrice: Double?
    let clientId: Int?
    let filled: Double?
    let lastFillPrice: Double?
    let mktCapPrice: Double?
    let orderId: Int
    let parentId: Int?
    let permId: Int?
    let remaining: Double?
    let status: String
    let whyHeld: String?
    
    // Safe defaults
    var safeAvgFillPrice: Double {
        return avgFillPrice ?? 0.0
    }
    
    var safeClientId: Int {
        return clientId ?? 0
    }
    
    var safeFilled: Double {
        return filled ?? 0.0
    }
    
    var safeLastFillPrice: Double {
        return lastFillPrice ?? 0.0
    }
    
    var safeMktCapPrice: Double {
        return mktCapPrice ?? 0.0
    }
    
    var safeParentId: Int {
        return parentId ?? 0
    }
    
    var safePermId: Int {
        return permId ?? 0
    }
    
    var safeRemaining: Double {
        return remaining ?? 0.0
    }
    
    var safeWhyHeld: String {
        return whyHeld ?? ""
    }
}

// MARK: - New Order Request/Response Models

struct IBKROrderRequest: Codable {
    let symbol: String
    let action: String // BUY or SELL
    let orderType: String // MKT, LMT, etc.
    let totalQuantity: Double
    let lmtPrice: Double?
    let auxPrice: Double?
    let timeInForce: String? // DAY, GTC, etc.
    let account: String?
}

struct IBKROrderResponse: Codable {
    let orderId: Int
    let status: String
    let message: String?
}

struct IBKROrderStatusResponse: Codable {
    let orderId: Int
    let status: String
    let filled: Double
    let remaining: Double
    let avgFillPrice: Double
    let lastFillPrice: Double
    let parentId: Int
    let permId: Int
    let whyHeld: String
}

struct IBKRCancelOrderResponse: Codable {
    let orderId: Int
    let status: String
    let message: String?
}

struct IBKRExecutionDetail: Codable {
    let orderId: Int
    let clientId: Int
    let execId: String
    let time: String
    let acctNumber: String
    let exchange: String
    let side: String
    let shares: Double
    let price: Double
    let permId: Int
    let liquidation: Int
    let cumQty: Double
    let avgPrice: Double
    let orderRef: String
    let evRule: String
    let evMultiplier: Double
    let modelCode: String
    let lastLiquidity: Int
}

struct IBKRClosePositionsResponse: Codable {
    let message: String
    let ordersPlaced: Int
    let orderIds: [Int]
}