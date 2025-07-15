import SwiftUI

struct InvestmentsView: View {
    @ObservedObject private var investmentsAccount = InvestmentsAccount.shared

    var body: some View {
        ContentUnavailableView {
            Label("Investments Coming Soon", systemImage: "chart.bar")
        } description: {
            Text("We're working on bringing you the best investment experience possible.")
        }
    }
}