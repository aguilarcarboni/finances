import Foundation

struct Asset: Identifiable {
    var id: UUID
    var name: String
    var type: String
    var purchaseDate: Date
    var purchasePrice: Double
    var downPayment: Double
    var interestRate: Double
    var loanTermYears: Int
    var currentMarketValue: Double?
    var customDepreciationRate: Double?
    var expenseCategory: String // Category name in ExpensesAccount for tracking actual payments
}