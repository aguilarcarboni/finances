import SwiftUI
import Charts

struct DecisionModulesView: View {
    @StateObject private var financialSystem = FinancialSystemViewModel()
    @State private var selectedTool: DecisionTool = .payoffVsInvest
    
    enum DecisionTool: String, CaseIterable {
        case payoffVsInvest = "Payoff vs Invest"
        case capitalDeployment = "Capital Deployment"
        case liquidityRisk = "Liquidity Risk"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tool Selector
                toolSelector
                
                // Selected Tool Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTool {
                        case .payoffVsInvest:
                            PayoffVsInvestTool(financialSystem: financialSystem)
                        case .capitalDeployment:
                            CapitalDeploymentTool(financialSystem: financialSystem)
                        case .liquidityRisk:
                            LiquidityRiskTool(financialSystem: financialSystem)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Decision Tools")
        }
    }
    
    private var toolSelector: some View {
        Picker("Decision Tool", selection: $selectedTool) {
            ForEach(DecisionTool.allCases, id: \.self) { tool in
                Text(tool.rawValue).tag(tool)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

// MARK: - Payoff vs Invest Tool
struct PayoffVsInvestTool: View {
    let financialSystem: FinancialSystemViewModel
    @State private var extraPaymentAmount: Double = 50000
    @State private var expectedInvestmentReturn: Double = 7.0
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Payoff vs Invest Analysis")
                .font(.title2.weight(.bold))
            
            Text("Compare paying extra on debt vs investing that money")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Asset Info (using first asset as example)
            if let asset = financialSystem.assetsViewModel.assets.first {
                assetInfoCard(for: asset)
                
                // Input Controls
                inputControls
                
                // Analysis Results
                analysisResults(for: asset)
            } else {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "car.circle",
                    description: Text("Add an asset with debt to use this tool")
                )
            }
        }
    }
    
    private func assetInfoCard(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: asset.iconName)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.headline)
                    Text("\(String(format: "%.1f", asset.interestRate))% APR")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currencyFormatter.string(from: NSNumber(value: asset.remainingLoanBalance)) ?? "₡0")
                        .font(.headline.weight(.semibold))
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var inputControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Parameters")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Extra Monthly Payment: \(currencyFormatter.string(from: NSNumber(value: extraPaymentAmount)) ?? "₡0")")
                    .font(.subheadline)
                Slider(value: $extraPaymentAmount, in: 10000...200000, step: 10000)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Expected Investment Return: \(String(format: "%.1f", expectedInvestmentReturn))%")
                    .font(.subheadline)
                Slider(value: $expectedInvestmentReturn, in: 3...15, step: 0.5)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func analysisResults(for asset: Asset) -> some View {
        let payoffAnalysis = financialSystem.assetsViewModel.payoffAnalysis(for: asset, extraPayment: extraPaymentAmount)
        let investmentValue = calculateInvestmentValue(monthlyAmount: extraPaymentAmount, years: Double(payoffAnalysis.monthsSaved) / 12, annualReturn: expectedInvestmentReturn)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Results")
                .font(.headline)
            
            // Comparison
            HStack(spacing: 16) {
                ResultCard(
                    title: "Extra Payoff",
                    value: currencyFormatter.string(from: NSNumber(value: payoffAnalysis.interestSaved)) ?? "₡0",
                    subtitle: "Interest Saved",
                    color: .blue
                )
                
                ResultCard(
                    title: "Investment",
                    value: currencyFormatter.string(from: NSNumber(value: investmentValue)) ?? "₡0",
                    subtitle: "Potential Gain",
                    color: .green
                )
            }
            
            // Recommendation
            let betterOption = investmentValue > payoffAnalysis.interestSaved ? "INVEST" : "PAYOFF"
            let difference = abs(investmentValue - payoffAnalysis.interestSaved)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recommendation")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(betterOption)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(betterOption == "INVEST" ? .green : .blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Text("\(betterOption == "INVEST" ? "Investing" : "Paying off debt") provides ₡\(Int(difference).formatted()) more value")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.yellow.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func calculateInvestmentValue(monthlyAmount: Double, years: Double, annualReturn: Double) -> Double {
        let monthsTotal = years * 12
        let monthlyReturn = annualReturn / 100 / 12
        
        guard monthsTotal > 0, monthlyReturn > 0 else { return 0 }
        
        let futureValue = monthlyAmount * (pow(1 + monthlyReturn, monthsTotal) - 1) / monthlyReturn
        let totalInvested = monthlyAmount * monthsTotal
        
        return futureValue - totalInvested
    }
}

