//
//  AssetsView.swift
//  finances
//
//  Created by Andrés on 10/6/2025.
//

import SwiftUI

struct AssetsView: View {
    @State private var assets: [Asset] = [
        Asset(
            id: UUID(),
            name: "Nissan Magnite",
            type: "Car",
            purchaseDate: Date(timeIntervalSince1970: 1746142058),
            purchasePrice: 24900.00,
            downPayment: 6000.00,
            interestRate: 7.5,
            loanTermYears: 8,
            currentMarketValue: 22400.00,
            customDepreciationRate: nil,
            expenseCategory: "Debt"
        )
    ]
    
    @State private var selectedAsset: Asset?
    
    var body: some View {
        NavigationView {
            List(assets) { asset in
                AssetListRow(asset: asset)
                    .onTapGesture {
                        selectedAsset = asset
                    }
            }
            .navigationTitle("Assets")
            .sheet(item: $selectedAsset) { asset in
                AssetDetailView(asset: asset)
            }
        }
    }
}

struct AssetListRow: View {
    let asset: Asset
    
    var body: some View {
        HStack(spacing: 16) {
            // Asset Icon
            Image(systemName: asset.iconName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(asset.type)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Text("Value: $\(asset.currentValue, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if asset.remainingLoanBalance > 0 {
                        Text("Loan: $\(asset.remainingLoanBalance, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(asset.equity >= 0 ? "+" : "")$\(abs(asset.equity))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(asset.equity >= 0 ? .green : .red)
                
                Text("Equity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
