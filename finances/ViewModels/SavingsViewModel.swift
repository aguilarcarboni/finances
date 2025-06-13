import Foundation
import Combine

class SavingsViewModel: ObservableObject {
    @Published var savingsAccount = SavingsAccount.shared
    @Published var expensesAccount = ExpensesAccount.shared
    
    // Emergency Fund Target
    let emergencyFundTarget: Double = 250_000
    
    var savingsGrowthData: [(period: String, balance: Double)] {
        var runningBalance: Double = 0
        return savingsAccount.biweeklyPeriods.map { period in
            runningBalance += period.netBalance
            return (period: period.dateRange, balance: runningBalance)
        }
    }
    
    var totalSavingsBalance: Double {
        savingsGrowthData.last?.balance ?? 0
    }
    
    var emergencyFundProgress: Double {
        min(totalSavingsBalance / emergencyFundTarget, 1.0)
    }
    
    var emergencyFundProgressPercentage: Double {
        emergencyFundProgress * 100
    }
    
    var emergencyFundRemaining: Double {
        max(emergencyFundTarget - totalSavingsBalance, 0)
    }
    
    var isEmergencyFundComplete: Bool {
        totalSavingsBalance >= emergencyFundTarget
    }
    
    var excessSavings: Double {
        max(totalSavingsBalance - emergencyFundTarget, 0)
    }
    
    var savingsCategories: [(name: String, amount: Double, percentage: Double)] {
        guard isEmergencyFundComplete && excessSavings > 0 else { return [] }
        
        let categories = [
            ("Trips", 0.5),
            ("Long term", 0.5)
        ]
        
        return categories.map { (name, percentage) in
            let amount = excessSavings * percentage
            return (name: name, amount: amount, percentage: percentage)
        }
    }
    
    var transferValidation: (isValid: Bool, message: String) {
        let expensesSavingsTransfers = expensesAccount.biweeklyPeriods.reduce(0.0) { total, period in
            total + period.debitsForCategory("Savings")
        }
        
        let savingsIncomingTransfers = savingsAccount.biweeklyPeriods.reduce(0.0) { total, period in
            total + period.creditsForCategory("Emergency Fund") // Where the transfers go
        }
        
        let isValid = abs(expensesSavingsTransfers - savingsIncomingTransfers) < 1.0 // Allow for rounding
        let message = isValid 
            ? "✅ Transfers match perfectly" 
            : "⚠️ Transfer mismatch: ₡\(Int(abs(expensesSavingsTransfers - savingsIncomingTransfers)).formatted()) difference"
        
        return (isValid, message)
    }
}
