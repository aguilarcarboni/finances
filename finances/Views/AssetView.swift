//
//  AssetView.swift
//  finances
//
//  Created by Andrés on 10/6/2025.
//

import Foundation
import SwiftUI
import Charts

enum DepreciationMethod {
    case straightLine(years: Int)
    case custom(rate: Double)
}

struct DepreciationDataPoint: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
}

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let target: Double
    let actual: Double
}

struct PaymentDataPoint: Identifiable {
    let id = UUID()
    let month: Int
    let principal: Double
    let interest: Double
    let type: String
}

struct PaymentComparisonDataPoint: Identifiable {
    let id = UUID()
    let periodName: String
    let amount: Double
    let type: String
}

struct AssetDetailView: View {
    let asset: Asset
    @ObservedObject private var expensesAccount = ExpensesAccount.shared
    
    @State private var forecastMonths: Double = 12
    @State private var selectedChartFilter: ChartTimeFilter = .oneMonth
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Base Cards - Always Present
                assetHeaderCard
                assetDetailsCard
                // Show loan details in a separate card when applicable
                if asset.hasLoan {
                    loanDetailsCard
                }
                performanceSummaryCard
                valueOverTimeChartCard
                // Payment comparison for loan assets
                if asset.hasActiveLoan {
                    paymentComparisonCard
                }
            }
            .padding()
        }
        .navigationTitle("Asset Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Base Cards
    
    private var assetHeaderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(asset.type)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        // Category, Loan Status, and Revenue Badges
                        HStack(spacing: 4) {
                            Text(asset.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(asset.category == .tangible ? .blue.opacity(0.2) : .purple.opacity(0.2))
                                .foregroundStyle(asset.category == .tangible ? .blue : .purple)
                                .clipShape(Capsule())
                            
                            Text(asset.loanStatus.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(loanStatusColor.opacity(0.2))
                                .foregroundStyle(loanStatusColor)
                                .clipShape(Capsule())
                            
                            if asset.isRevenueGenerating {
                                Text("Revenue Generating")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Asset Type Icon
                Image(systemName: asset.iconName)
                    .font(.title)
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private var assetDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(title: "Acquisition Date", value: formattedDate(asset.acquisitionDate))
                DetailRow(title: "Acquisition Price", value: "₡\(formattedNumber(asset.acquisitionPrice))")
                DetailRow(title: "Current Value", value: "₡\(formattedNumber(asset.currentValue))")
                DetailRow(title: "Years Owned", value: String(format: "%.1f", asset.yearsOwned))
                
                // Revenue details for revenue-generating assets
                if asset.isRevenueGenerating {
                    DetailRow(title: "Monthly Revenue Target", value: "₡\(formattedNumber(asset.monthlyRevenueTarget))")
                    DetailRow(title: "Total Revenue Generated", value: "₡\(formattedNumber(asset.totalRevenueGenerated))")
                    DetailRow(title: "Average Monthly Revenue", value: "₡\(formattedNumber(asset.averageMonthlyRevenue))")
                    DetailRow(title: "Target Achievement", value: String(format: "%.1f", asset.revenueTargetAchievementPercentage) + "%")
                }
                
                // Loan details have been moved to the dedicated card below
                
                // Special properties for intangible assets
                if asset.category == .intangible && asset.customDepreciationRate != nil {
                    DetailRow(title: "Expected Annual Growth", value: String(format: "%.1f", asset.customDepreciationRate! * 100) + "%")
                }

                // Financial metrics for assets without loans, displayed as detail rows
                if !asset.hasLoan {
                    Divider()
                    ForEach(financialMetrics, id: \.title) { metric in
                        let valueText = metric.title == "Risk Level" ? metric.subtitle : metric.formattedValue
                        DetailRow(title: metric.title, value: valueText)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Loan Details Card

    private var loanDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(asset.loanStatus == .paidOff ? "Loan Summary" : "Loan Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DetailRow(title: "Down Payment", value: "₡\(formattedNumber(asset.downPayment))")
                DetailRow(title: "Interest Rate", value: "\(formattedNumber(asset.interestRate, decimals: 1))%")
                DetailRow(title: "Loan Term", value: "\(asset.loanTermYears) years")

                if asset.hasActiveLoan {
                    DetailRow(title: "Monthly Payment", value: "₡\(formattedNumber(asset.monthlyPayment))")
                    DetailRow(title: "Remaining Balance", value: "₡\(formattedNumber(asset.remainingLoanBalance))")
                    DetailRow(title: "Loan Progress", value: String(format: "%.1f", loanProgressPercentage) + "%")
                } else if asset.loanStatus == .paidOff {
                    if let paidOffDate = asset.loan?.paidOffDate {
                        DetailRow(title: "Paid Off Date", value: formattedDate(paidOffDate))
                    }
                    DetailRow(title: "Loan Status", value: "Paid Off ✓")
                }
            }

            // Financial metrics for loaned assets, displayed as detail rows
            Divider()
            ForEach(financialMetrics, id: \.title) { metric in
                let valueText = metric.title == "Risk Level" ? metric.subtitle : metric.formattedValue
                DetailRow(title: metric.title, value: valueText)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var performanceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(asset.appreciationRate >= 0 ? "+" : "")₡\(formattedNumber(asset.totalAppreciation))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(asset.appreciationRate >= 0 ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Return %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", asset.appreciationRatePercentage) + "%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(asset.appreciationRate >= 0 ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annualized Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", asset.annualizedAppreciationRatePercentage) + "%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(asset.annualizedAppreciationRate >= 0 ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Rating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(asset.performanceRating)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(performanceColor)
                }
            }
            
            // Add revenue summary if revenue-generating
            if asset.isRevenueGenerating {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Revenue Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Generated")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("₡\(formattedNumber(asset.totalRevenueGenerated))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg Monthly")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("₡\(formattedNumber(asset.averageMonthlyRevenue))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Modular Content Helpers
    
    private var financialOverviewTitle: String {
        if asset.isRevenueGenerating {
            return "Financial & Revenue Overview"
        } else if asset.hasActiveLoan {
            return "Loan Overview"
        } else if asset.loanStatus == .paidOff {
            return "Equity Summary"
        } else {
            return "Investment Overview"
        }
    }
    
    private var financialOverviewIcon: String {
        if asset.isRevenueGenerating {
            return "dollarsign.circle"
        } else if asset.hasActiveLoan {
            return "creditcard"
        } else if asset.loanStatus == .paidOff {
            return "checkmark.circle"
        } else {
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    private var financialOverviewIconColor: Color {
        if asset.isRevenueGenerating {
            return .green
        } else if asset.hasActiveLoan {
            return .orange
        } else if asset.loanStatus == .paidOff {
            return .green
        } else {
            return .blue
        }
    }
    
    private struct FinancialMetric {
        let title: String
        let value: Double
        let subtitle: String
        let color: Color
        let icon: String
        
        var formattedValue: String {
            if title.contains("%") || title.contains("Rate") || title.contains("Progress") {
                return String(format: "%.1f%%", value)
            } else {
                return "₡\(formattedNumber(abs(value)))"
            }
        }
        
        private func formattedNumber(_ number: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: number)) ?? "\(Int(number))"
        }
    }
    
    private var financialMetrics: [FinancialMetric] {
        if asset.hasActiveLoan {
            return [
                FinancialMetric(
                    title: "Current Equity",
                    value: asset.equity,
                    subtitle: asset.equity >= 0 ? "Positive" : "Underwater",
                    color: asset.equity >= 0 ? .green : .red,
                    icon: asset.equity >= 0 ? "arrow.up.circle" : "arrow.down.circle"
                ),
                FinancialMetric(
                    title: "Remaining Balance",
                    value: asset.remainingLoanBalance,
                    subtitle: remainingLoanTimeText,
                    color: .orange,
                    icon: "creditcard"
                ),
                FinancialMetric(
                    title: "Total Interest",
                    value: asset.totalInterestOverLife,
                    subtitle: "Over loan life",
                    color: .red,
                    icon: "percent"
                ),
                FinancialMetric(
                    title: "LTV Ratio",
                    value: asset.loanToValueRatioPercentage,
                    subtitle: "Loan-to-Value",
                    color: asset.loanToValueRatioPercentage > 80 ? .orange : .green,
                    icon: "chart.pie"
                )
            ]
        } else if asset.loanStatus == .paidOff {
            return [
                FinancialMetric(
                    title: "Full Equity",
                    value: asset.currentValue,
                    subtitle: "100% Owned",
                    color: .green,
                    icon: "checkmark.circle.fill"
                ),
                FinancialMetric(
                    title: "Total Appreciation",
                    value: asset.totalAppreciation,
                    subtitle: "Since acquisition",
                    color: asset.appreciationRate >= 0 ? .green : .red,
                    icon: asset.appreciationRate >= 0 ? "arrow.up" : "arrow.down"
                ),
                FinancialMetric(
                    title: "Appreciation Rate",
                    value: asset.appreciationRatePercentage,
                    subtitle: "Total return",
                    color: asset.appreciationRate >= 0 ? .green : .red,
                    icon: "percent"
                ),
                FinancialMetric(
                    title: "Risk Level",
                    value: 0, // Not a numeric value
                    subtitle: asset.riskLevel,
                    color: riskColor,
                    icon: "shield"
                )
            ]
        } else {
            return [
                FinancialMetric(
                    title: "Investment Value",
                    value: asset.currentValue,
                    subtitle: "Current market value",
                    color: .blue,
                    icon: "dollarsign.circle"
                ),
                FinancialMetric(
                    title: "Total Return",
                    value: asset.totalAppreciation,
                    subtitle: asset.appreciationRate >= 0 ? "Gain" : "Loss",
                    color: asset.appreciationRate >= 0 ? .green : .red,
                    icon: asset.appreciationRate >= 0 ? "plus.circle" : "minus.circle"
                ),
                FinancialMetric(
                    title: "Return Rate",
                    value: asset.appreciationRatePercentage,
                    subtitle: "Total return",
                    color: asset.appreciationRate >= 0 ? .green : .red,
                    icon: "percent"
                ),
                FinancialMetric(
                    title: "Risk Level",
                    value: 0, // Not a numeric value
                    subtitle: asset.riskLevel,
                    color: riskColor,
                    icon: "shield"
                )
            ]
        }
    }
    
    @ViewBuilder
    private var paidOffLoanAdditionalContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                
                Text("Loan Successfully Paid Off!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
            
            if let paidOffDate = asset.loan?.paidOffDate {
                Text("Completed on \(formattedDate(paidOffDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Properties and Methods
    
    private var loanStatusColor: Color {
        switch asset.loanStatus {
        case .noLoan: return .gray
        case .activeLoan: return .orange
        case .paidOff: return .green
        }
    }
    
    private var performanceColor: Color {
        switch asset.performanceRating {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }
    
    private var riskColor: Color {
        switch asset.riskLevel {
        case "Low": return .green
        case "Medium": return .orange
        default: return .red
        }
    }
    
    private var revenuePerformanceColor: Color {
        switch asset.monthlyRevenuePerformance {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }
    
    private var loanProgressPercentage: Double {
        guard asset.hasActiveLoan else { return 100 }
        let totalMonths = Double(asset.loanTermYears * 12)
        let monthsPaid = Double(asset.monthsOwned)
        return min(100, (monthsPaid / totalMonths) * 100)
    }
    
    private var remainingLoanTimeText: String {
        guard asset.hasActiveLoan else { return "N/A" }
        let totalMonths = asset.loanTermYears * 12
        let remainingMonths = max(0, totalMonths - asset.monthsOwned)
        
        let years = remainingMonths / 12
        let months = remainingMonths % 12
        
        if years > 0 && months > 0 {
            return "\(years)y \(months)m"
        } else if years > 0 {
            return "\(years) years"
        } else {
            return "\(months) months"
        }
    }
    
    private var valueProjectionData: [DepreciationDataPoint] {
        // Calculate current effective annual appreciation/depreciation rate based on actual data
        let totalAppreciationPercentage = (asset.totalAppreciation / asset.acquisitionPrice) * 100
        let currentAppreciationRate = totalAppreciationPercentage / (asset.yearsOwned * 100)
        let effectiveAnnualRate = max(-0.25, min(0.25, currentAppreciationRate)) // Cap between -25% and +25%
        
        // Create projection from year 0 using the effective rate we now know
        return (0...10).map { year in
            let value = asset.acquisitionPrice * pow(1 + effectiveAnnualRate, Double(year))
            return DepreciationDataPoint(year: year, value: max(0, value))
        }
    }
    
    private func getRevenueChartData() -> [RevenueDataPoint] {
        guard asset.isRevenueGenerating else { return [] }
        
        let historicalData = asset.getHistoricalRevenue()
        return historicalData.map { data in
            RevenueDataPoint(
                month: data.month,
                target: data.target,
                actual: data.actual
            )
        }
    }
    
    private func getPaymentComparisonData() -> [PaymentComparisonDataPoint] {
        guard asset.hasLoan, asset.monthlyPayment > 0 else { return [] }
        var result: [PaymentComparisonDataPoint] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthsToShow = 12
        for i in stride(from: monthsToShow - 1, through: 0, by: -1) {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            if monthDate < asset.acquisitionDate { continue }
            let monthString = formatter.string(from: monthDate)
            let expected = asset.monthlyPayment
            let actual = expensesAccount.transactions
                .filter { transaction in
                    transaction.type == .debit &&
                    transaction.category == asset.expenseCategory &&
                    calendar.isDate(transaction.date, equalTo: monthDate, toGranularity: .month)
                }
                .reduce(0) { $0 + $1.amount }
            result.append(PaymentComparisonDataPoint(periodName: monthString, amount: expected, type: "Expected"))
            result.append(PaymentComparisonDataPoint(periodName: monthString, amount: actual, type: "Actual"))
        }
        return result
    }

        private var valueOverTimeChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value Over Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Historical and projected value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Current")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                // Projected value line
                ForEach(valueProjectionData) { dataPoint in
                    LineMark(
                        x: .value("Year", dataPoint.year),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(.blue.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    
                    AreaMark(
                        x: .value("Year", dataPoint.year),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                
                // Current position marker
                PointMark(
                    x: .value("Year", asset.yearsOwned),
                    y: .value("Value", asset.currentValue)
                )
                .foregroundStyle(.green)
                .symbolSize(100)
                
                // Current position annotation
                RuleMark(x: .value("Year", asset.yearsOwned))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top) {
                        Text("Now")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("₡" + String(format: "%.1f", doubleValue/1000000) + "M")
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)y")
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

        private var paymentComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Expected vs Actual Payments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: 12, height: 3)
                        Text("Expected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 12, height: 3)
                        Text("Actual")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            let paymentData = getPaymentComparisonData()
            if !paymentData.isEmpty {
                Chart(paymentData) { point in
                    if point.type == "Expected" {
                        LineMark(
                            x: .value("Month", point.periodName),
                            y: .value("Amount", point.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    } else {
                        BarMark(
                            x: .value("Month", point.periodName),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(.green.opacity(0.7))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("₡\(Int(amount/1000))K")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Payment Data",
                    systemImage: "creditcard",
                    description: Text("No payment activity recorded for this asset")
                )
                .frame(height: 250)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formattedNumber(_ number: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: number)) ?? String(format: "%.*f", decimals, number)
    }

    // Removed Financial Metrics Section grid; metrics are now shown as simple rows in the respective detail cards
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

