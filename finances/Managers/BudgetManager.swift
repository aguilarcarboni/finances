import SwiftUI
import Foundation
import Combine

class BudgetManager: ObservableObject {
    
    @Published var categories: [BudgetCategory] = [
        BudgetCategory(name: "Debt", budget: 90000),
        BudgetCategory(name: "Subscriptions", budget: 50000),
        BudgetCategory(name: "Transportation", budget: 40000),
        BudgetCategory(name: "Savings", budget: 100000),
        BudgetCategory(name: "Misc", budget: 65000),
    ]
    
    static let shared = BudgetManager()
    
    private init() {}
    
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.budget }
    }
    
    func budgetForCategory(_ categoryName: String) -> Double {
        categories.first { $0.name == categoryName }?.budget ?? 0
    }
}
