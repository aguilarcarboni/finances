//
//  AssetsView.swift
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

extension Asset {
    var currentValue: Double {
        currentMarketValue ?? 0
    }
    
    var loanAmount: Double {
        purchasePrice - downPayment
    }
    
    var monthsOwned: Int {
        let timeInterval = Date().timeIntervalSince(purchaseDate)
        return max(1, Int(timeInterval / (30.44 * 24 * 60 * 60)))
    }
    
    var yearsOwned: Double {
        let timeInterval = Date().timeIntervalSince(purchaseDate)
        return timeInterval / (365.25 * 24 * 60 * 60)
    }
    
    var monthlyPayment: Double {
        guard loanAmount > 0, interestRate > 0 else { return 0 }
        
        let monthlyRate = interestRate / 100 / 12
        let numberOfPayments = Double(loanTermYears * 12)
        
        let numerator = loanAmount * monthlyRate * pow(1 + monthlyRate, numberOfPayments)
        let denominator = pow(1 + monthlyRate, numberOfPayments) - 1
        
        return numerator / denominator
    }
    
    var remainingLoanBalance: Double {
        let totalMonths = loanTermYears * 12
        let monthlyRate = interestRate / 100 / 12
        
        guard monthsOwned < totalMonths, interestRate > 0 else { return 0 }
        
        let remainingPayments = Double(totalMonths - monthsOwned)
        
        let numerator = monthlyPayment * (pow(1 + monthlyRate, remainingPayments) - 1)
        let denominator = monthlyRate * pow(1 + monthlyRate, remainingPayments)
        
        return numerator / denominator
    }
    
    var equity: Double {
        currentValue - remainingLoanBalance
    }
    
    var totalPaidToday: Double {
        let paymentsMade = min(monthsOwned, loanTermYears * 12)
        return downPayment + (monthlyPayment * Double(paymentsMade))
    }
    
    var totalDepreciation: Double {
        purchasePrice - currentValue
    }
    
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
        default:
            return "cube.box.fill"
        }
    }
}

struct AssetDetailView: View {
    let asset: Asset
    @ObservedObject private var expensesAccount = ExpensesAccount.shared
    
    @State private var forecastMonths: Double = 12
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(asset.type)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
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
                    
                    // Asset Details Card
                    assetDetailsCard
                    
                    // Financial Overview Cards
                    financialOverviewCards

                    // Payment Comparison Chart
                    paymentComparisonChartCard

                    // Equity Snapshot
                    equitySnapshotCard
                    
                    // Loan Transfer Outlook
                    loanTransferOutlookCard
                    
                    // Depreciation Risk
                    depreciationRiskCard

