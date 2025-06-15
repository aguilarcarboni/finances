import Foundation
import Combine

class AssetsManager: ObservableObject {

    @Published var assets: [Asset] = []
    
    static let shared = AssetsManager()
    
    private init() {
        loadMockAssets()
    }
    
    private func loadMockAssets() {

        let macbook = Asset(
            name: "Macbook Air M3",
            type: "Computer",
            category: .tangible,
            acquisitionDate: Date(timeIntervalSince1970: 1719859200), // June 2024
            acquisitionPrice: 871190,
            currentMarketValue: 562948,
        )
        addAsset(macbook)

        // Add the user's house (paid off loan from years ago)
        let house = Asset(
            name: "Family Home",
            type: "House",
            category: .tangible,
            acquisitionDate: Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date(),
            acquisitionPrice: 58000000, // 58 million colones original loan
            currentMarketValue: 75000000, // Estimated current value - user can adjust
            customDepreciationRate: 0.03, // 3% appreciation annually
            expenseCategory: "Housing",
            loanAmount: 58000000,
            interestRate: 8.5, // Typical Costa Rica mortgage rate
            loanTermYears: 20,
            downPayment: 5000000 // Estimated down payment
        )
        
        // Mark the house loan as paid off
        var paidOffHouse = house
        paidOffHouse.markLoanAsPaidOff(on: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date())
        //addAsset(paidOffHouse)
        
        // Add the Nissan Magnite car (current loan)
        let _ = Asset(
            name: "Nissan Magnite",
            type: "Car",
            category: .tangible,
            acquisitionDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            acquisitionPrice: 12823500, // 24,900 USD * 515 CRC
            currentMarketValue: 12000000, // 22,900 USD * 515 CRC (slight depreciation)
            customDepreciationRate: -0.15, // 15% annual depreciation
            expenseCategory: "Debt",
            loanAmount: 9733500, // Loan amount after down payment
            interestRate: 7.5,
            loanTermYears: 8,
            downPayment: 3090000 // 6,000 USD * 515 CRC
        )
        //addAsset(car)
        
        // Add an example business asset (future business loan)
        let _ = Asset(
            name: "Tech Consulting Business",
            type: "Business",
            category: .intangible,
            acquisitionDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            acquisitionPrice: 5000000, // Initial investment/setup costs
            currentMarketValue: 7500000, // Growing business value
            customDepreciationRate: 0.08, // 8% annual growth
            expenseCategory: "Business"
        )
        //addAsset(business)
        
        // Add an example of intellectual property
        let _ = Asset(
            name: "Software Patent",
            type: "Intellectual Property",
            category: .intangible,
            acquisitionDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
            acquisitionPrice: 2000000, // Cost to develop and file
            currentMarketValue: 2200000, // Current estimated value
            customDepreciationRate: -0.05, // Slow depreciation over time
            expenseCategory: "Research & Development"
        )
        //addAsset(patent)
    }
    
    // MARK: - Portfolio Financial Metrics
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
        let activeLoans = assets.filter { $0.hasActiveLoan }
        guard !activeLoans.isEmpty else { return 0 }
        
        let totalLoanAmount = activeLoans.reduce(0) { total, asset in
            total + asset.loanAmount
        }
        guard totalLoanAmount > 0 else { return 0 }
        
        let weightedInterestSum = activeLoans.reduce(0) { total, asset in
            total + (asset.interestRate * asset.loanAmount)
        }
        
