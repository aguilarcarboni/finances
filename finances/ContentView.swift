import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExpensesAccountView()
                .tabItem { Label("Expenses", systemImage: "checklist") }
            SavingsView()
                .tabItem { Label("Savings", systemImage: "dollarsign.bank.building") }
            AssetsView()
                .tabItem { Label("Assets", systemImage: "house") }
        }
    }
}

#Preview { ContentView() }