// MARK: - Capital Deployment Tool
struct CapitalDeploymentTool: View {
    let financialSystem: FinancialSystemViewModel
    @State private var deploymentAmount: Double = 100000
    @State private var timeHorizon: Double = 3
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Capital Deployment Simulator")
                .font(.title2.weight(.bold))
            
            Text("Analyze moving capital from savings to investments")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Input Controls
            VStack(alignment: .leading, spacing: 16) {
                Text("Parameters")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount: \(currencyFormatter.string(from: NSNumber(value: deploymentAmount)) ?? "₡0")")
                        .font(.subheadline)
                    Slider(value: $deploymentAmount, in: 50000...500000, step: 25000)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Horizon: \(Int(timeHorizon)) years")
                        .font(.subheadline)
                    Slider(value: $timeHorizon, in: 1...10, step: 1)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            
            // Scenarios
            scenarioAnalysis
            
            // Risk Assessment
            riskAssessment
        }
    }
    
    private var scenarioAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scenario Analysis")
                .font(.headline)
            
            VStack(spacing: 12) {
                ScenarioCard(
                    title: "Conservative (5%)",
                    value: calculateFutureValue(amount: deploymentAmount, years: timeHorizon, rate: 5.0),
                    color: .blue
                )
                
                ScenarioCard(
                    title: "Moderate (7%)",
                    value: calculateFutureValue(amount: deploymentAmount, years: timeHorizon, rate: 7.0),
                    color: .green
                )
                
                ScenarioCard(
                    title: "Aggressive (10%)",
                    value: calculateFutureValue(amount: deploymentAmount, years: timeHorizon, rate: 10.0),
                    color: .purple
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var riskAssessment: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment")
                .font(.headline)
            
            let remainingBalance = financialSystem.savingsAccount.getAccountSummary().netBalance - deploymentAmount
            let monthsRemaining = remainingBalance / max(financialSystem.monthlyExpenses, 1)
            
            HStack {
                Text("Emergency Buffer After Deployment")
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.1f", monthsRemaining)) months")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(monthsRemaining >= 3 ? .green : .red)
            }
            
            ProgressView(value: min(monthsRemaining / 6, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: monthsRemaining >= 3 ? .green : .red))
            
            if monthsRemaining < 3 {
                Text("⚠️ This would reduce emergency buffer below 3 months")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func calculateFutureValue(amount: Double, years: Double, rate: Double) -> Double {
        return amount * pow(1 + rate / 100, years)
    }
}

// MARK: - Liquidity Risk Tool
struct LiquidityRiskTool: View {
    let financialSystem: FinancialSystemViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Liquidity Risk Analysis")
                .font(.title2.weight(.bold))
            
            Text("Analyze your financial buffer and survival time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Survival Time
            survivalTimeCard
            
            // Monthly Burn Rate
            burnRateCard
            
            // Recommendations
            recommendationsCard
        }
    }
    
    private var survivalTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Survival Time")
                .font(.headline)
            
            let survivalMonths = financialSystem.emergencyBufferMonths
            
            HStack {
                Text("Current liquid savings can cover:")
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.1f", survivalMonths)) months")
                    .font(.title2.weight(.bold))
                    .foregroundColor(survivalMonths >= 6 ? .green : .red)
            }
            
            ProgressView(value: min(survivalMonths / 12, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: survivalMonths >= 6 ? .green : .red))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Current")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Target: 6+ months")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var burnRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Burn Rate")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("₡\(Int(financialSystem.monthlyExpenses).formatted())")
                        .font(.title3.weight(.semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Burn")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("₡\(Int(financialSystem.monthlyExpenses / 30).formatted())")
                        .font(.title3.weight(.semibold))
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            let survivalMonths = financialSystem.emergencyBufferMonths
            
            if survivalMonths < 3 {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Critical: Build Emergency Fund",
                    description: "Increase emergency savings immediately",
                    priority: .high
                )
            } else if survivalMonths < 6 {
                RecommendationRow(
                    icon: "clock.fill",
                    title: "Strengthen Buffer",
                    description: "Work toward 6-month emergency fund",
                    priority: .medium
                )
            } else {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    title: "Strong Position",
                    description: "Consider deploying excess capital",
                    priority: .low
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views
struct ResultCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

struct ScenarioCard: View {
    let title: String
    let value: Double
    let color: Color
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Text(currencyFormatter.string(from: NSNumber(value: value)) ?? "₡0")
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(priority.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DecisionModulesView()
} 