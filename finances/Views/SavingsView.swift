import SwiftUI
import Charts

enum ChartTimeFilter: String, CaseIterable {
    /// Current month to date
    case oneMonth = "1M"
    // Last 3 months starting from the current month
    case threeMonths = "3M"
    // Last 6 months starting from the current month
    case sixMonths = "6M"
    // Last 12 months starting from the current month
    case oneYear  = "12M"

    /// Filters that should be presented to the user (order matters for UI)
    static var allCases: [ChartTimeFilter] {
        [.oneMonth, .threeMonths, .sixMonths, .oneYear]
    }

    /// Date interval for each filter
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .oneMonth:
            // From the 1st of the current month up to today
            let comps = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: comps) ?? now
            return (start: start, end: now)

        case .threeMonths:
            // From the 1st of the month two months ago up to today (3 months inclusive)
            guard let dateThreeMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else {
                return (start: now, end: now)
            }
            let comps = calendar.dateComponents([.year, .month], from: dateThreeMonthsAgo)
            let start = calendar.date(from: comps) ?? now
            return (start: start, end: now)

        case .sixMonths:
            // From the 1st of the month five months ago up to today (6 months inclusive)
            guard let dateSixMonthsAgo = calendar.date(byAdding: .month, value: -5, to: now) else {
                return (start: now, end: now)
            }
            let comps = calendar.dateComponents([.year, .month], from: dateSixMonthsAgo)
            let start = calendar.date(from: comps) ?? now
            return (start: start, end: now)

        case .oneYear:
            // From the 1st of the month eleven months ago up to today (12 months inclusive)
            guard let dateOneYearAgo = calendar.date(byAdding: .month, value: -11, to: now) else {
                return (start: now, end: now)
            }
            let comps = calendar.dateComponents([.year, .month], from: dateOneYearAgo)
            let start = calendar.date(from: comps) ?? now
            return (start: start, end: now)
        }
    }
}

extension NumberFormatter {
    static let savingsCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

struct SavingsView: View {
    @ObservedObject private var savingsAccount = SavingsAccount.shared
    @ObservedObject private var expensesAccount = ExpensesAccount.shared
    @State private var selectedChartFilter: ChartTimeFilter = .oneMonth
    
    // Computed transfer-validation status
    private var transferValidation: (isValid: Bool, message: String) {
        savingsAccount.validateTransfersWithExpenses(expensesAccount)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    self.summaryHeader

                    self.growthChartSection
                    
                    self.emergencyFundProgressSection
                    
                    if savingsAccount.isEmergencyFundComplete && !savingsAccount.savingsCategories.isEmpty {
                        self.savingsCategoriesSection
                    }
                    
                }
            }
            .navigationTitle("Savings")
        }
    }
}

