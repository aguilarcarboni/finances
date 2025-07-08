import SwiftUI
import Charts
import Combine

enum ChartTimeFilter: String, CaseIterable {
    case twoWeeks = "2W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = now
        
        let startDate: Date
        switch self {
        case .twoWeeks:
            startDate = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return (start: startDate, end: endDate)
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
    @StateObject private var viewModel = SavingsViewModel()
    @ObservedObject private var savingsAccount = SavingsAccount.shared
    @State private var selectedChartFilter: ChartTimeFilter = .threeMonths
    
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
                    Image(systemName: viewModel.transferValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.transferValidation.isValid ? .green : .orange)
                        .font(.caption)
                    Text(viewModel.transferValidation.isValid ? "Validated" : "Check Transfers")
                        .font(.caption)
                        .foregroundColor(viewModel.transferValidation.isValid ? .green : .orange)
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
            formatter.dateFormat = selectedChartFilter == .twoWeeks ? "MMM d" : "MMM yyyy"
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
        case .twoWeeks:
            formatter.dateFormat = "MMM d"
            var currentDate = start
            while currentDate < end {
                let nextDate = calendar.date(byAdding: .day, value: 2, to: currentDate) ?? end
                intervals.append((
                    start: currentDate,
                    end: min(nextDate, end),
                    label: formatter.string(from: currentDate)
                ))
                currentDate = nextDate
            }
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
        case .twoWeeks, .oneMonth:
            formatter.dateFormat = "d MMM yyyy"
        default:
            formatter.dateFormat = "MMM yyyy"
        }
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }
}
