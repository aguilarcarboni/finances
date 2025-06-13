import Foundation
import Combine

class ExpensesAccountViewModel: ObservableObject {
    @Published var expensesAccount = ExpensesAccount.shared
    
    func debitsForCategory(_ category: BudgetCategory) -> Double {
        expensesAccount.debitsForCategory(category.name)
    }
}
