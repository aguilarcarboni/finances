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

struct IncomeSource: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let currency: String
}

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
    BudgetCategory(name: "Misc", budget: 65000),
]

let incomeSources = [
    IncomeSource(name: "Salary", amount: 400, currency: "USD"),
    IncomeSource(name: "Mesada", amount: 140000, currency: "CRC")
] 

// Exchange rate (you can update this as needed)
let usdToCrcRate: Double = 520.0

// Function to calculate total income in colones
func totalIncomeInColones() -> Double {
    return incomeSources.reduce(0) { total, income in
        if income.currency == "USD" {
            return total + (income.amount * usdToCrcRate)
        } else {
            return total + income.amount
        }
    }
}

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Finances")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Income Sources Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Income Sources")
                        .font(.title2.bold())
                    
                    ForEach(incomeSources) { income in
                        IncomeRow(income: income)
                    }
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    HStack {
                        Text("Total Income")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("₡\(Int(totalIncomeInColones()).formatted())")
                            .font(.headline.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .cornerRadius(20)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Budget")
                        .font(.title2.bold())
                    
                    ForEach(viewModel.categories) { category in
                        let totalExpenses = viewModel.expensesForCategory(category)
                        BudgetRow(
                            category: category.name,
                            currentAmount: totalExpenses,
                            maxAmount: category.budget,
                            progress: totalExpenses / category.budget
                        )
                    }
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    let totalBudget = viewModel.categories.reduce(0) { $0 + $1.budget }
                    let totalSpent = viewModel.expenses.reduce(0) { $0 + $1.amount }
                    let overallProgress = totalSpent / totalBudget
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Total Budget")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₡\(Int(totalSpent).formatted()) / ₡\(Int(totalBudget).formatted())")
                                .font(.headline.monospacedDigit())
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: overallProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: overallProgress > 1.0 ? .red : .blue))
                            .scaleEffect(x: 1, y: 3, anchor: .center)
                        
                        HStack {
                            Text("Budget Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(overallProgress * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(overallProgress > 1.0 ? .red : .secondary)
                        }
                    }
                }
                .padding()
                .cornerRadius(20)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("All Expenses")
                        .font(.title2.bold())
                    
                    ForEach(viewModel.expenses) { expense in
                        IndividualExpenseRow(expense: expense)
                    }
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    HStack {
                        Text("Total Expenses")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("₡\(Int(viewModel.expenses.reduce(0) { $0 + $1.amount }).formatted())")
                            .font(.headline.monospacedDigit())
                            .fontWeight(.semibold)
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
    let currentAmount: Double
    let maxAmount: Double
    let progress: Double
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.headline)
                Spacer()
                Text("\(currencyFormatter.string(from: NSNumber(value: currentAmount)) ?? "") / \(currencyFormatter.string(from: NSNumber(value: maxAmount)) ?? "")")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : .blue))
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
        formatter.currencySymbol = "₡"
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
        formatter.currencySymbol = "₡"
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

// New component for income sources
struct IncomeRow: View {
    let income: IncomeSource
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = income.currency == "USD" ? "$" : "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 10, height: 10)
            Text(income.name)
                .font(.subheadline)
            Spacer()
            Text(currencyFormatter.string(from: NSNumber(value: income.amount)) ?? "")
                .font(.subheadline.monospacedDigit())
            if income.currency != "CRC" {
                Text(income.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
    }
}