                    // Depreciation Chart
                    depreciationChartCard
                    
                }
                .padding()
        }
        .navigationTitle("Asset Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Financial Overview Cards
    private var financialOverviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            
            // Expected Loan Balance
            AssetMetricCard(
                title: "Expected Loan Balance",
                value: asset.remainingLoanBalance,
                subtitle: "at \(asset.interestRate)% APR",
                color: .orange,
                icon: "creditcard"
            )

            // Actual Loan Balance Card
            AssetMetricCard(
                title: "Actual Loan Balance",
                value: actualLoanBalance,
                subtitle: "based on payments made",
                color: actualLoanBalance > asset.remainingLoanBalance ? .red : .green,
                icon: "banknote"
            )
        }
    }
    
    // MARK: - Strategic Widgets for Car Flipping
    private var equitySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Equity Snapshot")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Are you above water or underwater?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: asset.equity >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(asset.equity >= 0 ? .green : .red)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(asset.equity >= 0 ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(asset.equity >= 0 ? "Positive Equity" : "Underwater")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(asset.equity >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(asset.equity >= 0 ? "+" : "-")$\(abs(asset.equity))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(asset.equity >= 0 ? .green : .red)
                }
            }
            
            HStack {
                Text("Equity vs Market Value:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(equityPercentage)%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var loanTransferOutlookCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loan Transfer Outlook")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("How attractive is your loan to a buyer?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(transferFeasibilityScore)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(transferFeasibilityColor)
                    
                    Text("Feasibility")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining Loan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(asset.remainingLoanBalance)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(remainingLoanTimeText)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Payment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(asset.monthlyPayment)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("APR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(asset.interestRate)%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var depreciationRiskCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Depreciation Rate")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("How aggressively is this car losing value?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Loss vs Purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("-\(totalDepreciationPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Annual Loss Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("$\(annualDepreciationAmount)/year")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var sellForecastCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sell Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("How will your equity change over time?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Forecast Period:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(forecastMonths)) months")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $forecastMonths, in: 1...36, step: 1)
                    .tint(.blue)
            }
            
            let forecast = getForecastData(months: Int(forecastMonths))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                VStack(alignment: .center, spacing: 4) {
                    Text("Market Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(forecast.marketValue)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Loan Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(forecast.loanBalance)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Projected Equity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(forecast.equity >= 0 ? "+" : "-")$\(abs(forecast.equity))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(forecast.equity >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var effectiveMonthlyCostCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Effective Monthly Cost")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("What has this car really cost you?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("$\(effectiveMonthlyCost)/mo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Total Out of Pocket")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("$\(totalOutOfPocket)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Current Equity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(asset.equity >= 0 ? "+" : "-")$\(abs(asset.equity))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(asset.equity >= 0 ? .green : .red)
                }
                
                Divider()
                
                HStack {
                    Text("Net Cost")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("$\(netCost)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Months Owned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(asset.monthsOwned)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Depreciation Chart Card
    private var depreciationChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value Over Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Current position vs projected depreciation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Current value indicator
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
                // Projected depreciation line
                ForEach(depreciationData) { dataPoint in
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
                            Text("$\(doubleValue/1000, specifier: "%.0f")K")
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
            .chartLegend(position: .bottom) {
                HStack {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue.opacity(0.7))
                            .frame(width: 12, height: 2)
                        Text("Projected")
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 12, height: 2)
                        Text("Actual")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            // Performance vs projection summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("vs Projection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let difference = asset.currentValue - projectedValueAtCurrentTime
                    Text("\(difference >= 0 ? "+" : "")$\(difference, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundStyle(difference >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ownership Period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(asset.yearsOwned, specifier: "%.1f") years")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Payment Schedule Chart Card
    private var paymentScheduleChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Breakdown")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Monthly payment of $\(asset.monthlyPayment) split between principal and interest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Chart(paymentScheduleData) { dataPoint in
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Amount", dataPoint.type == "Principal" ? dataPoint.principal : dataPoint.interest)
                )
                .foregroundStyle(dataPoint.type == "Principal" ? .green : .orange)
                .position(by: .value("Type", dataPoint.type))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("$\(doubleValue)")
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
                            Text("\(intValue)")
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartLegend(position: .bottom)
            
            // Payment Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Interest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(totalInterestPaid)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Payments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(totalPayments)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Payment Comparison Chart Card
    private var paymentComparisonChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Comparison")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Expected biweekly payments vs. actual expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            Chart(paymentComparisonData) { dataPoint in
                BarMark(
                    x: .value("Period", dataPoint.periodName),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(dataPoint.type == "Expected" ? .blue : .orange)
                .position(by: .value("Type", dataPoint.type))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("$\(doubleValue/1000, specifier: "%.0f")K")
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.caption)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartLegend(position: .bottom) {
                HStack {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                        Text("Expected")
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.orange)
                            .frame(width: 12, height: 12)
                        Text("Actual")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            // Payment Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected Biweekly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(asset.monthlyPayment / 2, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Actual Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(averageActualPayment, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.top, 8)
            
            // Variance Analysis
            HStack {
                Text("Biweekly Variance:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let variance = averageActualPayment - (asset.monthlyPayment / 2)
                Text("\(variance >= 0 ? "+" : "")$\(variance, specifier: "%.0f")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(variance >= 0 ? .red : .green)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Asset Details Card
    private var assetDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(title: "Purchase Date", value: formattedDate(asset.purchaseDate))
                DetailRow(title: "Purchase Price", value: "$\(asset.purchasePrice)")
                DetailRow(title: "Current Value", value: "$\(asset.currentValue)")
                DetailRow(title: "Down Payment", value: "$\(asset.downPayment)")
                DetailRow(title: "Interest Rate", value: "\(asset.interestRate)%")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var valueChangeText: String {
        let change = asset.totalDepreciation
        let changePercent = (change / asset.purchasePrice) * 100
        return change >= 0 ? "-$\(abs(change)) (\(changePercent)%)" : "+$\(abs(change)) (\(abs(changePercent))%)"
    }
    
    private var valueChangeColor: Color {
        asset.totalDepreciation >= 0 ? .red : .green
    }
    
    private var depreciationData: [DepreciationDataPoint] {
        // Calculate current effective annual depreciation rate based on actual data from start of loan
        let totalDepreciationPercentage = (asset.totalDepreciation / asset.purchasePrice) * 100
        let currentDepreciationRate = totalDepreciationPercentage / (asset.yearsOwned * 100)
        let effectiveAnnualRate = min(0.25, max(0.05, currentDepreciationRate)) // Cap between 5% and 25%
        
        // Create curved depreciation projection from year 0 using the effective rate we now know
        // This shows what the curve would have looked like from the start with this rate
        return (0...10).map { year in
            let value = asset.purchasePrice * pow(1 - effectiveAnnualRate, Double(year))
            return DepreciationDataPoint(year: year, value: max(0, value))
        }
    }
    
    private var actualValueData: [DepreciationDataPoint] {
        // Create actual value points from purchase to now
        var dataPoints: [DepreciationDataPoint] = []
        
        // Starting point (purchase)
        dataPoints.append(DepreciationDataPoint(year: 0, value: asset.purchasePrice))
        
        // Current point (actual market value)
        dataPoints.append(DepreciationDataPoint(year: Int(asset.yearsOwned), value: asset.currentValue))
        
        return dataPoints
    }
    
    private var projectedValueAtCurrentTime: Double {
        // Use the same effective annual rate calculation as depreciationData
        let totalDepreciationPercentage = (asset.totalDepreciation / asset.purchasePrice) * 100
        let currentDepreciationRate = totalDepreciationPercentage / (asset.yearsOwned * 100)
        let effectiveAnnualRate = min(0.25, max(0.05, currentDepreciationRate))
        return asset.purchasePrice * pow(1 - effectiveAnnualRate, asset.yearsOwned)
    }
    
    private var paymentScheduleData: [PaymentDataPoint] {
        guard asset.loanAmount > 0, asset.interestRate > 0 else { return [] }
        
        let monthlyRate = asset.interestRate / 100 / 12
        let totalPayments = asset.loanTermYears * 12
        let payment = asset.monthlyPayment
        var remainingBalance = asset.loanAmount
        var dataPoints: [PaymentDataPoint] = []
        
        for month in 1...totalPayments {
            let interestPayment = remainingBalance * monthlyRate
            let principalPayment = payment - interestPayment
            remainingBalance -= principalPayment
            
            // Add principal payment data point
            dataPoints.append(PaymentDataPoint(
                month: month,
                principal: principalPayment,
                interest: 0,
                type: "Principal"
            ))
            
            // Add interest payment data point
            dataPoints.append(PaymentDataPoint(
                month: month,
                principal: 0,
                interest: interestPayment,
                type: "Interest"
            ))
        }
        
        return dataPoints
    }
    
    private var totalInterestPaid: Double {
        paymentScheduleData.reduce(0) { $0 + $1.interest }
    }
    
    private var totalPayments: Double {
        asset.monthlyPayment * Double(asset.loanTermYears * 12)
    }
    
    // MARK: - Strategic Calculations for Car Flipping
    
    private var equityPercentage: Double {
        guard asset.currentValue > 0 else { return 0 }
        return (asset.equity / asset.currentValue) * 100
    }
    
    private var remainingLoanTimeText: String {
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
    
    private var transferFeasibilityScore: String {
        let remainingYears = Double(asset.loanTermYears * 12 - asset.monthsOwned) / 12
        let rate = asset.interestRate
        
        // Score based on remaining term and interest rate
        if remainingYears > 3 && rate < 5 {
            return "HIGH"
        } else if remainingYears > 2 && rate < 8 {
            return "MEDIUM"
        } else {
            return "LOW"
        }
    }
    
    private var transferFeasibilityColor: Color {
        switch transferFeasibilityScore {
        case "HIGH": return .green
        case "MEDIUM": return .orange
        default: return .red
        }
    }
    
    // 3. Depreciation Risk Calculations
    private var totalDepreciationPercentage: Double {
        (asset.totalDepreciation / asset.purchasePrice) * 100
    }
    
    private var annualDepreciationAmount: Double {
        guard asset.yearsOwned > 0 else { return 0 }
        return asset.totalDepreciation / asset.yearsOwned
    }
    
    private var monthlyPrincipalPayment: Double {
        let monthlyRate = asset.interestRate / 100 / 12
        let interestPayment = asset.remainingLoanBalance * monthlyRate
        return asset.monthlyPayment - interestPayment
    }
    
    private var depreciationToPrincipalRatio: Double {
        let monthlyDepreciation = annualDepreciationAmount / 12
        guard monthlyPrincipalPayment > 0 else { return 0 }
        return monthlyDepreciation / monthlyPrincipalPayment
    }
    
    // 4. Effective Monthly Cost Calculations    
    private var totalOutOfPocket: Double {
        asset.totalPaidToday
    }
    
    private var netCost: Double {
        totalOutOfPocket - max(0, asset.equity)
    }
    
    private var effectiveMonthlyCost: Double {
        netCost / Double(asset.monthsOwned)
    }
    
    // MARK: - Actual Loan Balance Calculation
    private var totalActualPaymentsMade: Double {
        var totalPaid = asset.downPayment // Start with down payment
        
        // Add up all actual car payments from expenses using the same helper function
        for period in expensesAccount.biweeklyPeriods {
            totalPaid += getActualPaymentForPeriod(period)
        }
        
        return totalPaid
    }
    
    private var actualLoanBalance: Double {
        // Calculate remaining balance based on actual payment amounts with proper amortization
        let monthlyRate = asset.interestRate / 100 / 12
        var remainingBalance = asset.loanAmount
        
        // Process each period's actual payments
        for period in expensesAccount.biweeklyPeriods {
            let actualPayment = getActualPaymentForPeriod(period)
            
            if actualPayment > 0 && remainingBalance > 0 {
                // Calculate interest for this period
                let interestPayment = remainingBalance * monthlyRate
                
                // Calculate principal payment (remaining goes to principal)
                let principalPayment = max(0, actualPayment - interestPayment)
                
                // Reduce remaining balance by principal payment
                remainingBalance = max(0, remainingBalance - principalPayment)
            }
        }
        
        return remainingBalance
    }
    
    // MARK: - Payment Comparison Data
    private func getActualPaymentForPeriod(_ period: BiweeklyPeriod) -> Double {
        let carPaymentTransactions = period.transactions.filter { 
            $0.category == asset.expenseCategory && 
            $0.type == .debit
        }
        return carPaymentTransactions.reduce(0) { $0 + $1.amount } / 515.0 // Convert from CRC to USD
    }
    
    private var paymentComparisonData: [PaymentComparisonDataPoint] {
        var dataPoints: [PaymentComparisonDataPoint] = []
        
        // Group transactions by biweekly period and calculate totals
        for period in expensesAccount.biweeklyPeriods {
            let actualAmount = getActualPaymentForPeriod(period)
            let expectedAmount = asset.monthlyPayment / 2 // Split monthly payment in half for biweekly periods
            
            let periodFormatter = DateFormatter()
            periodFormatter.dateFormat = "MMM d"
            let startDate = periodFormatter.string(from: period.startDate)
            let endDate = periodFormatter.string(from: period.endDate)
            let periodName = "\(startDate)-\(String(endDate.dropFirst(4)))" // e.g., "May 1-15"
            
            // Add expected payment data point
            dataPoints.append(PaymentComparisonDataPoint(
                periodName: periodName,
                amount: expectedAmount,
                type: "Expected"
            ))
            
            // Add actual payment data point (only if there was an actual payment)
            if actualAmount > 0 {
                dataPoints.append(PaymentComparisonDataPoint(
                    periodName: periodName,
                    amount: actualAmount,
                    type: "Actual"
                ))
            }
        }
        
        return dataPoints
    }
    
    private var averageActualPayment: Double {
        let actualPayments = expensesAccount.biweeklyPeriods.compactMap { period in
            let amount = getActualPaymentForPeriod(period)
            return amount > 0 ? amount : nil
        }
        guard !actualPayments.isEmpty else { return 0 }
        return actualPayments.reduce(0, +) / Double(actualPayments.count)
    }
    
    // MARK: - Forecast Data Structure
    struct ForecastData {
        let marketValue: Double
        let loanBalance: Double
        let equity: Double
    }
    
    private func getForecastData(months: Int) -> ForecastData {
        let futureMonthsFromPurchase = asset.monthsOwned + months
        let futureYearsFromPurchase = Double(futureMonthsFromPurchase) / 12
        
        // Calculate future market value using effective annual depreciation rate
        let currentDepreciationRate = totalDepreciationPercentage / (asset.yearsOwned * 100)
        let effectiveAnnualRate = min(0.25, max(0.05, currentDepreciationRate))
        let futureMarketValue = asset.purchasePrice * pow(1 - effectiveAnnualRate, futureYearsFromPurchase)
        
        // Calculate future loan balance
        let totalLoanMonths = asset.loanTermYears * 12
        let futureLoanBalance: Double
        
        if futureMonthsFromPurchase >= totalLoanMonths {
            futureLoanBalance = 0
        } else {
            let monthlyRate = asset.interestRate / 100 / 12
            let payment = asset.monthlyPayment
            let remainingPayments = Double(totalLoanMonths - futureMonthsFromPurchase)
            
            let numerator = payment * (pow(1 + monthlyRate, remainingPayments) - 1)
            let denominator = monthlyRate * pow(1 + monthlyRate, remainingPayments)
            
            futureLoanBalance = numerator / denominator
        }
        
        let futureEquity = futureMarketValue - futureLoanBalance
        
        return ForecastData(
            marketValue: futureMarketValue,
            loanBalance: futureLoanBalance,
            equity: futureEquity
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AssetMetricCard: View {
    let title: String
    let value: Double
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("$\(abs(value))")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
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