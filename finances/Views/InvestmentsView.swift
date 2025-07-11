import SwiftUI

struct InvestmentsView: View {
    @ObservedObject private var investmentsAccount = InvestmentsAccount.shared
    @ObservedObject private var apiManager = IBKRAPIManager.shared
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if apiManager.isConnected {
                    // Show comprehensive trading dashboard when connected
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // SECTION 1: Account Overview (/summary)
                            AccountOverviewSection()
                            
                            // SECTION 2: Portfolio & Positions (/portfolio or /positions + /latest-price)
                            PortfolioPositionsSection()
                            
                            // SECTION 3: PnL Tracking (/pnl + /pnl-single)
                            PnLTrackingSection()
                            
                            // SECTION 4: Orders (/open-orders) - Read Only
                            OrdersSection()
                            
                            // SECTION 5: Trades/Fills (/exec-details) - Read Only
                            TradesSection()
                            
                            // SECTION 6: Market Data (/latest-price)
                            MarketDataSection()
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Show connection prompt when offline
                    ContentUnavailableView {
                        Label("Trading Dashboard Offline", systemImage: "wifi.slash")
                    } description: {
                        Text("Connect to IBKR to access your trading dashboard with real-time portfolio data, orders, and positions.")
                    } actions: {
                        Button("Connect to IBKR") {
                            Task {
                                do {
                                    try await investmentsAccount.connectToIBKR()
                                } catch {
                                    print("Error!")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItemGroup() {
                    if apiManager.isConnected {
                        Button(action: {
                            apiManager.disconnect()
                        }) {
                            Image(systemName: "wifi.slash")
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await investmentsAccount.syncWithIBKR()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 24, height: 24)
                    }
                    .disabled(!apiManager.isConnected)
                }
            }
        }
        .task {
            // Auto-refresh data when view appears if connected
            if apiManager.isConnected {
                await investmentsAccount.syncWithIBKR()
            }
        }
    }
    
    // MARK: - SECTION 1: Account Overview (/summary)
    @ViewBuilder
    private func AccountOverviewSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Account Health")
                    .font(.headline)
                Spacer()
                Image(systemName: "heart.text.square")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            // Key Account Metrics from /summary endpoint
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                AccountMetricCard(
                    title: "Net Liquidation",
                    value: investmentsAccount.portfolioValue,
                    subtitle: "Total Account Value",
                    systemImage: "dollarsign.circle"
                )
                
                AccountMetricCard(
                    title: "Available Funds",
                    value: investmentsAccount.availableFunds,
                    subtitle: "Cash Available",
                    systemImage: "banknote"
                )
                
                AccountMetricCard(
                    title: "Buying Power", 
                    value: investmentsAccount.buyingPower,
                    subtitle: "Max Purchase Power",
                    systemImage: "bolt.circle"
                )
                
                AccountMetricCard(
                    title: "Total Cash",
                    value: investmentsAccount.totalCashValue,
                    subtitle: "All Currencies",
                    systemImage: "wallet.pass"
                )
            }
            
            // Margin utilization indicator
            if investmentsAccount.buyingPower > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Margin Utilization")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(investmentsAccount.marginUtilization.formatted(.percent.precision(.fractionLength(1))))")
                            .font(.caption.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundColor(marginColor(investmentsAccount.marginUtilization))
                    }
                    
