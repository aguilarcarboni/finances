import Foundation

// MARK: - Loan lifecycle status
enum LoanStatus: String, CaseIterable, Hashable {
    case noLoan = "No Loan"
    case activeLoan = "Active Loan"
    case paidOff = "Paid Off"
}
/// Encapsulates all the data and logic for a loan that belongs to an `Asset`.
///
/// Moving the loan‐related calculations into its own type keeps the `Asset` model
/// focussed on asset-specific behaviour and improves the overall object-oriented
/// structure of the codebase.
struct Loan: Identifiable, Hashable {
    // MARK: – Basic stored properties
    let id: UUID
    var originalAmount: Double
    var interestRate: Double      // Annual nominal rate expressed in percent (e.g. 7.5)
    var termYears: Int           // Total length of the loan in years
    var startDate: Date          // When the loan started – usually the asset acquisition date
    var downPayment: Double      // Initial down-payment made when the loan was taken
    private(set) var status: LoanStatus
    private(set) var paidOffDate: Date?

    // MARK: – Initialisation
    init(id: UUID = UUID(),
                originalAmount: Double,
                interestRate: Double,
                termYears: Int,
                startDate: Date,
                downPayment: Double = 0,
                status: LoanStatus = .activeLoan,
                paidOffDate: Date? = nil) {
        self.id = id
        self.originalAmount = originalAmount
        self.interestRate = interestRate
        self.termYears = termYears
        self.startDate = startDate
        self.downPayment = downPayment
        self.status = status
        self.paidOffDate = paidOffDate
    }

    // MARK: – Lifecycle helpers
    mutating func markAsPaidOff(on date: Date = Date()) {
        status = .paidOff
        paidOffDate = date
    }

    // MARK: – Derived time information
    /// Number of months that have elapsed since the loan start date.
    private var monthsSinceStart: Int {
        let interval = Date().timeIntervalSince(startDate)
        return max(0, Int(interval / (30.44 * 24 * 60 * 60)))
    }

    private var totalNumberOfPayments: Int { termYears * 12 }

    // MARK: – Financial calculations
    /// Standard amortised monthly payment for the loan.
    var monthlyPayment: Double {
        guard status == .activeLoan, originalAmount > 0, interestRate > 0 else { return 0 }
        let monthlyRate = interestRate / 100 / 12
        let n = Double(totalNumberOfPayments)
        let numerator = originalAmount * monthlyRate * pow(1 + monthlyRate, n)
        let denominator = pow(1 + monthlyRate, n) - 1
        return numerator / denominator
    }

    /// Remaining principal balance on the loan right now.
    var remainingBalance: Double {
        guard status == .activeLoan else { return 0 }
        let monthlyRate = interestRate / 100 / 12
        let mPaid = Double(min(monthsSinceStart, totalNumberOfPayments))
        // If interestRate == 0 we avoid division by zero and just do straight-line.
        if interestRate == 0 {
            let principalPaid = (originalAmount / Double(totalNumberOfPayments)) * mPaid
            return max(0, originalAmount - principalPaid)
        }

        let remainingPayments = Double(totalNumberOfPayments) - mPaid
        let numerator = monthlyPayment * (pow(1 + monthlyRate, remainingPayments) - 1)
        let denominator = monthlyRate * pow(1 + monthlyRate, remainingPayments)
        return numerator / denominator
    }

    /// Total interest paid so far.
    var interestPaidToDate: Double {
        let paymentsMade = Double(min(monthsSinceStart, totalNumberOfPayments))
        let totalPaid = monthlyPayment * paymentsMade
        let principalPaid = originalAmount - remainingBalance
        return max(0, totalPaid - principalPaid)
    }

    /// Remaining interest that will be paid if the loan runs to term.
    var remainingInterest: Double {
        let remainingPayments = Double(max(0, totalNumberOfPayments - monthsSinceStart))
        let totalRemainingPayments = monthlyPayment * remainingPayments
        return max(0, totalRemainingPayments - remainingBalance)
    }

    /// Total interest over the full life of the loan (paid + remaining).
    var totalInterest: Double { interestPaidToDate + remainingInterest }
} 
