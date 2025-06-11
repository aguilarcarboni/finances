import SwiftUI
import Combine

class ExpensesAccountViewModel: ObservableObject {
    @Published var expensesAccount = ExpensesAccount.shared
    
    func debitsForCategory(_ category: BudgetCategory) -> Double {
        expensesAccount.debitsForCategory(category.name)
    }
}

struct ExpensesAccountView: View {
    @StateObject private var viewModel = ExpensesAccountViewModel()
    private var account: ExpensesAccount { viewModel.expensesAccount }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // Current Period Header
                    if let currentPeriod = account.currentPeriod {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Expenses Account")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(currentPeriod.dateRange)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            // Account Balance Summary
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Account Balance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("₡\(Int(account.netBalance).formatted())")
                                        .font(.title2.monospacedDigit())
                                        .fontWeight(.bold)
                                        .foregroundColor(account.netBalance >= 0 ? .green : .red)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total In: ₡\(Int(account.totalCredits).formatted())")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.green)
                                    Text("Total Out: ₡\(Int(account.totalDebits).formatted())")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Budget vs Actual Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Budget vs Actual")
                            .font(.title2.bold())
                        
                        ForEach(account.budget) { category in
                            let actualSpent = viewModel.debitsForCategory(category)
                            BudgetRow(
                                category: category.name,
                                currentAmount: actualSpent,
                                maxAmount: category.budget,
                                progress: actualSpent / category.budget
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        let totalBudget = account.totalBudget
                        let totalSpent = account.totalDebits
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
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // All Debits (Expenses) Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Expenses")
                            .font(.title2.bold())
                        
                        ForEach(account.debits.sorted { $0.date > $1.date }) { transaction in
                            TransactionRow(transaction: transaction, isDebit: true)
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        HStack {
                            Text("Total Debits")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₡\(Int(account.totalDebits).formatted())")
                                .font(.headline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // All Credits (Income) Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Credits (Income)")
                            .font(.title2.bold())
                        
                        ForEach(account.credits.sorted { $0.date > $1.date }) { transaction in
                            TransactionRow(transaction: transaction, isDebit: false)
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        HStack {
                            Text("Total Credits")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₡\(Int(account.totalCredits).formatted())")
                                .font(.headline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Expenses")
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

struct TransactionRow: View {
    let transaction: Transaction
    let isDebit: Bool
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    // Color mapping for categories
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Debt": return .red
        case "Subscriptions": return .orange
        case "Transportation": return .blue
        case "Savings": return .green
        case "Income": return .green
        case "Investment": return .purple
        case "Rewards": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForCategory(transaction.category))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.category)
                    .font(.caption)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundColor(isDebit ? .red : .green)
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview
struct ExpensesAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesAccountView()
    }
}