                    ProgressView(value: min(investmentsAccount.marginUtilization / 100.0, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: marginColor(investmentsAccount.marginUtilization)))
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - SECTION 2: Portfolio & Positions (/portfolio or /positions + /latest-price)
    @ViewBuilder
    private func PortfolioPositionsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portfolio & Positions")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(investmentsAccount.positions.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if investmentsAccount.positions.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Positions",
                    subtitle: "Your portfolio positions will appear here"
                )
            } else {
                VStack(spacing: 8) {
                    // Table Header
                    HStack {
                        Text("Symbol")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Qty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Text("Market Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .trailing)
                        Text("P&L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    
                    Divider()
                    
                    // Position Rows (show top 5, with expand option)
                    ForEach(investmentsAccount.positions.prefix(5)) { position in
                        PositionRow(position: position)
                    }
                    
                    if investmentsAccount.positions.count > 5 {
                        Button("View All \(investmentsAccount.positions.count) Positions") {
                            // TODO: Navigate to detailed positions view
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - SECTION 3: PnL Tracking (/pnl + /pnl-single)
    @ViewBuilder
    private func PnLTrackingSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("P&L Tracking")
                    .font(.headline)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(investmentsAccount.totalPnL >= 0 ? .green : .red)
            }
            
            // Main P&L metrics grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                PnLCard(
                    title: "Total P&L",
                    value: investmentsAccount.totalPnL,
                    percentage: investmentsAccount.totalPnLPercentage,
                    isPrimary: true
                )
                
                PnLCard(
                    title: "Daily P&L",
                    value: investmentsAccount.offlineAwareDayChange,
                    percentage: investmentsAccount.offlineAwareDayChangePercentage,
                    isPrimary: false
                )
                
                PnLCard(
                    title: "Unrealized P&L",
                    value: investmentsAccount.unrealizedGains,
                    percentage: nil,
                    isPrimary: false
                )
                
                PnLCard(
                    title: "Realized P&L",
                    value: investmentsAccount.realizedGains,
                    percentage: nil,
                    isPrimary: false
                )
            }
            
            // Win/Loss Analytics
            if investmentsAccount.positions.count > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Winners: \(investmentsAccount.winnersCount)")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(formatCurrency(investmentsAccount.winnersValue))
                            .font(.caption.monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Win/Loss Ratio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(investmentsAccount.winLossRatio.formatted(.number.precision(.fractionLength(2))))")
                            .font(.caption.monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundColor(investmentsAccount.winLossRatio > 1 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Losers: \(investmentsAccount.losersCount)")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(formatCurrency(investmentsAccount.losersValue))
                            .font(.caption.monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - SECTION 4: Orders (/open-orders) - Read Only
    @ViewBuilder
    private func OrdersSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Open Orders")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(investmentsAccount.openOrders.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "list.bullet.clipboard")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            
            if investmentsAccount.openOrders.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.clipboard",
                    title: "No Open Orders",
                    subtitle: "Your active orders will appear here"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(investmentsAccount.openOrders.prefix(3).enumerated()), id: \.offset) { index, order in
                        OrderRow(order: order, showActions: false) // Read-only
                    }
                    
                    if investmentsAccount.openOrders.count > 3 {
                        Button("View All \(investmentsAccount.openOrders.count) Orders") {
                            // TODO: Navigate to detailed orders view
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - SECTION 5: Trades/Fills (/exec-details) - Read Only
    @ViewBuilder
    private func TradesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Trades")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(investmentsAccount.completedOrders.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            if investmentsAccount.completedOrders.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Recent Trades",
                    subtitle: "Your executed trades will appear here"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(investmentsAccount.completedOrders.prefix(3).enumerated()), id: \.offset) { index, order in
                        TradeRow(order: order)
                    }
                    
                    if investmentsAccount.completedOrders.count > 3 {
                        Button("View All \(investmentsAccount.completedOrders.count) Trades") {
                            // TODO: Navigate to detailed trades view
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - SECTION 6: Market Data (/latest-price)
    @ViewBuilder
    private func MarketDataSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Watchlist Prices")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(investmentsAccount.watchlist.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "quote.bubble")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
            
            if investmentsAccount.watchlist.isEmpty {
                EmptyStateView(
                    icon: "quote.bubble",
                    title: "No Watchlist Items",
                    subtitle: "Add symbols to track their prices"
                )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(investmentsAccount.watchlist) { item in
                        WatchlistItemCard(item: item)
                    }
                }
                
                // Refresh button for watchlist
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await investmentsAccount.updateWatchlistPrices()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Refresh Prices")
                                .font(.caption)
                        }
                    }
                    .disabled(!apiManager.isConnected)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    private func marginColor(_ utilization: Double) -> Color {
        if utilization < 50 {
            return .green
        } else if utilization < 80 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Views

struct AccountMetricCard: View {
    let title: String
    let value: Double
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(formatCurrency(value))
                .font(.title3.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

struct PnLCard: View {
    let title: String
    let value: Double
    let percentage: Double?
    let isPrimary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatCurrency(value))
                .font(isPrimary ? .title2.monospacedDigit() : .subheadline.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(value >= 0 ? .green : .red)
            
            if let percentage = percentage {
                HStack(spacing: 4) {
                    Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(percentage.formatted(.percent.precision(.fractionLength(2))))")
                        .font(.caption2.monospacedDigit())
                }
                .foregroundColor(value >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

struct PositionRow: View {
    let position: InvestmentPosition
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(position.secType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(position.position.formatted(.number.precision(.fractionLength(0))))")
                .font(.caption.monospacedDigit())
                .frame(width: 60, alignment: .trailing)
            
            Text(formatCurrency(position.marketValue))
                .font(.caption.monospacedDigit())
                .frame(width: 90, alignment: .trailing)
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(formatCurrency(position.unrealizedPnL))
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(position.unrealizedPnL >= 0 ? .green : .red)
                Text("\(position.pnLPercentage.formatted(.percent.precision(.fractionLength(1))))")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(position.pnLPercentage >= 0 ? .green : .red)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

struct OrderRow: View {
    let order: IBKROrder
    let showActions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.contract.symbol)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(order.contract.secType) • \(order.orderStatus.status)")
                        .font(.caption2)
                        .foregroundColor(statusColor(order.orderStatus.status))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Qty: \(order.safeRemaining.formatted(.number.precision(.fractionLength(0))))")
                        .font(.caption)
                        .fontWeight(.medium)
                    if order.orderStatus.safeAvgFillPrice > 0 {
                        Text("@ \(formatCurrency(order.orderStatus.safeAvgFillPrice))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Order ID for reference (read-only)
            HStack {
                Spacer()
                Text("Order #\(order.orderStatus.orderId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .cornerRadius(8)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "filled": return .green
        case "submitted", "presubmitted": return .blue
        case "cancelled": return .red
        default: return .orange
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value.formatted(.number.precision(.fractionLength(2))))"
    }
}

struct TradeRow: View {
    let order: IBKROrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(order.contract.symbol)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Filled • \(order.contract.secType)")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Qty: \(order.safefilled.formatted(.number.precision(.fractionLength(0))))")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("@ \(formatCurrency(order.orderStatus.safeAvgFillPrice))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value.formatted(.number.precision(.fractionLength(2))))"
    }
}

struct WatchlistItemCard: View {
    let item: WatchlistItem
    
    var body: some View {
        Button(action: {
            print("Checking stocks...")
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    if item.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if let error = item.error {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if let lastUpdated = item.lastUpdated {
                        Text(timeAgo(from: lastUpdated))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if item.isLoading {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let error = item.error {
                    Text("Error")
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else {
                    Text(formatCurrency(item.currentPrice))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding()

            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value.formatted(.number.precision(.fractionLength(2))))"
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
