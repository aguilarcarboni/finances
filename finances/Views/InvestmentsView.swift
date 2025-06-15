import SwiftUI

struct InvestmentsView: View {
    @StateObject private var viewModel = InvestmentsViewModel()
    @ObservedObject private var investmentsAccount = InvestmentsAccount.shared
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private func findItem(by title: String) -> AccountSummaryItem? {
        viewModel.items.first { $0.title.lowercased() == title.lowercased() }
    }

    var body: some View {
        NavigationView {
            Group {
                if investmentsAccount.isConnectedToIBKR {
                    // Show investment data when connected
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Connection Status Card
                            ConnectionStatusCard()
                            
                            // Portfolio Overview Card
                            PortfolioOverviewCard()
                            
                            // Performance Metrics Card  
                            PerformanceMetricsCard()
                            
                            // Asset Allocation Card
                            AssetAllocationCard()
                            
                            // Rebalancing Recommendations Card
                            if investmentsAccount.needsRebalancing {
                                RebalancingCard()
                            }
                            
                            // Transaction History
                            TransactionHistoryCard()
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Show content unavailable when offline
                    ContentUnavailableView {
                        Label("Investments Offline", systemImage: "wifi.slash")
                    } description: {
                        Text("Connect to IBKR to view your investment portfolio and real-time data.")
                    } actions: {
                        Button("Connect to IBKR") {
                            Task {
                                await viewModel.connectToIBKR()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .navigationTitle("Investments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                    .disabled(!investmentsAccount.isConnectedToIBKR)
                }
            }
        }
    }
    
    // MARK: - Connection Status Card
    @ViewBuilder
    private func ConnectionStatusCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: investmentsAccount.isConnectedToIBKR ? "wifi" : "wifi.slash")
                    .foregroundColor(investmentsAccount.isConnectedToIBKR ? .green : .orange)
                
                Text("IBKR Connection")
                    .font(.headline)
                
                Spacer()
                
                Text(investmentsAccount.isConnectedToIBKR ? "Connected" : "Offline")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(investmentsAccount.isConnectedToIBKR ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(investmentsAccount.isConnectedToIBKR ? .green : .orange)
                    .cornerRadius(8)
            }
            
            if !investmentsAccount.isConnectedToIBKR {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Offline mode: Investment data won't affect your dashboard calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            if let lastSync = investmentsAccount.lastSyncDate {
                Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Portfolio Overview Card
    @ViewBuilder
    private func PortfolioOverviewCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Investment Portfolio")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Portfolio Value Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(investmentsAccount.rawPortfolioValue))
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Day Change: \(formatCurrency(investmentsAccount.offlineAwareDayChange))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(investmentsAccount.offlineAwareDayChange >= 0 ? .green : .red)
                    Text("Return: \(String(format: "%.1f", investmentsAccount.returnPercentage))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(investmentsAccount.returnPercentage >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Performance Metrics Card
    @ViewBuilder
    private func PerformanceMetricsCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance")
                .font(.title2.bold())
            
            VStack(spacing: 16) {
                // Performance Metrics
                let metrics = investmentsAccount.getPerformanceMetrics()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Invested")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(investmentsAccount.totalInvested))
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Unrealized Gains")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(investmentsAccount.unrealizedGains))
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(investmentsAccount.unrealizedGains >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Annualized Return")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", metrics.annualizedReturn))%")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(metrics.annualizedReturn >= 0 ? .green : .red)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diversification Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(investmentsAccount.getDiversificationScorePercentage()))%")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Needs Rebalancing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(investmentsAccount.needsRebalancing ? "Yes" : "No")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(investmentsAccount.needsRebalancing ? .orange : .green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Asset Allocation Card
    @ViewBuilder
    private func AssetAllocationCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Asset Allocation")
                .font(.title2.bold())
            
            ForEach(investmentsAccount.portfolioAllocation, id: \.category) { allocation in
                AllocationRow(
                    category: allocation.category,
                    value: allocation.value,
                    percentage: allocation.percentage,
                    target: investmentsAccount.targetAllocation[allocation.category] ?? 0
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Rebalancing Recommendations Card
    @ViewBuilder
    private func RebalancingCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rebalancing Recommendations")
                .font(.title2.bold())
            
            ForEach(investmentsAccount.rebalancingRecommendations, id: \.category) { recommendation in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.category)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(recommendation.action)
                            .font(.caption)
                            .foregroundColor(recommendation.action == "Buy" ? .green : .red)
                    }
                    
                    Spacer()
                    
                    Text(formatCurrency(recommendation.amount))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(recommendation.action == "Buy" ? .green : .red)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Transaction History
    @ViewBuilder
    private func TransactionHistoryCard() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Transactions")
                .font(.title2.bold())
            
            ForEach(investmentsAccount.transactions.sorted { $0.date > $1.date }.prefix(10), id: \.id) { transaction in
                InvestmentTransactionRow(transaction: transaction)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}

struct AllocationRow: View {
    let category: String
    let value: Double
    let percentage: Double
    let target: Double
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", percentage))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.primary)
                    Text("Target: \(String(format: "%.0f", target * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: min(max(percentage, 0), 100), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: abs(percentage - (target * 100)) > 5 ? .orange : .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(formatCurrency(value))
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }
}

struct InvestmentTransactionRow: View {
    let transaction: Transaction
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(transaction.type == .credit ? .green : .blue)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(transaction.amount))
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .credit ? .green : .blue)
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    InvestmentsView()
}