import Foundation
import Combine

class SavingsViewModel: ObservableObject {
    @Published var savingsAccount = SavingsAccount.shared
    @Published var expensesAccount = ExpensesAccount.shared
    
    // All savings logic is now properly handled in SavingsAccount
    // ViewModel just provides convenient access to the account data
    
    var savingsGrowthData: [(period: String, balance: Double)] {
        savingsAccount.savingsGrowthData
    }
    
    var totalSavingsBalance: Double {
        savingsAccount.totalSavingsBalance
    }
    
    var emergencyFundProgress: Double {
        savingsAccount.emergencyFundProgress
    }
    
    var emergencyFundProgressPercentage: Double {
        savingsAccount.emergencyFundProgressPercentage
    }
    
    var emergencyFundRemaining: Double {
        savingsAccount.emergencyFundRemaining
    }
    
    var isEmergencyFundComplete: Bool {
        savingsAccount.isEmergencyFundComplete
    }
    
    var excessSavings: Double {
        savingsAccount.excessSavings
    }
    
    var savingsCategories: [(name: String, amount: Double, percentage: Double)] {
        savingsAccount.savingsCategories
    }
    
    var transferValidation: (isValid: Bool, message: String) {
        savingsAccount.validateTransfersWithExpenses(expensesAccount)
    }
}
