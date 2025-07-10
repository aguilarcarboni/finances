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

            ExpensesAccountView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign")
                }
            
            SavingsView()
                .tabItem {
                    Label("Savings", systemImage: "dollarsign.bank.building")
                }

            AssetsView()
                .tabItem {
                    Label("Assets", systemImage: "house")
                }
            
            InvestmentsView()
                .tabItem {
                    Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            WealthMapView()
                .tabItem {
                    Label("Wealth Map", systemImage: "point.3.connected.trianglepath.dotted")
                }
        }
    }
}

#Preview {
    ContentView()
}