        return weightedInterestSum / totalLoanAmount
    }
    
    var netWorth: Double {
        totalEquity
    }
    
    var loanToValueRatio: Double {
        guard totalAssetsValue > 0 else { return 0 }
        return totalDebt / totalAssetsValue
    }
    
    var loanToValueRatioPercentage: Double {
        loanToValueRatio * 100
    }
    
    var totalAcquisitionPrice: Double {
        assets.reduce(0) { total, asset in
            total + asset.acquisitionPrice
        }
    }
    
    var totalAppreciation: Double {
        assets.reduce(0) { total, asset in
            total + asset.totalAppreciation
        }
    }
    
    var appreciationRate: Double {
        guard totalAcquisitionPrice > 0 else { return 0 }
        return totalAppreciation / totalAcquisitionPrice
    }
    
    var appreciationRatePercentage: Double {
        appreciationRate * 100
    }
    
    // MARK: - Asset Categories
    var tangibleAssets: [Asset] {
        assets.filter { $0.category == .tangible }
    }
    
    var intangibleAssets: [Asset] {
        assets.filter { $0.category == .intangible }
    }
    
    var assetsWithActiveLoans: [Asset] {
        assets.filter { $0.hasActiveLoan }
    }
    
    var assetsWithPaidOffLoans: [Asset] {
        assets.filter { $0.loanStatus == .paidOff }
    }
    
    var assetsWithoutLoans: [Asset] {
        assets.filter { $0.loanStatus == .noLoan }
    }
    
    // MARK: - Portfolio Analysis
    var assetsAtRisk: [Asset] {
        assets.filter { $0.isAtRisk }
    }
    
    var highPerformingAssets: [Asset] {
        assets.filter { asset in
            asset.appreciationRate > 0.1 && asset.equity > 0
        }
    }
    
    var underwaterAssets: [Asset] {
        assets.filter { $0.isUnderwater }
    }
    
    var appreciatingAssets: [Asset] {
        assets.filter { $0.totalAppreciation > 0 }
    }
    
    var depreciatingAssets: [Asset] {
        assets.filter { $0.totalAppreciation < 0 }
    }
    
    // MARK: - Financial Health Scores
    var portfolioHealthScore: Double {
        let positiveEquityAssets = assets.filter { $0.equity >= 0 }.count
        let totalAssets = assets.count
        guard totalAssets > 0 else { return 1.0 }
        
        let equityScore = Double(positiveEquityAssets) / Double(totalAssets)
        let ltvScore = min(1.0, max(0.0, 1.0 - (loanToValueRatio - 0.5) / 0.3)) // Optimal at 50% LTV
        let appreciationScore = min(1.0, max(0.0, 1.0 + appreciationRate)) // Positive appreciation is good
        
        return (equityScore + ltvScore + appreciationScore) / 3.0
    }
    
    var portfolioHealthScorePercentage: Double {
        portfolioHealthScore * 100
    }
    
    // MARK: - Payoff Analysis
    func payoffAnalysis(for asset: Asset, extraPayment: Double = 0) -> (monthsSaved: Int, interestSaved: Double) {
        guard asset.hasActiveLoan, asset.remainingLoanBalance > 0 else { return (0, 0) }
        return asset.payoffAnalysis(extraPayment: extraPayment)
    }
    
    // MARK: - Portfolio Optimization
    func getOptimalPayoffOrder() -> [Asset] {
        // Sort by interest rate (avalanche method) for mathematical optimization
        return assetsWithActiveLoans.sorted { $0.interestRate > $1.interestRate }
    }
    
    func getEmotionalPayoffOrder() -> [Asset] {
        // Sort by remaining balance (snowball method) for psychological wins
        return assetsWithActiveLoans.sorted { $0.remainingLoanBalance < $1.remainingLoanBalance }
    }
    
    func getFlipPriorityOrder() -> [Asset] {
        // Sort by equity/value ratio and appreciation risk
        return assets.sorted { first, second in
            let firstScore = (first.equity / max(first.currentValue, 1)) + first.appreciationRate
            let secondScore = (second.equity / max(second.currentValue, 1)) + second.appreciationRate
            return firstScore < secondScore
        }
    }
    
    // MARK: - Asset Management
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
            assets[index].updateMarketValue(newValue)
        }
    }
    
    func markLoanAsPaidOff(for assetId: UUID, on date: Date = Date()) {
        if let index = assets.firstIndex(where: { $0.id == assetId }) {
            assets[index].markLoanAsPaidOff(on: date)
        }
    }
    
    // MARK: - Reporting & Analytics
    func getAssetsByType() -> [String: [Asset]] {
        Dictionary(grouping: assets, by: { $0.type })
    }
    
    func getAssetsByCategory() -> [AssetCategory: [Asset]] {
        Dictionary(grouping: assets, by: { $0.category })
    }
    
    func getAssetsByLoanStatus() -> [LoanStatus: [Asset]] {
        Dictionary(grouping: assets, by: { $0.loanStatus })
    }
    
    func getAssetsByPerformance() -> (performing: [Asset], underperforming: [Asset]) {
        let performing = assets.filter { $0.appreciationRate > 0 && $0.equity > 0 }
        let underperforming = assets.filter { $0.appreciationRate < -0.1 || $0.isUnderwater }
        return (performing: performing, underperforming: underperforming)
    }
    
    func getMonthlyPaymentBreakdown() -> [(asset: Asset, payment: Double, interestPortion: Double, principalPortion: Double)] {
        return assetsWithActiveLoans.map { asset in
            let monthlyRate = asset.interestRate / 100 / 12
            let interestPortion = asset.remainingLoanBalance * monthlyRate
            let principalPortion = asset.monthlyPayment - interestPortion
            return (asset: asset, payment: asset.monthlyPayment, interestPortion: interestPortion, principalPortion: principalPortion)
        }
    }
    
    // MARK: - Summary Statistics
    var portfolioSummary: (
        totalValue: Double,
        totalDebt: Double,
        netWorth: Double,
        monthlyPayments: Double,
        avgInterestRate: Double,
        healthScore: Double,
        assetsCount: Int,
        activeLoansCount: Int
    ) {
        return (
            totalValue: totalAssetsValue,
            totalDebt: totalDebt,
            netWorth: netWorth,
            monthlyPayments: totalMonthlyPayments,
            avgInterestRate: averageInterestRate,
            healthScore: portfolioHealthScore,
            assetsCount: assets.count,
            activeLoansCount: assetsWithActiveLoans.count
        )
    }
} 
