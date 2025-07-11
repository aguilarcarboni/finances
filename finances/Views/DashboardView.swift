import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var wealthEngine = WealthEngineManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Net Worth Section
                    NetWorthCardView(
                        netWorth: wealthEngine.netWorth,
                        history: wealthEngine.netWorthHistory
                    )
                    
                    // Capital Allocation Section
                    CapitalAllocationCardView(allocation: wealthEngine.capitalAllocation)

                }
            }
            .navigationTitle("Finances")
        }
    }
}

// MARK: - Net Worth Card

struct NetWorthCardView: View {
    let netWorth: Double
    let history: [NetWorthSnapshot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Net Worth")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "dollarsign.circle")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            Text(netWorth.formatted(.currency(code: "CRC")))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(netWorth >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Capital Allocation Card

struct CapitalAllocationCardView: View {
    let allocation: CapitalAllocation
    @ObservedObject private var investmentsAccount = InvestmentsAccount.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Capital Allocation")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chart.pie")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            // Investment Status Warning
            if investmentsAccount.hasOfflineData {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Investments offline - not included in calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

                        // Pie Chart
            if allocation.totalCapital > 0 {
                Chart {
                    if allocation.savings > 0 {
                        SectorMark(
                            angle: .value("Savings", allocation.savingsPercentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                    
                    if allocation.investments > 0 {
                        SectorMark(
                            angle: .value("Investments", allocation.investmentsPercentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(.green)
                        .cornerRadius(4)
                    }
                    
                    if allocation.assets > 0 {
                        SectorMark(
                            angle: .value("Assets", allocation.assetsPercentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(.purple)
                        .cornerRadius(4)
                    }
                    
                    if allocation.cash > 0 {
                        SectorMark(
                            angle: .value("Cash", allocation.cashPercentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(.yellow)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 150)
            } else {
                // Show a placeholder chart when no data
                Circle()
                    .frame(height: 150)
                    .overlay(
                        Text("No assets yet")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    )
            }
            
            // Legend - always show regardless of total capital
            VStack(spacing: 8) {
                CapitalAllocationRow(title: "Savings", amount: allocation.savings, percentage: allocation.savingsPercentage, color: .blue)
                CapitalAllocationRow(title: "Investments", amount: allocation.investments, percentage: allocation.investmentsPercentage, color: .green)
                CapitalAllocationRow(title: "Assets", amount: allocation.assets, percentage: allocation.assetsPercentage, color: .purple)
                CapitalAllocationRow(title: "Cash", amount: allocation.cash, percentage: allocation.cashPercentage, color: .yellow)
                
                // Separator line
                Divider()
                    .padding(.vertical, 4)
                
                if allocation.debt > 0 {
                    CapitalAllocationRow(title: "Debt", amount: -allocation.debt, percentage: allocation.debtPercentage, color: .red)
                    
                    // Final calculation separator
                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CapitalAllocationRow: View {
    let title: String
    let amount: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.caption)
            
            Spacer()
            
            Text("\(percentage.formatted(.percent.precision(.fractionLength(1))))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(amount.formatted(.currency(code: "CRC")))
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
