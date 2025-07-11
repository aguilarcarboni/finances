import SwiftUI
import Charts

struct LoanPayoffPredictorView: View {
    @StateObject private var assetsManager = AssetsManager.shared
    @State private var selectedAsset: Asset?
    @State private var extraMonthlyPayment: Double = 0
    @State private var showingCalculations = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header Card
                HeaderCardView()
                
                // Asset Selection
                AssetSelectionSection(
                    assetsWithLoans: assetsWithLoans,
                    selectedAsset: $selectedAsset
                )
                
                // Extra Payment Input
                if let selectedAsset = selectedAsset {
                    ExtraPaymentInputSection(
                        extraMonthlyPayment: $extraMonthlyPayment,
                        showingCalculations: $showingCalculations
                    )
                    
                    // Results Section
                    if showingCalculations {
                        LoanPayoffResultsView(
                            asset: selectedAsset,
                            extraPayment: extraMonthlyPayment
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Loan Payoff Predictor")        }
    }
    
    private var assetsWithLoans: [Asset] {
        assetsManager.assets.filter { $0.hasActiveLoan }
    }
}

// MARK: - Header Card
struct HeaderCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Loan Payoff Predictor")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Calculate how much interest you can save and how much faster you can pay off your loans by making extra monthly payments.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Asset Selection Section
struct AssetSelectionSection: View {
    let assetsWithLoans: [Asset]
    @Binding var selectedAsset: Asset?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select an Asset with a Loan")
                .font(.headline)
            
            if assetsWithLoans.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("No active loans found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(assetsWithLoans, id: \.id) { asset in
                            AssetLoanCard(
                                asset: asset,
                                isSelected: selectedAsset?.id == asset.id
                            )
                            .onTapGesture {
                                selectedAsset = asset
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Asset Loan Card
struct AssetLoanCard: View {
    let asset: Asset
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(asset.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Balance:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.remainingLoanBalance.formatted(.currency(code: "CRC")))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Payment:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.monthlyPayment.formatted(.currency(code: "CRC")))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Rate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(asset.interestRate.formatted(.percent.precision(.fractionLength(1))))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(width: 180)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.white))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color(.white), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Extra Payment Input Section
struct ExtraPaymentInputSection: View {
    @Binding var extraMonthlyPayment: Double
    @Binding var showingCalculations: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Monthly Payment")
                .font(.headline)
            
            HStack {
                Text("₡")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $extraMonthlyPayment, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: extraMonthlyPayment) { _ in
                        showingCalculations = extraMonthlyPayment > 0
                    }
            }
            
            // Quick amount buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach([25000, 50000, 100000, 200000], id: \.self) { amount in
                    Button {
                        extraMonthlyPayment = Double(amount)
                        showingCalculations = true
                    } label: {
                        Text("₡\(amount.formatted())")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .cornerRadius(12)
    }
}

// MARK: - Loan Payoff Results View
struct LoanPayoffResultsView: View {
    let asset: Asset
    let extraPayment: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary Cards
            HStack(spacing: 12) {
                ResultCard(
                    title: "Interest Saved",
                    value: interestSaved.formatted(.currency(code: "CRC")),
                    subtitle: "Total savings",
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                ResultCard(
                    title: "Time Saved",
                    value: "\(monthsSaved)",
                    subtitle: "months earlier",
                    color: .blue,
                    icon: "clock.fill"
                )
            }
            
            // Detailed Comparison
            ComparisonTableView(
                originalPayment: asset.monthlyPayment,
                newPayment: asset.monthlyPayment + extraPayment,
                originalMonths: originalMonthsRemaining,
                newMonths: newMonthsRemaining,
                originalTotalInterest: originalTotalInterest,
                newTotalInterest: newTotalInterest
            )
        }
        .padding()
        .cornerRadius(12)
    }
    
    // MARK: - Calculated Properties
    
    private var originalMonthsRemaining: Int {
        guard let loan = asset.loan else { return 0 }
        let totalMonths = loan.termYears * 12
        return max(0, totalMonths - asset.monthsOwned)
    }
    
    private var newMonthsRemaining: Int {
        guard extraPayment > 0, asset.remainingLoanBalance > 0, asset.interestRate > 0 else { return originalMonthsRemaining }
        
        let balance = asset.remainingLoanBalance
        let monthlyRate = asset.interestRate / 100 / 12
        let totalPayment = asset.monthlyPayment + extraPayment
        
        // Calculate months to pay off with extra payment
        let months = -log(1 - (balance * monthlyRate) / totalPayment) / log(1 + monthlyRate)
        
        return max(1, Int(ceil(months)))
    }
    
    private var monthsSaved: Int {
        originalMonthsRemaining - newMonthsRemaining
    }
    
    private var originalTotalInterest: Double {
        (asset.monthlyPayment * Double(originalMonthsRemaining)) - asset.remainingLoanBalance
    }
    
    private var newTotalInterest: Double {
        ((asset.monthlyPayment + extraPayment) * Double(newMonthsRemaining)) - asset.remainingLoanBalance
    }
    
    private var interestSaved: Double {
        originalTotalInterest - newTotalInterest
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Comparison Table
struct ComparisonTableView: View {
    let originalPayment: Double
    let newPayment: Double
    let originalMonths: Int
    let newMonths: Int
    let originalTotalInterest: Double
    let newTotalInterest: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Comparison")
                .font(.headline)
            
            VStack(spacing: 8) {
                ComparisonRow(
                    label: "Monthly Payment",
                    original: originalPayment.formatted(.currency(code: "CRC")),
                    new: newPayment.formatted(.currency(code: "CRC"))
                )
                
                ComparisonRow(
                    label: "Months Remaining",
                    original: "\(originalMonths)",
                    new: "\(newMonths)"
                )
                
                ComparisonRow(
                    label: "Total Interest",
                    original: originalTotalInterest.formatted(.currency(code: "CRC")),
                    new: newTotalInterest.formatted(.currency(code: "CRC"))
                )
            }
        }
        .padding()
        .cornerRadius(8)
    }
}

struct ComparisonRow: View {
    let label: String
    let original: String
    let new: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Current")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(original)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 80)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("With Extra")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(new)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .frame(minWidth: 80)
        }
    }
}

#Preview {
    LoanPayoffPredictorView()
} 
