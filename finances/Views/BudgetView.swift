import SwiftUI
import Combine

// MARK: - Models
struct BudgetCategory: Identifiable {
    let id = UUID()
    let name: String
    let budget: Double
}

struct Expense: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let amount: Double
}

// MARK: - Mock Data
let allExpenses: [Expense] = [
    Expense(name: "Car Payment", category: "Debt", amount: 90000),
    Expense(name: "Savings", category: "Savings", amount: 100000),
    Expense(name: "Gas", category: "Transportation", amount: 40000),
    Expense(name: "Seguro BAC", category: "Subscriptions", amount: 1800),
    Expense(name: "ChatGPT", category: "Subscriptions", amount: 10000),
    Expense(name: "Cursor", category: "Subscriptions", amount: 10000),
    Expense(name: "IPTV", category: "Subscriptions", amount: 9000),
    Expense(name: "Uber One", category: "Subscriptions", amount: 2999),
    Expense(name: "Admin Compass", category: "Subscriptions", amount: 2500),
    Expense(name: "Apple One", category: "Subscriptions", amount: 10000),
    
]

let budgetCategories = [
    BudgetCategory(name: "Debt", budget: 90000),
    BudgetCategory(name: "Subscriptions", budget: 50000),
    BudgetCategory(name: "Transportation", budget: 40000),
    BudgetCategory(name: "Savings", budget: 100000),
    
]

// MARK: - ViewModel
class BudgetViewModel: ObservableObject {
    @Published var expenses: [Expense] = allExpenses
    @Published var categories: [BudgetCategory] = budgetCategories

    func expensesForCategory(_ category: BudgetCategory) -> Double {
        expenses
            .filter { $0.category == category.name }
            .reduce(0) { $0 + $1.amount }
    }
}

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showExpenses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Finances")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Budget")
                        .font(.title2.bold())
                    
                    ForEach(viewModel.categories) { category in
                        let totalExpenses = viewModel.expensesForCategory(category)
                        BudgetRow(
                            category: category.name,
                            progress: totalExpenses / category.budget
                        )
                    }
                }
                .padding()
                .cornerRadius(20)
                .padding(.horizontal)
                .onTapGesture {
                    showExpenses = true
                }
                .sheet(isPresented: $showExpenses) {
                    BuegetDetailsView()
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("All Expenses")
                        .font(.title2.bold())
                    
                    ForEach(viewModel.expenses) { expense in
                        IndividualExpenseRow(expense: expense)
                    }
                }
                .padding()
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Reusable Components
struct BudgetRow: View {
    let category: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(category)
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

struct ExpenseRow: View {
    let category: String
    let amount: Double
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(category)
                .font(.headline)
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: amount)) ?? "")
                .font(.body.monospacedDigit())
        }
    }
}

struct IndividualExpenseRow: View {
    let expense: Expense
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    // macOS tag-style color mapping
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Debt": return .red
        case "Subscriptions": return .orange
        case "Transportation": return .blue
        case "Savings": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForCategory(expense.category))
                .frame(width: 10, height: 10)
            Text(expense.name)
                .font(.subheadline)
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: expense.amount)) ?? "")
                .font(.subheadline.monospacedDigit())
        }
    }
}

// MARK: - Preview
struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
    }
}

