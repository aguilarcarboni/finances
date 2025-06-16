import SwiftUI
import Charts
import Combine

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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    self.summaryHeader
                    
                    self.emergencyFundProgressSection
                    
                    if savingsAccount.isEmergencyFundComplete && !savingsAccount.savingsCategories.isEmpty {
                        self.savingsCategoriesSection
                    }
                    
                    self.growthChartSection
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
                Text("Savings Account")
                    .font(.headline)
                    .foregroundColor(.primary)
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
                Text("₡\(Int(savingsAccount.totalSavingsBalance).formatted())")
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
                        Text("₡\(Int(savingsAccount.totalSavingsBalance).formatted())")
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
            
            let chartData = savingsAccount.savingsGrowthData
            
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
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
