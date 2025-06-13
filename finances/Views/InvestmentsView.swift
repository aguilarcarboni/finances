import SwiftUI

struct InvestmentsView: View {
    @StateObject private var viewModel = InvestmentsViewModel()
    
    private func formatValue(_ value: String, currency: String) -> String {
        if let doubleValue = Double(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(currency) \(value)"
        }
        return value
    }
    
    private func findItem(by tag: String) -> AccountSummaryItem? {
        viewModel.items.first { $0.tag.lowercased() == tag.lowercased() }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Portfolio Summary Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Investment Portfolio")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if let netLiquidation = findItem(by: "NetLiquidation") {
                                Text(formatValue(netLiquidation.value, currency: netLiquidation.currency))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Account Balance Summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let netLiquidation = findItem(by: "NetLiquidation") {
                                    Text(formatValue(netLiquidation.value, currency: netLiquidation.currency))
                                        .font(.title2.monospacedDigit())
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                if let buyingPower = findItem(by: "BuyingPower") {
                                    Text("Available: \(formatValue(buyingPower.value, currency: buyingPower.currency))")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.blue)
                                }
                                if let unrealizedPnL = findItem(by: "UnrealizedPnL") {
                                    let isPositive = Double(unrealizedPnL.value) ?? 0 >= 0
                                    Text("P&L: \(formatValue(unrealizedPnL.value, currency: unrealizedPnL.currency))")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(isPositive ? .green : .red)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Asset Allocation Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Asset Allocation")
                            .font(.title2.bold())
                        
                        if let stockValue = findItem(by: "StockMarketValue"),
                           let netLiquidation = findItem(by: "NetLiquidation"),
                           let stockAmount = Double(stockValue.value),
                           let totalAmount = Double(netLiquidation.value) {
                            
                            let stockPercentage = totalAmount > 0 ? (stockAmount / totalAmount) * 100 : 0
                            let cashPercentage = 100 - stockPercentage
                            
                            VStack(spacing: 16) {
                                // Stock Allocation
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Stocks")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(Int(stockPercentage))%")
                                            .font(.headline.monospacedDigit())
                                            .foregroundColor(.blue)
                                    }
                                    
                                    ProgressView(value: stockPercentage, total: 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                    
                                    Text(formatValue(stockValue.value, currency: stockValue.currency))
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundColor(.secondary)
                                }
                                
                                // Cash Allocation
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Cash")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(Int(cashPercentage))%")
                                            .font(.headline.monospacedDigit())
                                            .foregroundColor(.green)
                                    }
                                    
                                    ProgressView(value: cashPercentage, total: 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                    
                                    if let buyingPower = findItem(by: "BuyingPower") {
                                        Text(formatValue(buyingPower.value, currency: buyingPower.currency))
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Performance Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Performance")
                            .font(.title2.bold())
                        
                        if let unrealizedPnL = findItem(by: "UnrealizedPnL"),
                           let netLiquidation = findItem(by: "NetLiquidation") {
                            
                            let pnlValue = Double(unrealizedPnL.value) ?? 0
                            let totalValue = Double(netLiquidation.value) ?? 0
                            let pnlPercentage = totalValue > 0 ? (pnlValue / totalValue) * 100 : 0
                            
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Unrealized P&L")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(formatValue(unrealizedPnL.value, currency: unrealizedPnL.currency))
                                            .font(.title3.monospacedDigit())
                                            .fontWeight(.bold)
                                            .foregroundColor(pnlValue >= 0 ? .green : .red)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Return")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(String(format: "%.1f", pnlPercentage))%")
                                            .font(.title3.monospacedDigit())
                                            .fontWeight(.bold)
                                            .foregroundColor(pnlValue >= 0 ? .green : .red)
                                    }
                                }
                                
                                Divider()
                                
                                if let stockValue = findItem(by: "StockMarketValue") {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Stock Value")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(formatValue(stockValue.value, currency: stockValue.currency))
                                                .font(.subheadline.monospacedDigit())
                                                .fontWeight(.medium)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Cash Value")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let buyingPower = findItem(by: "BuyingPower") {
                                                Text(formatValue(buyingPower.value, currency: buyingPower.currency))
                                                    .font(.subheadline.monospacedDigit())
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Investments")
            .task {
                await viewModel.fetchAccountSummary()
            }
        }
    }
}

#Preview {
    InvestmentsView()
}