import SwiftUI

struct AccountsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ExpensesAccountView()) {
                    Label("Expenses Account", systemImage: "dollarsign")
                }
                NavigationLink(destination: SavingsView()) {
                    Label("Savings Account", systemImage: "dollarsign.bank.building")
                }
                NavigationLink(destination: WiseAccountView()) {
                    Label("Wise Account", systemImage: "arrow.2.circlepath")
                }
                NavigationLink(destination: InvestmentsView()) {
                    Label("Investments Account", systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            .navigationTitle("Accounts")
        }
    }
}

#Preview {
    AccountsView()
} 