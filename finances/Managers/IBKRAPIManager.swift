import Foundation
import Combine

class IBKRAPIManager: ObservableObject {
    static let shared = IBKRAPIManager()
    
    private let baseURL = "http://10.4.178.243:5000"
    private var accessToken: String?
    
    @Published var isConnected = false
    @Published var lastError: Error?
    
    private init() {}
    
    // MARK: - Authentication
    
    func authenticate(token: String = "admin") async throws {
        let url = URL(string: "\(baseURL)/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["token": token, "scopes": "all"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let token = response?["access_token"] as? String else {
            throw IBKRAPIError.authenticationFailed
        }
        
        self.accessToken = token
        await MainActor.run {
            self.isConnected = true
        }
    }
    
    // MARK: - Account API Calls
    
    func getAccountSummary() async throws -> [IBKRAccountSummaryItem] {
        try await makeAPICall(endpoint: "/account/summary")
    }
    
    func getPositions() async throws -> [IBKRPosition] {
        try await makeAPICall(endpoint: "/account/positions")
    }

    func getPortfolio() async throws -> [IBKRPortfolioItem] {
        try await makeAPICall(endpoint: "/account/portfolio")
    }

    func getPnl() async throws -> [IBKRPnlItem] {
        try await makeAPICall(endpoint: "/account/pnl")
    }

    func getPnlSingle() async throws -> [IBKRPnLSingleItem] {
        try await makeAPICall(endpoint: "/account/pnl-single")
    }
    
    // MARK: - Market Data API Calls
    
    func getLatestStockPrice(symbol: String) async throws -> StockPriceResponse {
        print("🔍 IBKRAPIManager: Getting latest stock price for symbol: \(symbol)")
        
        guard let accessToken = accessToken else {
            print("❌ IBKRAPIManager: Not authenticated")
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/market/latest/stock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["symbol": symbol]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 IBKRAPIManager: Sending request to \(url) with body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 IBKRAPIManager: Received response with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 IBKRAPIManager: Response data: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ IBKRAPIManager: Request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw IBKRAPIError.requestFailed
        }
        
        do {
            let result = try JSONDecoder().decode(StockPriceResponse.self, from: data)
            print("✅ IBKRAPIManager: Successfully decoded price response: \(result.latestPrice)")
            return result
        } catch {
            print("❌ IBKRAPIManager: Decoding failed: \(error)")
            throw IBKRAPIError.decodingFailed
        }
    }
    
    func getHistoricalStockPrice(symbol: String, period: String) async throws -> [IBKRBarData] {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/market/historical/stock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["symbol": symbol, "period": period]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode([IBKRBarData].self, from: data)
    }
    
    // MARK: - Orders API Calls
    
    func placeOrder(order: IBKROrderRequest) async throws -> IBKROrderResponse {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/orders/place-order")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(order)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(IBKROrderResponse.self, from: data)
    }

    func getOrderStatus(orderId: String) async throws -> IBKROrderStatusResponse {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/orders/order-status?orderId=\(orderId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(IBKROrderStatusResponse.self, from: data)
    }

    func cancelOrder(orderId: String) async throws -> IBKRCancelOrderResponse {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/orders/cancel-order")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["orderId": orderId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(IBKRCancelOrderResponse.self, from: data)
    }

    func getOpenOrders() async throws -> [IBKROrder] {
        try await makeAPICall(endpoint: "/orders/open-orders")
    }

    func getCompletedOrders() async throws -> [IBKROrder] {
        try await makeAPICall(endpoint: "/orders/completed-orders")
    }

    func getExecDetails() async throws -> [IBKRExecutionDetail] {
        try await makeAPICall(endpoint: "/orders/exec-details")
    }

    func closeAllPositions() async throws -> IBKRClosePositionsResponse {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/orders/close-all-positions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(IBKRClosePositionsResponse.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func makeAPICall<T: Codable>(endpoint: String) async throws -> T {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Data Processing
    
    func processAccountSummary(_ summaryItems: [IBKRAccountSummaryItem]) -> InvestmentSummary {
        var netLiquidation: Double = 0
        var totalCashValue: Double = 0
        var stockMarketValue: Double = 0
        var optionMarketValue: Double = 0
        var futuresPNL: Double = 0
        var unrealizedPnL: Double = 0
        var realizedPnL: Double = 0
        var availableFunds: Double = 0
        var buyingPower: Double = 0
        var previousDayEquity: Double = 0
        
        for item in summaryItems {
            guard let value = Double(item.value) else { continue }
            
            switch item.tag {
            case "NetLiquidation":
                netLiquidation = value
            case "TotalCashValue":
                totalCashValue = value
            case "StockMarketValue":
                stockMarketValue = value
            case "OptionMarketValue":
                optionMarketValue = value
            case "FuturesPNL":
                futuresPNL = value
            case "UnrealizedPnL":
                unrealizedPnL = value
            case "RealizedPnL":
                realizedPnL = value
            case "AvailableFunds":
                availableFunds = value
            case "BuyingPower":
                buyingPower = value
            case "PreviousDayEquityWithLoanValue":
                previousDayEquity = value
            default:
                break
            }
        }
        
        let dayChange = netLiquidation - previousDayEquity
        
        return InvestmentSummary(
            netLiquidation: netLiquidation,
            totalCashValue: totalCashValue,
            stockMarketValue: stockMarketValue,
            optionMarketValue: optionMarketValue,
            futuresPNL: futuresPNL,
            unrealizedPnL: unrealizedPnL,
            realizedPnL: realizedPnL,
            availableFunds: availableFunds,
            buyingPower: buyingPower,
            dayChange: dayChange
        )
    }
    
    func processPositions(_ positions: [IBKRPosition]) -> [InvestmentPosition] {
        return positions.map { position in
            let multiplier = Double(position.contract.multiplier) ?? 1.0
            let currentValue = position.avgCost // For now, using avgCost as current value
            let unrealizedPnL = (currentValue - position.avgCost) * position.position * multiplier
            
            return InvestmentPosition(
                symbol: position.contract.symbol,
                localSymbol: position.contract.localSymbol,
                secType: position.contract.secType,
                position: position.position,
                avgCost: position.avgCost,
                currentValue: currentValue,
                unrealizedPnL: unrealizedPnL,
                currency: position.contract.currency,
                multiplier: multiplier
            )
        }
    }
    
    func disconnect() {
        accessToken = nil
        isConnected = false
    }
}

// MARK: - Error Types

enum IBKRAPIError: LocalizedError {
    case authenticationFailed
    case notAuthenticated
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with IBKR API"
        case .notAuthenticated:
            return "Not authenticated with IBKR API"
        case .requestFailed:
            return "API request failed"
        case .decodingFailed:
            return "Failed to decode API response"
        }
    }
} 
