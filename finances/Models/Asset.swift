import Foundation

enum AssetCategory: String, CaseIterable {
    case tangible = "Tangible"
    case intangible = "Intangible"
    
    var description: String {
        switch self {
        case .tangible:
            return "Physical assets like houses, cars, equipment"
        case .intangible:
            return "Non-physical assets like businesses, loans, intellectual property"
        }
    }
}

enum LoanStatus: String, CaseIterable {
    case noLoan = "No Loan"
    case activeLoan = "Active Loan"
    case paidOff = "Paid Off"
}

struct LoanDetails {
    var originalAmount: Double
    var interestRate: Double
    var termYears: Int
    var startDate: Date
    var downPayment: Double
    var status: LoanStatus
    var paidOffDate: Date?
    
    init(originalAmount: Double, interestRate: Double, termYears: Int, startDate: Date, downPayment: Double = 0) {
        self.originalAmount = originalAmount
        self.interestRate = interestRate
        self.termYears = termYears
        self.startDate = startDate
        self.downPayment = downPayment
        self.status = .activeLoan
        self.paidOffDate = nil
    }
    
    mutating func markAsPaidOff(on date: Date = Date()) {
        self.status = .paidOff
        self.paidOffDate = date
    }
}

struct RevenueDetails {
    var monthlyRevenueTarget: Double
    var revenueGenerationRate: Double // Probability of generating revenue (0.0 to 1.0)
    var variabilityFactor: Double // How much the revenue can vary (0.0 to 1.0)
    var isRevenueGenerating: Bool
    
    init(monthlyTarget: Double, generationRate: Double = 0.8, variabilityFactor: Double = 0.3) {
        self.monthlyRevenueTarget = monthlyTarget
        self.revenueGenerationRate = max(0.0, min(1.0, generationRate))
        self.variabilityFactor = max(0.0, min(1.0, variabilityFactor))
        self.isRevenueGenerating = monthlyTarget > 0
    }
}

struct Asset: Identifiable {
    var id: UUID
    var name: String
    var type: String
    var category: AssetCategory
    var acquisitionDate: Date
    var acquisitionPrice: Double
    var currentMarketValue: Double?
    var customDepreciationRate: Double?
    var expenseCategory: String // Category name in ExpensesAccount for tracking actual payments
    var loan: LoanDetails?
    var revenue: RevenueDetails?
    
    // MARK: - Convenience Initializers
    
    // For assets without loans or revenue
    init(id: UUID = UUID(), name: String, type: String, category: AssetCategory, acquisitionDate: Date, acquisitionPrice: Double, currentMarketValue: Double? = nil, customDepreciationRate: Double? = nil, expenseCategory: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.acquisitionDate = acquisitionDate
        self.acquisitionPrice = acquisitionPrice
        self.currentMarketValue = currentMarketValue
        self.customDepreciationRate = customDepreciationRate
        self.expenseCategory = expenseCategory
        self.loan = nil
        self.revenue = nil
    }
    
