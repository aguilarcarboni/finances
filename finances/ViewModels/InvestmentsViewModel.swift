import Foundation
import Combine

struct TokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
}

enum IBKRError: Error, LocalizedError {
    case notImplemented(String)
    case connectionFailed(String)
    case authenticationFailed(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not Implemented: \(message)"
        case .connectionFailed(let message):
            return "Connection Failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication Failed: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

@MainActor
class InvestmentsViewModel: ObservableObject {
    @Published var investmentsAccount = InvestmentsAccount.shared
    @Published var isLoading = false
    @Published var error: String?
    
    // Legacy IBKR API properties (kept for future integration)
    @Published var items: [AccountSummaryItem] = []
    private var accessToken: String?
    
    // MARK: - IBKR API Methods
    func fetchAccountSummary() async {
        isLoading = true
        error = nil
        
        do {
            // Attempt to fetch real data from IBKR API
            // This will fail until proper IBKR API integration is implemented
            throw IBKRError.notImplemented("IBKR API integration not yet implemented")
            
        } catch {
            print("[InvestmentsViewModel] Error: \(error)")
            self.error = error.localizedDescription
            
            // Disconnect on API failure
            investmentsAccount.disconnectFromIBKR()
        }
        isLoading = false
    }
    
    // MARK: - Authentication
    private func authenticate() async throws {
        // Real IBKR authentication would happen here
        // For now, this will always fail until proper integration is implemented
        throw IBKRError.authenticationFailed("IBKR authentication not configured")
    }
    
    func connectToIBKR() async {
        do {
            try await authenticate()
            investmentsAccount.connectToIBKR()
            await fetchAccountSummary()
            await investmentsAccount.syncWithIBKR()
        } catch {
            self.error = "Failed to connect to IBKR: \(error.localizedDescription)"
            investmentsAccount.disconnectFromIBKR()
        }
    }
    
    func disconnectFromIBKR() {
        investmentsAccount.disconnectFromIBKR()
        accessToken = nil
        items = []
    }
    
    func refreshData() async {
        if investmentsAccount.isConnectedToIBKR {
            await fetchAccountSummary()
            await investmentsAccount.syncWithIBKR()
        }
    }
}
