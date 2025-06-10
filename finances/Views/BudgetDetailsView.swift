import SwiftUI

struct BuegetDetailsView: View {
    
    @StateObject private var viewModel = BudgetViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Expenses")
                    .font(.title2.bold())

                ForEach(viewModel.categories) { category in
                    let totalExpenses = viewModel.expensesForCategory(category)
                    BudgetRow(
                        category: category.name,
                        progress: totalExpenses / category.budget
                    )
                }
                
                ForEach(viewModel.categories) { category in
                    let totalExpenses = viewModel.expensesForCategory(category)
                    if totalExpenses > 0 {
                        ExpenseRow(
                            category: category.name,
                            amount: totalExpenses
                        )
                    }
                }
            }
            .padding()
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
}