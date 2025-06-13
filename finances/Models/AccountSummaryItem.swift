import Foundation

struct AccountSummaryItem: Codable, Identifiable {
    var id: String { tag + account + currency + modelCode }
    let account: String
    let currency: String
    let modelCode: String
    let tag: String
    let value: String
} 