//
//  ContentView.swift
//  finances
//
//  Created by Andrés on 9/6/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    var body: some View {
        TabView {
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign")
                }
            
            NavigationView {
                ContentUnavailableView(
                    "Coming soon...",
                    systemImage: "dollarsign.bank.building",
                    description: Text("Savings is not implemented yet")
                )
            }
            .tabItem {
                Label("Savings", systemImage: "dollarsign.bank.building")
            }

            NavigationView {
                AssetsView()
            }
            .tabItem {
                Label("Assets", systemImage: "house")
            }

            NavigationView {
                ContentUnavailableView(
                    "Coming soon...",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Investments is not implemented yet")
                )
            }
            .tabItem {
                Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}

#Preview {
    ContentView()
}