private extension SavingsView {
    var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Savings Account")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(dateRangeDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Transfer Validation Status
                HStack(spacing: 4) {
                    Image(systemName: transferValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(transferValidation.isValid ? .green : .orange)
                        .font(.caption)
                    Text(transferValidation.isValid ? "Validated" : "Check Transfers")
                        .font(.caption)
                        .foregroundColor(transferValidation.isValid ? .green : .orange)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("₡\(Int(savingsAccount.savingsBalance).formatted())")
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    var emergencyFundProgressSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Emergency Fund Progress")
                    .font(.title2.bold())
                Spacer()
                Text("₡\(Int(savingsAccount.emergencyFundTarget).formatted())")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Progress Bar
                ProgressView(value: savingsAccount.emergencyFundProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(x: 1, y: 2.5, anchor: .center)
                
                // Progress Details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₡\(Int(savingsAccount.savingsBalance).formatted())")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(savingsAccount.emergencyFundProgressPercentage))%")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₡\(Int(savingsAccount.emergencyFundRemaining).formatted())")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    var savingsCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Savings Categories")
                    .font(.title2.bold())
                Spacer()
                Text("₡\(Int(savingsAccount.excessSavings).formatted())")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                ForEach(savingsAccount.savingsCategories, id: \.name) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("\(Int(category.percentage * 100))% allocation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("₡\(Int(category.amount).formatted())")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    var growthChartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Savings Growth")
                .font(.title2.bold())
            
            let chartData = getFilteredChartData()
            
            if !chartData.isEmpty {
                Chart(chartData, id: \.month) { item in
                    AreaMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", max(item.balance, 0))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.6), .green.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", max(item.balance, 0))
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", max(item.balance, 0))
                    )
                    .foregroundStyle(.green)
                    .symbolSize(60)
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let balance = value.as(Double.self) {
                                Text("₡\(Int(max(balance, 0)/1000))K")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
            } else {
                ContentUnavailableView(
                    "No Savings Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Start saving to see your growth here")
                )
                .frame(height: 250)
            }
            
            // Time filter buttons at the bottom
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(ChartTimeFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedChartFilter = filter
                        }) {
                            Text(filter.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(selectedChartFilter == filter ? .white : .gray)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedChartFilter == filter ? .gray : .gray.opacity(0.2))
                                )
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    func getFilteredChartData() -> [(month: String, balance: Double)] {
        let dateRange = selectedChartFilter.dateRange
        let calendar = Calendar.current
        var result: [(month: String, balance: Double)] = []
        var runningBalance: Double = 0
        
        // Get all transactions up to the filter start date to calculate starting balance
        let transactionsBeforeRange = savingsAccount.transactions
            .filter { $0.date < dateRange.start }
            .sorted { $0.date < $1.date }
        
        let startingBalance = transactionsBeforeRange.reduce(0) { total, transaction in
            total + (transaction.type == .credit ? transaction.amount : -transaction.amount)
        }
        runningBalance = startingBalance
        
        // Get transactions within the selected date range
        let filteredTransactions = savingsAccount.transactions
            .filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
            .sorted { $0.date < $1.date }
        
        guard !filteredTransactions.isEmpty else {
            // If no transactions in range, show the starting balance
            let formatter = DateFormatter()
            formatter.dateFormat = selectedChartFilter == .oneMonth ? "MMM d" : "MMM yyyy"
            result.append((month: formatter.string(from: dateRange.start), balance: max(runningBalance, 0)))
            return result
        }
        
        // Determine the appropriate time intervals based on the filter
        let intervals = getChartTimeIntervals(from: dateRange.start, to: dateRange.end)
        
        for interval in intervals {
            // Get transactions for this specific interval
            let intervalTransactions = filteredTransactions.filter { transaction in
                transaction.date >= interval.start && transaction.date < interval.end
            }
            
            // Calculate net change for this interval
            let intervalChange = intervalTransactions.reduce(0) { total, transaction in
                total + (transaction.type == .credit ? transaction.amount : -transaction.amount)
            }
            
            // Add to running balance
            runningBalance += intervalChange
            
            result.append((month: interval.label, balance: max(runningBalance, 0)))
        }
        
        return result
    }
    
    func getChartTimeIntervals(from start: Date, to end: Date) -> [(start: Date, end: Date, label: String)] {
        let calendar = Calendar.current
        var intervals: [(start: Date, end: Date, label: String)] = []
        
        let formatter = DateFormatter()
        
        switch selectedChartFilter {
        case .oneMonth:
            formatter.dateFormat = "MMM d"
            var currentDate = start
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .day, value: 3, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
        default:
            formatter.dateFormat = "MMM yyyy"
            var currentDate = calendar.dateInterval(of: .month, for: start)?.start ?? start
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
        }
        
        return intervals
    }
    
    func dateRangeDisplay() -> String {
        let range = selectedChartFilter.dateRange
        let formatter = DateFormatter()
        switch selectedChartFilter {
        case .oneMonth:
            formatter.dateFormat = "d MMM yyyy"
        default:
            formatter.dateFormat = "MMM yyyy"
        }
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }
}
