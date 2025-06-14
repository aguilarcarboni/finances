import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var financialSystem = FinancialSystemViewModel()
    
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
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Net Worth Header
                    netWorthHeader
                    
                    // Financial Health Score
                    financialHealthCard
                    
                    // Daily Recommendation
                    recommendationCard
                    
                    // Capital Allocation Pie Chart
                    capitalAllocationCard
                    
                    // Quick Metrics Grid
                    quickMetricsGrid
                    
                    // Emergency Buffer Status
                    emergencyBufferCard
                    
                    // Cash Flow Summary
                    cashFlowCard
                }
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .task {
                await financialSystem.refreshInvestmentData()
            }
            .refreshable {
                await financialSystem.refreshInvestmentData()
            }
        }
    }
    
    // MARK: - Net Worth Header
    private var netWorthHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Worth")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(currencyFormatter.string(from: NSNumber(value: financialSystem.netWorth)) ?? "₡0")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Savings Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(financialSystem.savingsRate))%")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(financialSystem.savingsRate >= 20 ? .green : .orange)
                }
            }
            
            // Net Worth Growth Indicator (simplified)
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Track net worth growth over time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Financial Health Score
    private var financialHealthCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Financial Health Score")
                    .font(.title2.weight(.semibold))
                
                Spacer()
                
                Text("\(financialSystem.financialHealthScore.score)")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(getHealthScoreColor(financialSystem.financialHealthScore.score))
            }
            
            // Health Score Components
            VStack(spacing: 12) {
                ForEach(financialSystem.financialHealthScore.components, id: \.name) { component in
                    HStack {
                        Text(component.name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ProgressView(value: Double(component.score), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: getHealthScoreColor(component.score)))
                            .frame(width: 80)
                        
                        Text("\(component.score)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(getHealthScoreColor(component.score))
                            .frame(width: 30)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Daily Recommendation
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Recommendation")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text(financialSystem.dailyRecommendation.priority)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getPriorityColor(financialSystem.dailyRecommendation.priority))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Text(financialSystem.dailyRecommendation.title)
                .font(.subheadline.weight(.medium))
            
            Text(financialSystem.dailyRecommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(financialSystem.dailyRecommendation.action)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Capital Allocation Chart
    private var capitalAllocationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capital Allocation")
                .font(.title2.weight(.semibold))
            
            Chart(financialSystem.capitalAllocation, id: \.category) { allocation in
                SectorMark(
                    angle: .value("Amount", allocation.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2.0
                )
                .foregroundStyle(by: .value("Category", allocation.category))
                .opacity(0.8)
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .center)
            
            // Allocation Details
            VStack(spacing: 8) {
                ForEach(financialSystem.capitalAllocation, id: \.category) { allocation in
                    HStack {
                        Text(allocation.category)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(allocation.percentage))%")
                            .font(.subheadline.weight(.medium))
                        
                        Text(currencyFormatter.string(from: NSNumber(value: allocation.amount)) ?? "₡0")
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Metrics Grid
    private var quickMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            
            MetricCard(
                title: "Monthly Income",
                value: currencyFormatter.string(from: NSNumber(value: financialSystem.monthlyIncome)) ?? "₡0",
                icon: "arrow.down.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Monthly Expenses",
                value: currencyFormatter.string(from: NSNumber(value: financialSystem.monthlyExpenses)) ?? "₡0",
                icon: "arrow.up.circle.fill",
                color: .red
            )
            
            MetricCard(
                title: "Debt Pressure",
                value: "\(Int(financialSystem.debtPressureIndex))%",
                icon: "exclamationmark.triangle.fill",
                color: financialSystem.debtPressureIndex > 30 ? .red : .orange
            )
            
            MetricCard(
                title: "Investment Value",
                value: currencyFormatter.string(from: NSNumber(value: financialSystem.totalInvestmentValue)) ?? "₡0",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
        }
    }
    
    // MARK: - Emergency Buffer Card
    private var emergencyBufferCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Emergency Buffer")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text("\(String(format: "%.1f", financialSystem.emergencyBufferMonths)) months")
                    .font(.title2.weight(.bold))
                    .foregroundColor(financialSystem.emergencyBufferMonths >= 6 ? .green : .orange)
            }
            
            ProgressView(value: min(financialSystem.emergencyBufferMonths / 6, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: financialSystem.emergencyBufferMonths >= 6 ? .green : .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Current: \(currencyFormatter.string(from: NSNumber(value: financialSystem.savingsAccount.getAccountSummary().netBalance)) ?? "₡0")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Target: 6 months")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Cash Flow Card
    private var cashFlowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash Flow Summary")
                .font(.headline.weight(.semibold))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Surplus")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let surplus = financialSystem.monthlyIncome - financialSystem.monthlyExpenses
                    Text(currencyFormatter.string(from: NSNumber(value: surplus)) ?? "₡0")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(surplus >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Flow Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let ratio = financialSystem.monthlyIncome > 0 ? (financialSystem.monthlyExpenses / financialSystem.monthlyIncome) * 100 : 0
                    Text("\(Int(ratio))%")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(ratio <= 80 ? .green : .orange)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    private func getHealthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func getPriorityColor(_ priority: String) -> Color {
        switch priority.uppercased() {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        case "LOW": return .blue
        default: return .gray
        }
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
} 