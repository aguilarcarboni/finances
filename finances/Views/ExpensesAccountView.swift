import SwiftUI
import Charts
import Combine

struct ExpensesAccountView: View {
    @StateObject private var viewModel = ExpensesAccountViewModel()
    @ObservedObject private var account = ExpensesAccount.shared
    @State private var selectedChartFilter: ChartTimeFilter = .threeMonths

    // MARK: - Current Month Data
    private var currentMonthTransactions: [Transaction] {
        account.transactionsForMonth(Date())
    }
    
    private var currentMonthDebits: [Transaction] {
        currentMonthTransactions.filter { $0.type == .debit }
    }
    
    private var currentMonthCredits: [Transaction] {
        currentMonthTransactions.filter { $0.type == .credit }
    }
    
    private var currentMonthTotalDebits: Double {
        currentMonthDebits.reduce(0) { $0 + $1.amount }
    }
    
    private var currentMonthTotalCredits: Double {
        currentMonthCredits.reduce(0) { $0 + $1.amount }
    }
    
    private func currentMonthDebitsForCategory(_ categoryName: String) -> Double {
        currentMonthDebits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // Current Month Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Expenses Account")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(getDateRangeDisplay())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        // Account Balance Summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("₡\(Int(account.netBalance).formatted())")
                                    .font(.title2.monospacedDigit())
                                    .fontWeight(.bold)
                                    .foregroundColor(account.netBalance >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    self.balanceChartSection

                    // Budget vs Actual Section
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ForEach(account.budget) { category in
                            let actualSpent = currentMonthDebitsForCategory(category.name)
                            BudgetRow(
                                category: category.name,
                                currentAmount: actualSpent,
                                maxAmount: category.budget,
                                progress: actualSpent / category.budget
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        let totalBudget = account.totalBudget
                        let totalSpent = currentMonthTotalDebits
                        let overallProgress = totalSpent / totalBudget
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total Budget")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("₡\(Int(totalSpent).formatted()) / ₡\(Int(totalBudget).formatted())")
                                    .font(.headline.monospacedDigit())
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: overallProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: overallProgress > 1.0 ? .red : .blue))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            HStack {
                                Text("Budget Usage")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(overallProgress * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(overallProgress > 1.0 ? .red : .secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // All Debits (Expenses) Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Expenses")
                            .font(.title2.bold())
                        
                        if currentMonthDebits.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text("No expenses in this period")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                        } else {
                            ForEach(currentMonthDebits.sorted { $0.date > $1.date }) { transaction in
                                TransactionRow(transaction: transaction, isDebit: true)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        HStack {
                            Text("Total Debits")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₡\(Int(currentMonthTotalDebits).formatted())")
                                .font(.headline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // All Credits (Income) Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Income")
                            .font(.title2.bold())
                        
                        if currentMonthCredits.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text("No income in this period")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                        } else {
                            ForEach(currentMonthCredits.sorted { $0.date > $1.date }) { transaction in
                                TransactionRow(transaction: transaction, isDebit: false)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        HStack {
                            Text("Total Credits")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₡\(Int(currentMonthTotalCredits).formatted())")
                                .font(.headline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Expenses")
        }
    }
    
    private func getDateRangeDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account Balance Over Time")
                .font(.title2.bold())
            
            let chartData = getFilteredChartData()
            
            if !chartData.isEmpty {
                Chart(chartData, id: \.month) { item in
                    AreaMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", item.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                item.balance >= 0 ? .green.opacity(0.6) : .red.opacity(0.6),
                                item.balance >= 0 ? .green.opacity(0.1) : .red.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", item.balance)
                    )
                    .foregroundStyle(item.balance >= 0 ? .green : .red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Month", item.month),
                        y: .value("Balance", item.balance)
                    )
                    .foregroundStyle(item.balance >= 0 ? .green : .red)
                    .symbolSize(60)
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let balance = value.as(Double.self) {
                                let absValue = abs(balance)
                                let prefix = balance < 0 ? "-₡" : "₡"
                                Text("\(prefix)\(Int(absValue/1000))K")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
            } else {
                ContentUnavailableView(
                    "No Transaction Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Add transactions to see your balance over time")
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
        let transactionsBeforeRange = account.transactions
            .filter { $0.date < dateRange.start }
            .sorted { $0.date < $1.date }
        
        let startingBalance = transactionsBeforeRange.reduce(0) { total, transaction in
            total + (transaction.type == .credit ? transaction.amount : -transaction.amount)
        }
        runningBalance = startingBalance
        
        // Get transactions within the selected date range
        let filteredTransactions = account.transactions
            .filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
            .sorted { $0.date < $1.date }
        
        guard !filteredTransactions.isEmpty else {
            // If no transactions in range, show the starting balance
            let formatter = DateFormatter()
            formatter.dateFormat = selectedChartFilter == .twoWeeks ? "MMM d" : "MMM yyyy"
            result.append((month: formatter.string(from: dateRange.start), balance: runningBalance))
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
            
            result.append((month: interval.label, balance: runningBalance))
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
}

struct BudgetRow: View {
    let category: String
    let currentAmount: Double
    let maxAmount: Double
    let progress: Double
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.headline)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: currentAmount)) ?? "") / \(currencyFormatter.string(from: NSNumber(value: maxAmount)) ?? "")")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let isDebit: Bool
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    // Color mapping for categories
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Debt": return .red
        case "Subscriptions": return .orange
        case "Transportation": return .blue
        case "Savings": return .green
        case "Income": return .green
        case "Investment": return .purple
        case "Rewards": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForCategory(transaction.category))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.category)
                    .font(.caption)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(isDebit ? .red : .green)
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption)
            }
        }
    }
}
