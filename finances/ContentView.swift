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

            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "person.3.sequence")
                }
            
            AssetsView()
                .tabItem {
                    Label("Assets", systemImage: "house")
                }
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
