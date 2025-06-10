//
//  AssetsView.swift
//  finances
//
//  Created by Andrés on 10/6/2025.
//

import Foundation
import SwiftUI
import Charts

struct Asset: Identifiable {
    var id: UUID
    var name: String
    var type: String
    var purchaseDate: Date
    var purchasePrice: Double
    var downPayment: Double
    var interestRate: Double
    var loanTermYears: Int
    var currentMarketValue: Double?
    var depreciationMethod: DepreciationMethod
    var customDepreciationRate: Double?
    var notes: String?
}

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

struct AssetsView: View {
    let asset = Asset(
        id: UUID(),
        name: "Nissan Magnite",
        type: "Car",
        purchaseDate: Date(timeIntervalSince1970: 1750011564),
        purchasePrice: 24900.00,
        downPayment: 6000.00,
        interestRate: 7.5,
        loanTermYears: 8,
        currentMarketValue: 24900.00,
        depreciationMethod: .straightLine(years: 5),
        customDepreciationRate: nil,
        notes: "Primary car."
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Financial Overview Cards
                financialOverviewCards
                
                // Depreciation Chart
                depreciationChartCard
                
                // Payment Schedule Chart
                paymentScheduleChartCard
                
                // Asset Details Card
                assetDetailsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(asset.type)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Asset Type Icon
                Image(systemName: iconForAssetType(asset.type))
                    .font(.title)
                    .foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Financial Overview Cards
    private var financialOverviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Current Value Card
            MetricCard(
                title: "Current Value",
                value: currentValue,
                subtitle: valueChangeText,
                color: valueChangeColor,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // Monthly Payment Card
            MetricCard(
                title: "Monthly Payment",
                value: monthlyPayment,
                subtitle: "for \(asset.loanTermYears) years",
                color: .blue,
                icon: "calendar"
            )
            
            // Total Equity Card
            MetricCard(
                title: "Total Equity",
                value: totalEquity,
                subtitle: "Owned: \(equityPercentage)%",
                color: .green,
                icon: "percent"
            )
            
            // Loan Balance Card
            MetricCard(
                title: "Loan Balance",
                value: loanBalance,
                subtitle: "at \(asset.interestRate)% APR",
                color: .orange,
                icon: "creditcard"
            )
        }
    }
    
    // MARK: - Depreciation Chart Card
    private var depreciationChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value Over Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Projected depreciation based on \(depreciationDescription(asset.depreciationMethod).lowercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Chart(depreciationData) { dataPoint in
                LineMark(
                    x: .value("Year", dataPoint.year),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Year", dataPoint.year),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("$\(doubleValue/1000)K")
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
                    
                    Text("Monthly payment of $\(monthlyPayment) split between principal and interest")
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
    
    // MARK: - Asset Details Card
    private var assetDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(title: "Purchase Date", value: formattedDate(asset.purchaseDate))
                DetailRow(title: "Purchase Price", value: "$\(asset.purchasePrice)")
                DetailRow(title: "Down Payment", value: "$\(asset.downPayment)")
                DetailRow(title: "Interest Rate", value: "\(asset.interestRate)%")
                
                if let notes = asset.notes {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    private var currentValue: Double {
        asset.currentMarketValue ?? calculateCurrentValue()
    }
    
    private var loanBalance: Double {
        max(0, asset.purchasePrice - asset.downPayment)
    }
    
    private var monthlyPayment: Double {
        guard loanBalance > 0, asset.interestRate > 0 else { return 0 }
        
        let principal = loanBalance
        let monthlyRate = asset.interestRate / 100 / 12
        let numberOfPayments = Double(asset.loanTermYears * 12)
        
        // Monthly payment formula: M = P * [r(1 + r)^n] / [(1 + r)^n - 1]
        let numerator = principal * monthlyRate * pow(1 + monthlyRate, numberOfPayments)
        let denominator = pow(1 + monthlyRate, numberOfPayments) - 1
        
        return numerator / denominator
    }
    
    private var totalEquity: Double {
        currentValue - loanBalance
    }
    
    private var equityPercentage: Double {
        guard currentValue > 0 else { return 0 }
        return (totalEquity / currentValue) * 100
    }
    
    private var totalDepreciation: Double {
        asset.purchasePrice - currentValue
    }
    
    private var valueChangeText: String {
        let change = totalDepreciation
        let changePercent = (change / asset.purchasePrice) * 100
        return change >= 0 ? "-$\(abs(change)) (\(changePercent)%)" : "+$\(abs(change)) (\(abs(changePercent))%)"
    }
    
    private var valueChangeColor: Color {
        totalDepreciation >= 0 ? .red : .green
    }
    
    private var depreciationData: [DepreciationDataPoint] {
        switch asset.depreciationMethod {
        case .straightLine(let years):
            let annualDepreciation = asset.purchasePrice / Double(years)
            return (0...years).map { year in
                let value = max(0, asset.purchasePrice - (Double(year) * annualDepreciation))
                return DepreciationDataPoint(year: year, value: value)
            }
        case .custom(let rate):
            return (0...10).map { year in
                let value = asset.purchasePrice * pow(1 - rate/100, Double(year))
                return DepreciationDataPoint(year: year, value: max(0, value))
            }
        }
    }
    
    private var paymentScheduleData: [PaymentDataPoint] {
        guard loanBalance > 0, asset.interestRate > 0 else { return [] }
        
        let monthlyRate = asset.interestRate / 100 / 12
        let totalPayments = asset.loanTermYears * 12
        let payment = monthlyPayment
        var remainingBalance = loanBalance
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
        monthlyPayment * Double(asset.loanTermYears * 12)
    }
    
    // MARK: - Helper Functions
    private func calculateCurrentValue() -> Double {
        let yearsOwned = Date().timeIntervalSince(asset.purchaseDate) / (365.25 * 24 * 60 * 60)
        
        switch asset.depreciationMethod {
        case .straightLine(let years):
            let annualDepreciation = asset.purchasePrice / Double(years)
            return max(0, asset.purchasePrice - (yearsOwned * annualDepreciation))
        case .custom(let rate):
            return asset.purchasePrice * pow(1 - rate/100, yearsOwned)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func depreciationDescription(_ method: DepreciationMethod) -> String {
        switch method {
        case .straightLine(let years):
            return "Straight Line (\(years) years)"
        case .custom(let rate):
            return "Custom (\(rate)% per year)"
        }
    }
    
    private func iconForAssetType(_ type: String) -> String {
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

// MARK: - Supporting Views
struct MetricCard: View {
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

#Preview {
    AssetsView()
}
