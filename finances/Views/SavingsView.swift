import SwiftUI
import Charts
import Combine


struct SavingsView: View {
    @StateObject private var viewModel = SavingsViewModel()
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // Current Savings Summary Header (matching ExpensesAccountView style)
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
                            Text("₡\(Int(viewModel.totalSavingsBalance).formatted())")
                                .font(.title2.monospacedDigit())
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Emergency Fund Progress Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Emergency Fund Progress")
                                .font(.title2.bold())
                            Spacer()
                            Text("₡\(Int(viewModel.emergencyFundTarget).formatted())")
                                .font(.title3.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Progress Bar
                            ProgressView(value: viewModel.emergencyFundProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .scaleEffect(x: 1, y: 2.5, anchor: .center)
                            
                            // Progress Details
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("₡\(Int(viewModel.totalSavingsBalance).formatted())")
                                        .font(.subheadline.monospacedDigit())
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 4) {
                                    Text("Progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(viewModel.emergencyFundProgressPercentage))%")
                                        .font(.title3.monospacedDigit())
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Remaining")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("₡\(Int(viewModel.emergencyFundRemaining).formatted())")
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
                    
                    // Savings Categories Section (shown when emergency fund is complete)
                    if viewModel.isEmergencyFundComplete && !viewModel.savingsCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Savings Categories")
                                    .font(.title2.bold())
                                Spacer()
                                Text("₡\(Int(viewModel.excessSavings).formatted())")
                                    .font(.title3.monospacedDigit())
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 16) {
                                ForEach(viewModel.savingsCategories, id: \.name) { category in
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
                    
                    // Growth Chart Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Savings Growth")
                            .font(.title2.bold())
                        
                        if !viewModel.savingsGrowthData.isEmpty {
                            Chart(viewModel.savingsGrowthData, id: \.period) { item in
                                AreaMark(
                                    x: .value("Period", item.period),
                                    y: .value("Balance", item.balance)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green.opacity(0.6), .green.opacity(0.1)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                LineMark(
                                    x: .value("Period", item.period),
                                    y: .value("Balance", item.balance)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                
                                PointMark(
                                    x: .value("Period", item.period),
                                    y: .value("Balance", item.balance)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(60)
                            }
                            .frame(height: 250)
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let balance = value.as(Double.self) {
                                            Text("₡\(Int(balance/1000))K")
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
            .navigationTitle("Savings")
        }
    }
}
