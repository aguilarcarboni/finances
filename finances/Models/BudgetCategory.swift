import Foundation

struct BudgetCategory: Identifiable {
    let id = UUID()
    let name: String
    let budget: Double
}