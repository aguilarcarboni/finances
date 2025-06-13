import Foundation
import Combine

struct TokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
}

@MainActor
class InvestmentsViewModel: ObservableObject {
    @Published var items: [AccountSummaryItem] = []
    @Published var isLoading = false
    @Published var error: String?

    var url = "http://10.4.178.146:5000"
    func fetchAccountSummary() async {
        isLoading = true
        error = nil
        do {
            // 1. Get token
            let tokenURL = URL(string: url + "/token")!
            var tokenRequest = URLRequest(url: tokenURL)
            tokenRequest.httpMethod = "POST"
            tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let tokenBody = ["token": "admin", "scopes": "all"]
            tokenRequest.httpBody = try JSONEncoder().encode(tokenBody)
            let (tokenData, _) = try await URLSession.shared.data(for: tokenRequest)
            if let tokenString = String(data: tokenData, encoding: .utf8) {
                print("[InvestmentsViewModel] Token response: \(tokenString)")
            }
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: tokenData)
            let accessToken = tokenResponse.access_token

            // 2. Get account summary
            let summaryURL = URL(string: url + "/trading/account/summary")!
            var summaryRequest = URLRequest(url: summaryURL)
            summaryRequest.httpMethod = "POST"
            summaryRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            summaryRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            summaryRequest.httpBody = try JSONEncoder().encode([String: String]())
            let (summaryData, _) = try await URLSession.shared.data(for: summaryRequest)
            if let summaryString = String(data: summaryData, encoding: .utf8) {
                print("[InvestmentsViewModel] Summary response: \(summaryString)")
            }
            let items = try JSONDecoder().decode([AccountSummaryItem].self, from: summaryData)
            self.items = items
        } catch {
            print("[InvestmentsViewModel] Error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
} 
