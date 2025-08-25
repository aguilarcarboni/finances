import SwiftUI
import Charts

struct ExpensesAccountView: View {
    @ObservedObject private var account = ExpensesAccount.shared
    @ObservedObject private var savingsAccount = SavingsAccount.shared
    @ObservedObject private var assetsManager = AssetsManager.shared
    @State private var selectedMonth: Date = Date()

    private var dateRange: (start: Date, end: Date) {
        var baseRange = (start: Date(), end: Date())
        let calendar = Calendar.current
        // Start at the first day of the selected date's month
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        if let monthStart = calendar.date(from: comps) {
            // End at the exact selected date (cut-off)
            let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedMonth) ?? selectedMonth
            baseRange = (start: monthStart, end: dayEnd)
        }
        return baseRange
    }

    // Savings → Expenses transfer validation helper
    private var savingsTransferValidation: (isValid: Bool, message: String) {
        account.validateTransfersFromSavings(savingsAccount)
    }

    // NEW: Helper for income budget section
    private var assetCashFlowValidation: (isValid: Bool, message: String) {
        account.validateCashFlowFromAssets(assetsManager.assets)
    }

    // NEW: Helper for Wise transfers validation
    private var wiseIncomingValidation: (isValid: Bool, message: String) {
        account.validateTransfersFromWise(WiseAccount.shared)
    }

    // MARK: - Filtered Transaction Data (based on selected time filter)
    private var currentMonthTransactions: [Transaction] {
        let range = dateRange
        return account.transactionsForDateRange(from: range.start, to: range.end)
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
    
    // NEW: Helper for income budget section
    private func currentMonthCreditsForCategory(_ categoryName: String) -> Double {
        currentMonthCredits.filter { $0.category == categoryName }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account Balance")) {
                    HStack {                   
                        VStack(alignment: .leading, spacing: 4) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("₡\(Int(account.netBalance).formatted())")
                                    .font(.title2.monospacedDigit())
                                    .fontWeight(.bold)
                                    .foregroundColor(account.netBalance >= 0 ? .green : .red)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            // Savings → Expenses validation
                            HStack(spacing: 4) {
                                Image(systemName: savingsTransferValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(savingsTransferValidation.isValid ? .green : .orange)
                                    .font(.caption)
                                Text(savingsTransferValidation.isValid ? "Savings Credits Validated" : "Check Savings Credits")
                                    .font(.caption)
                                    .foregroundColor(savingsTransferValidation.isValid ? .green : .orange)
                            }
                            // Asset cash-flow validation
                            HStack(spacing: 4) {
                                Image(systemName: assetCashFlowValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(assetCashFlowValidation.isValid ? .green : .orange)
                                    .font(.caption)
                                Text(assetCashFlowValidation.isValid ? "Asset Credits Validated" : "Check Asset Credits")
                                    .font(.caption)
                                    .foregroundColor(assetCashFlowValidation.isValid ? .green : .orange)
                            }
                            // Wise → Expenses validation
                            HStack(spacing: 4) {
                                Image(systemName: wiseIncomingValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(wiseIncomingValidation.isValid ? .green : .orange)
                                    .font(.caption)
                                Text(wiseIncomingValidation.isValid ? "Wise Credits Validated" : "Check Wise Credits")
                                    .font(.caption)
                                    .foregroundColor(wiseIncomingValidation.isValid ? .green : .orange)
                            }
                        }
                    }
                }
                Section(header: Text("Balance Over Time")) {
                    self.balanceChartSection
                }
                Section(header: Text("Budget vs Actual")) {
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
                                .progressViewStyle(LinearProgressViewStyle(tint: overallProgress > 1.0 ? .red : .green))
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
                }
                Section(header: Text("Income vs Expected")) {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(account.incomeBudget) { category in
                            let actualIncome = currentMonthCreditsForCategory(category.name)
                            IncomeBudgetRow(
                                category: category.name,
                                currentAmount: actualIncome,
                                maxAmount: category.budget,
                                progress: category.budget > 0 ? actualIncome / category.budget : 0
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        let totalIncomeBudget = account.totalIncomeBudget
                        let totalIncome = currentMonthTotalCredits
                        let overallIncomeProgress = totalIncomeBudget > 0 ? totalIncome / totalIncomeBudget : 0
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total Expected Income")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("₡\(Int(totalIncome).formatted()) / ₡\(Int(totalIncomeBudget).formatted())")
                                    .font(.headline.monospacedDigit())
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: overallIncomeProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: overallIncomeProgress > 1.0 ? .green : .red))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            HStack {
                                Text("Income vs Expectation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(overallIncomeProgress * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(overallIncomeProgress > 1.0 ? .green : .red)
                            }
                        }
                    }
                }
                Section(header: Text("Expenses")) {
                    VStack(alignment: .leading, spacing: 15) {
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
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRow(transaction: transaction, isDebit: true)
                                }
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
                }
                Section(header: Text("Income")) {
                    VStack(alignment: .leading, spacing: 15) {
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
                                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                    TransactionRow(transaction: transaction, isDebit: false)
                                }
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
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DatePicker(
                        "Select Month",
                        selection: $selectedMonth,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
            }
        }
    }
    
    var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            
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
                    .interpolationMethod(.catmullRom)
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
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisValueLabel()
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
        }
    }
    
    func getFilteredChartData() -> [(month: String, balance: Double)] {
        let dateRange = dateRange
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
            formatter.dateFormat = "MMM d"
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

        formatter.dateFormat = "MMM d"
        var currentDate = start
        while currentDate < end {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? end
            intervals.append((
                start: currentDate,
                end: min(nextDate, end),
                label: formatter.string(from: currentDate)
            ))
            currentDate = nextDate
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
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : .green))
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
                    .foregroundColor(.primary)
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(isDebit ? .red : .green)
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct IncomeBudgetRow: View {
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
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .green : .red))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}
