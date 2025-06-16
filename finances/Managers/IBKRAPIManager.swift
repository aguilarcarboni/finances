import Foundation
import Combine

class IBKRAPIManager: ObservableObject {
    static let shared = IBKRAPIManager()
    
    private let baseURL = "http://192.168.1.43:3333"
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
    
    // MARK: - API Calls
    
    func getAccountSummary() async throws -> [IBKRAccountSummaryItem] {
        try await makeAPICall(endpoint: "/account/summary")
    }
    
    func getPositions() async throws -> [IBKRPosition] {
        try await makeAPICall(endpoint: "/account/positions")
    }
    
    func getOpenOrders() async throws -> [IBKROrder] {
        try await makeAPICall(endpoint: "/orders/open-orders")
    }
    
    func getCompletedOrders() async throws -> [IBKROrder] {
        try await makeAPICall(endpoint: "/orders/completed-orders")
    }
    
    // MARK: - Market Data API Calls
    
    func getLatestStockPrice(symbol: String) async throws -> StockPriceResponse {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/market/latest-price/stock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["symbol": symbol]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw IBKRAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(StockPriceResponse.self, from: data)
    }
    
    func getHistoricalStockPrice(symbol: String, period: String) async throws -> [String: Any] {
        guard let accessToken = accessToken else {
            throw IBKRAPIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/market/historical-price/stock")!
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
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IBKRAPIError.decodingFailed
        }
        
        return jsonObject
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