    // For assets with loans
    init(id: UUID = UUID(), name: String, type: String, category: AssetCategory, acquisitionDate: Date, acquisitionPrice: Double, currentMarketValue: Double? = nil, customDepreciationRate: Double? = nil, expenseCategory: String = "", loanAmount: Double, interestRate: Double, loanTermYears: Int, downPayment: Double = 0) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.acquisitionDate = acquisitionDate
        self.acquisitionPrice = acquisitionPrice
        self.currentMarketValue = currentMarketValue
        self.customDepreciationRate = customDepreciationRate
        self.expenseCategory = expenseCategory
        self.loan = LoanDetails(
            originalAmount: loanAmount,
            interestRate: interestRate,
            termYears: loanTermYears,
            startDate: acquisitionDate,
            downPayment: downPayment
        )
        self.revenue = nil
    }
    
    // For revenue generating assets
    init(id: UUID = UUID(), name: String, type: String, category: AssetCategory, acquisitionDate: Date, acquisitionPrice: Double, currentMarketValue: Double? = nil, customDepreciationRate: Double? = nil, expenseCategory: String = "", monthlyRevenueTarget: Double, revenueGenerationRate: Double = 0.8, variabilityFactor: Double = 0.3) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.acquisitionDate = acquisitionDate
        self.acquisitionPrice = acquisitionPrice
        self.currentMarketValue = currentMarketValue
        self.customDepreciationRate = customDepreciationRate
        self.expenseCategory = expenseCategory
        self.loan = nil
        self.revenue = RevenueDetails(
            monthlyTarget: monthlyRevenueTarget,
            generationRate: revenueGenerationRate,
            variabilityFactor: variabilityFactor
        )
    }
    
    // For assets with both loans and revenue generation
    init(id: UUID = UUID(), name: String, type: String, category: AssetCategory, acquisitionDate: Date, acquisitionPrice: Double, currentMarketValue: Double? = nil, customDepreciationRate: Double? = nil, expenseCategory: String = "", loanAmount: Double, interestRate: Double, loanTermYears: Int, downPayment: Double = 0, monthlyRevenueTarget: Double, revenueGenerationRate: Double = 0.8, variabilityFactor: Double = 0.3) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.acquisitionDate = acquisitionDate
        self.acquisitionPrice = acquisitionPrice
        self.currentMarketValue = currentMarketValue
        self.customDepreciationRate = customDepreciationRate
        self.expenseCategory = expenseCategory
        self.loan = LoanDetails(
            originalAmount: loanAmount,
            interestRate: interestRate,
            termYears: loanTermYears,
            startDate: acquisitionDate,
            downPayment: downPayment
        )
        self.revenue = RevenueDetails(
            monthlyTarget: monthlyRevenueTarget,
            generationRate: revenueGenerationRate,
            variabilityFactor: variabilityFactor
        )
    }
    
    // MARK: - Basic Properties
    var currentValue: Double {
        currentMarketValue ?? acquisitionPrice
    }
    
    var hasLoan: Bool {
        loan != nil
    }
    
    var hasActiveLoan: Bool {
        loan?.status == .activeLoan
    }
    
    var loanStatus: LoanStatus {
        loan?.status ?? .noLoan
    }
    
    var isRevenueGenerating: Bool {
        revenue?.isRevenueGenerating ?? false
    }
    
    var monthlyRevenueTarget: Double {
        revenue?.monthlyRevenueTarget ?? 0
    }
    
    // MARK: - Time-based Properties
    var monthsOwned: Int {
        let timeInterval = Date().timeIntervalSince(acquisitionDate)
        return max(1, Int(timeInterval / (30.44 * 24 * 60 * 60)))
    }
    
    var yearsOwned: Double {
        let timeInterval = Date().timeIntervalSince(acquisitionDate)
        return timeInterval / (365.25 * 24 * 60 * 60)
    }
    
    // MARK: - Loan-related Properties (only if loan exists)
    var loanAmount: Double {
        loan?.originalAmount ?? 0
    }
    
    var downPayment: Double {
        loan?.downPayment ?? 0
    }
    
    var interestRate: Double {
        loan?.interestRate ?? 0
    }
    
    var loanTermYears: Int {
        loan?.termYears ?? 0
    }
    
    var monthlyPayment: Double {
        guard let loan = loan, loan.status == .activeLoan, loan.originalAmount > 0, loan.interestRate > 0 else { return 0 }
        
        let monthlyRate = loan.interestRate / 100 / 12
        let numberOfPayments = Double(loan.termYears * 12)
        
        let numerator = loan.originalAmount * monthlyRate * pow(1 + monthlyRate, numberOfPayments)
        let denominator = pow(1 + monthlyRate, numberOfPayments) - 1
        
        return numerator / denominator
    }
    
    var remainingLoanBalance: Double {
        guard let loan = loan, loan.status == .activeLoan else { return 0 }
        
        let totalMonths = loan.termYears * 12
        let monthlyRate = loan.interestRate / 100 / 12
        
        guard monthsOwned < totalMonths, loan.interestRate > 0 else { return 0 }
        
        let remainingPayments = Double(totalMonths - monthsOwned)
        
        let numerator = monthlyPayment * (pow(1 + monthlyRate, remainingPayments) - 1)
        let denominator = monthlyRate * pow(1 + monthlyRate, remainingPayments)
        
        return numerator / denominator
    }
    
    var equity: Double {
        currentValue - remainingLoanBalance
    }
    
    var totalPaidToday: Double {
        guard let loan = loan else { return acquisitionPrice }
        
        let paymentsMade = min(monthsOwned, loan.termYears * 12)
        return loan.downPayment + (monthlyPayment * Double(paymentsMade))
    }
    
    // MARK: - Revenue Generation Methods
    func generateMonthlyRevenue(for date: Date = Date()) -> Double? {
        guard let revenue = revenue, revenue.isRevenueGenerating else { return nil }
        
        // Check if revenue should be generated this month based on generation rate
        let randomValue = Double.random(in: 0...1)
        guard randomValue <= revenue.revenueGenerationRate else { return nil }
        
        // Calculate revenue with variability
        let baseRevenue = revenue.monthlyRevenueTarget
        let variation = baseRevenue * revenue.variabilityFactor * Double.random(in: -1...1)
        let actualRevenue = max(0, baseRevenue + variation)
        
        return actualRevenue
    }
    
    func emitRevenueToExpensesAccount(for date: Date = Date()) {
        if let revenue = generateMonthlyRevenue(for: date) {
            let transaction = Transaction(
                name: "\(name) Revenue",
                category: "Asset Income",
                amount: revenue,
                type: .credit,
                date: date
            )
            ExpensesAccount.shared.addAssetRevenue(transaction)
        }
    }
    
    func getHistoricalRevenue() -> [(month: String, target: Double, actual: Double)] {
        guard isRevenueGenerating else { return [] }
        
        var result: [(month: String, target: Double, actual: Double)] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        // Get revenue for the last 12 months
        for i in 0..<12 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            
            // Skip months before asset acquisition
            guard monthDate >= acquisitionDate else { continue }
            
            let monthString = formatter.string(from: monthDate)
            let target = monthlyRevenueTarget
            
            // Get actual revenue from ExpensesAccount
            let actual = ExpensesAccount.shared.getAssetRevenueForMonth(assetName: name, month: monthDate)
            
            result.append((month: monthString, target: target, actual: actual))
        }
        
        return result.reversed()
    }
    
    // MARK: - Performance Metrics
    var totalAppreciation: Double {
        currentValue - acquisitionPrice
    }
    
    var appreciationRate: Double {
        guard acquisitionPrice > 0 else { return 0 }
        return totalAppreciation / acquisitionPrice
    }
    
    var appreciationRatePercentage: Double {
        appreciationRate * 100
    }
    
    var annualizedAppreciationRate: Double {
        guard yearsOwned > 0, acquisitionPrice > 0 else { return 0 }
        return pow(currentValue / acquisitionPrice, 1 / yearsOwned) - 1
    }
    
    var annualizedAppreciationRatePercentage: Double {
        annualizedAppreciationRate * 100
    }
    
    // MARK: - Revenue Performance Metrics
    var totalRevenueGenerated: Double {
        ExpensesAccount.shared.getTotalAssetRevenue(assetName: name)
    }
    
    var averageMonthlyRevenue: Double {
        guard monthsOwned > 0 else { return 0 }
        return totalRevenueGenerated / Double(monthsOwned)
    }
    
    var revenueTargetAchievementRate: Double {
        guard monthlyRevenueTarget > 0, monthsOwned > 0 else { return 0 }
        let totalExpectedRevenue = monthlyRevenueTarget * Double(monthsOwned)
        return totalRevenueGenerated / totalExpectedRevenue
    }
    
    var revenueTargetAchievementPercentage: Double {
        revenueTargetAchievementRate * 100
    }
    
    var monthlyRevenuePerformance: String {
        let achievementRate = revenueTargetAchievementRate
        switch achievementRate {
        case 1.2...:
            return "Excellent"
        case 1.0..<1.2:
            return "Good"
        case 0.8..<1.0:
            return "Fair"
        default:
            return "Poor"
        }
    }
    
    // MARK: - Equity and Ratios (only meaningful for assets with loans)
    var equityRatio: Double {
        guard currentValue > 0 else { return 1.0 }
        return equity / currentValue
    }
    
    var equityRatioPercentage: Double {
        equityRatio * 100
    }
    
    var loanToValueRatio: Double {
        guard currentValue > 0, hasActiveLoan else { return 0 }
        return remainingLoanBalance / currentValue
    }
    
    var loanToValueRatioPercentage: Double {
        loanToValueRatio * 100
    }
    
    var returnOnInvestment: Double {
        let investment = hasLoan ? downPayment : acquisitionPrice
        guard investment > 0 else { return 0 }
        return equity / investment
    }
    
    var returnOnInvestmentPercentage: Double {
        returnOnInvestment * 100
    }
    
    // MARK: - Risk Assessment
    var isUnderwater: Bool {
        hasActiveLoan && equity < 0
    }
    
    var isAtRisk: Bool {
        if hasActiveLoan {
            return isUnderwater || appreciationRate < -0.3 || loanToValueRatio > 0.9
        } else {
            return appreciationRate < -0.5 // Significant value loss for non-loan assets
        }
    }
    
    var riskLevel: String {
        if isAtRisk {
            return "High"
        } else if (hasActiveLoan && loanToValueRatio > 0.7) || appreciationRate < -0.15 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    var performanceRating: String {
        if equity > 0 && appreciationRate > 0.1 {
            return "Excellent"
        } else if equity > 0 && appreciationRate > 0 {
            return "Good"
        } else if equity > 0 || (!hasLoan && appreciationRate > -0.1) {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    // MARK: - Interest Calculations (only for assets with loans)
    var totalInterestPaid: Double {
        guard let loan = loan else { return 0 }
        
        let paymentsMade = min(monthsOwned, loan.termYears * 12)
        let totalPaid = monthlyPayment * Double(paymentsMade)
        let principalPaid = loan.originalAmount - remainingLoanBalance
        return max(0, totalPaid - principalPaid)
    }
    
    var remainingInterest: Double {
        guard hasActiveLoan, remainingLoanBalance > 0 else { return 0 }
        let remainingPayments = (loanTermYears * 12) - monthsOwned
        let totalRemainingPayments = monthlyPayment * Double(max(0, remainingPayments))
        return max(0, totalRemainingPayments - remainingLoanBalance)
    }
    
    var totalInterestOverLife: Double {
        totalInterestPaid + remainingInterest
    }
    
    // MARK: - Asset Classification
    var iconName: String {
        switch type.lowercased() {
        case "car", "vehicle", "automobile":
            return "car.fill"
        case "house", "home", "property", "real estate":
            return "house.fill"
        case "electronics", "computer", "laptop":
            return "laptopcomputer"
        case "equipment", "machinery":
            return "wrench.and.screwdriver.fill"
        case "business", "company":
            return "building.2.fill"
        case "intellectual property", "patent", "trademark":
            return "lightbulb.fill"
        case "investment", "portfolio":
            return "chart.line.uptrend.xyaxis"
        default:
            return category == .tangible ? "cube.box.fill" : "star.fill"
        }
    }
    
    // MARK: - Asset Management Methods
    mutating func markLoanAsPaidOff(on date: Date = Date()) {
        loan?.markAsPaidOff(on: date)
    }
    
    mutating func updateMarketValue(_ newValue: Double) {
        self.currentMarketValue = newValue
    }
    
    mutating func updateRevenueTarget(_ newTarget: Double) {
        revenue?.monthlyRevenueTarget = newTarget
        revenue?.isRevenueGenerating = newTarget > 0
    }
    
    mutating func updateRevenueGenerationRate(_ newRate: Double) {
        revenue?.revenueGenerationRate = max(0.0, min(1.0, newRate))
    }
    
    // MARK: - Payoff Analysis Methods (only for active loans)
    func payoffAnalysis(extraPayment: Double = 0) -> (monthsSaved: Int, interestSaved: Double) {
        guard hasActiveLoan, remainingLoanBalance > 0 else { return (0, 0) }
        
        let monthlyRate = interestRate / 100 / 12
        let currentPayment = monthlyPayment
        let newPayment = currentPayment + extraPayment
        
        // Calculate time to payoff with current payment
        let currentMonths = calculatePayoffTime(balance: remainingLoanBalance, payment: currentPayment, rate: monthlyRate)
        
        // Calculate time to payoff with extra payment
        let newMonths = calculatePayoffTime(balance: remainingLoanBalance, payment: newPayment, rate: monthlyRate)
        
        let monthsSaved = currentMonths - newMonths
        let currentTotalInterest = (currentPayment * Double(currentMonths)) - remainingLoanBalance
        let newTotalInterest = (newPayment * Double(newMonths)) - remainingLoanBalance
        let interestSaved = currentTotalInterest - newTotalInterest
        
        return (monthsSaved: monthsSaved, interestSaved: interestSaved)
    }
    
    private func calculatePayoffTime(balance: Double, payment: Double, rate: Double) -> Int {
        guard payment > balance * rate else { return Int.max } // Payment less than interest
        
        let months = -log(1 - (balance * rate / payment)) / log(1 + rate)
        return Int(months.rounded(.up))
    }
    
    // MARK: - Depreciation Methods
    func projectedValue(afterYears years: Double) -> Double {
        let depreciationRate = customDepreciationRate ?? getStandardDepreciationRate()
        return currentValue * pow(1 + depreciationRate, years) // Using + because depreciation rates can be negative (appreciation)
    }
    
    private func getStandardDepreciationRate() -> Double {
        switch type.lowercased() {
        case "car", "vehicle", "automobile":
            return -0.15 // 15% annual depreciation for cars
        case "electronics", "computer", "laptop":
            return -0.20 // 20% annual depreciation for electronics
        case "equipment", "machinery":
            return -0.10 // 10% annual depreciation for equipment
        case "house", "home", "property", "real estate":
            return 0.03 // Houses typically appreciate at 3% annually
        case "business", "company":
            return 0.05 // Businesses can appreciate 5% annually
        case "intellectual property", "patent", "trademark":
            return -0.05 // IP might depreciate slowly over time
        default:
            return category == .tangible ? -0.05 : 0.0 // Default: tangible depreciates, intangible neutral
        }
    }
}