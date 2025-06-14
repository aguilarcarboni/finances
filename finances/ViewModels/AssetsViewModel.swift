import Foundation
import Combine

class AssetsViewModel: ObservableObject {
    @Published var assets: [Asset] = [
        Asset(
            id: UUID(),
            name: "Nissan Magnite",
            type: "Car",
            purchaseDate: Date(timeIntervalSince1970: 1746142058),
            purchasePrice: 24900.00,
            downPayment: 6000.00,
            interestRate: 7.5,
            loanTermYears: 8,
            currentMarketValue: 22400.00,
            customDepreciationRate: nil,
            expenseCategory: "Debt"
        )
    ]
    
    // MARK: - Computed Properties
    var totalAssetsValue: Double {
        assets.reduce(0) { total, asset in
            total + asset.currentValue
        }
    }
    
    var totalDebt: Double {
        assets.reduce(0) { total, asset in
            total + asset.remainingLoanBalance
        }
    }
    
    var totalEquity: Double {
        assets.reduce(0) { total, asset in
            total + asset.equity
        }
    }
    
    var totalMonthlyPayments: Double {
        assets.reduce(0) { total, asset in
            total + asset.monthlyPayment
        }
    }
    
    var averageInterestRate: Double {
        let totalLoanAmount = assets.reduce(0) { total, asset in
            total + asset.loanAmount
        }
        guard totalLoanAmount > 0 else { return 0 }
        
        let weightedInterestSum = assets.reduce(0) { total, asset in
            total + (asset.interestRate * asset.loanAmount)
        }
        
        return weightedInterestSum / totalLoanAmount
    }
    
    // MARK: - Asset Analysis
    var assetsAtRisk: [Asset] {
        assets.filter { asset in
            asset.equity < 0 || asset.totalDepreciation / asset.purchasePrice > 0.3
        }
    }
    
    var highPerformingAssets: [Asset] {
        assets.filter { asset in
            asset.equity > 0 && asset.equity / asset.currentValue > 0.5
        }
    }
    
    // MARK: - Payoff Analysis
    func payoffAnalysis(for asset: Asset, extraPayment: Double = 0) -> (monthsSaved: Int, interestSaved: Double) {
        guard asset.remainingLoanBalance > 0 else { return (0, 0) }
        
        let monthlyRate = asset.interestRate / 100 / 12
        let currentPayment = asset.monthlyPayment
        let newPayment = currentPayment + extraPayment
        let remainingBalance = asset.remainingLoanBalance
        
        // Calculate time to payoff with current payment
        let currentMonths = calculatePayoffTime(balance: remainingBalance, payment: currentPayment, rate: monthlyRate)
        
        // Calculate time to payoff with extra payment
        let newMonths = calculatePayoffTime(balance: remainingBalance, payment: newPayment, rate: monthlyRate)
        
        let monthsSaved = currentMonths - newMonths
        let currentTotalInterest = (currentPayment * Double(currentMonths)) - remainingBalance
        let newTotalInterest = (newPayment * Double(newMonths)) - remainingBalance
        let interestSaved = currentTotalInterest - newTotalInterest
        
        return (monthsSaved: monthsSaved, interestSaved: interestSaved)
    }
    
    private func calculatePayoffTime(balance: Double, payment: Double, rate: Double) -> Int {
        guard payment > balance * rate else { return Int.max } // Payment less than interest
        
        let months = -log(1 - (balance * rate / payment)) / log(1 + rate)
        return Int(months.rounded(.up))
    }
    
    // MARK: - Asset Management Methods
    func addAsset(_ asset: Asset) {
        assets.append(asset)
    }
    
    func removeAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
    }
    
    func updateAsset(_ asset: Asset) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index] = asset
        }
    }
    
    func updateMarketValue(for assetId: UUID, newValue: Double) {
        if let index = assets.firstIndex(where: { $0.id == assetId }) {
            var updatedAsset = assets[index]
            updatedAsset.currentMarketValue = newValue
            assets[index] = updatedAsset
        }
    }
} 