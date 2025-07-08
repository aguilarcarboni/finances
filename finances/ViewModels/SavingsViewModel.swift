import Foundation
import Combine

class SavingsViewModel: ObservableObject {
    @Published var savingsAccount = SavingsAccount.shared
    @Published var transferValidation: (isValid: Bool, message: String) = (false, "")
    private let wealthEngine = WealthEngineManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // All savings logic is now properly handled in SavingsAccount
    // ViewModel just provides convenient access to the account data
    
    init() {
        // Observe changes and update wealth engine calculations
        savingsAccount.$transactions
            .sink { [weak self] _ in
                guard let self else { return }
                self.transferValidation = self.savingsAccount.validateTransfersWithExpenses(ExpensesAccount.shared)
                // Wealth engine observes separately
            }
            .store(in: &cancellables)

        transferValidation = savingsAccount.validateTransfersWithExpenses(ExpensesAccount.shared)
    }
}
