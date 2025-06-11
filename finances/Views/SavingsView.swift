import SwiftUI
import Charts
import Combine

class SavingsViewModel: ObservableObject {
    @Published var savingsAccount = SavingsAccount.shared
    @Published var expensesAccount = ExpensesAccount.shared
    
    var savingsGrowthData: [(period: String, balance: Double)] {
        var runningBalance: Double = 0
        return savingsAccount.biweeklyPeriods.map { period in
            runningBalance += period.netBalance
            return (period: period.dateRange, balance: runningBalance)
        }
    }
    
    var totalSavingsBalance: Double {
        savingsGrowthData.last?.balance ?? 0
    }
    
    var transferValidation: (isValid: Bool, message: String) {
        let expensesSavingsTransfers = expensesAccount.biweeklyPeriods.reduce(0.0) { total, period in
            total + period.debitsForCategory("Savings")
        }
        
        let savingsIncomingTransfers = savingsAccount.biweeklyPeriods.reduce(0.0) { total, period in
            total + period.creditsForCategory("Emergency Fund") // Where the transfers go
        }
        
        let isValid = abs(expensesSavingsTransfers - savingsIncomingTransfers) < 1.0 // Allow for rounding
        let message = isValid 
            ? "✅ Transfers match perfectly" 
            : "⚠️ Transfer mismatch: ₡\(Int(abs(expensesSavingsTransfers - savingsIncomingTransfers)).formatted()) difference"
        
        return (isValid, message)
    }
}

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

// MARK: - Preview
struct SavingsView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsView()
    }
} 