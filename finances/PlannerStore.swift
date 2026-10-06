import Foundation
import Combine

enum PlannerCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case crc = "CRC"
    var id: String { rawValue }
}

enum PlannerPayPeriod: String, CaseIterable, Identifiable {
    case first = "First half"
    case second = "Second half"
    var id: String { rawValue }
}

enum PlannerExpenseStatus: String {
    case unpaid = "Not paid"
    case partial = "Partial"
    case paid = "Paid"
}

struct PlannedExpense: Identifiable, Hashable {
    let id: UUID
    var period: PlannerPayPeriod
    var category: String
    var name: String
    var plannedAmount: Double
    var paidAmount: Double = 0
    init(id: UUID = UUID(), period: PlannerPayPeriod, category: String, name: String, plannedAmount: Double, paidAmount: Double = 0) {
        self.id = id; self.period = period; self.category = category; self.name = name; self.plannedAmount = plannedAmount; self.paidAmount = paidAmount
    }
    var remainingAmount: Double { max(plannedAmount - paidAmount, 0) }
    var status: PlannerExpenseStatus { paidAmount <= 0 ? .unpaid : (paidAmount < plannedAmount ? .partial : .paid) }
}

struct RollingExpensePlan: Identifiable, Hashable {
    let id: UUID
    var category: String
    var name: String
    var contributionPerPeriod: Double
    var savedAmount: Double = 0
    var targetAmount: Double
    var dueDate: Date
    var recurrence: String
    var fundedPeriods: Set<String> = []
    init(id: UUID = UUID(), category: String, name: String, contributionPerPeriod: Double, savedAmount: Double = 0, targetAmount: Double, dueDate: Date, recurrence: String, fundedPeriods: Set<String> = []) {
        self.id = id; self.category = category; self.name = name; self.contributionPerPeriod = contributionPerPeriod; self.savedAmount = savedAmount; self.targetAmount = targetAmount; self.dueDate = dueDate; self.recurrence = recurrence; self.fundedPeriods = fundedPeriods
    }
    var remainingAmount: Double { max(targetAmount - savedAmount, 0) }
}

private extension Date {
    static func plannerDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}

final class PlannerStore: ObservableObject {
    static let shared = PlannerStore()
    @Published var firstHalfSalary = 700.0
    @Published var secondHalfSalary = 700.0
    @Published var selectedPeriod: PlannerPayPeriod = Calendar.current.component(.day, from: Date()) <= 15 ? .first : .second
    @Published var currency: PlannerCurrency = .usd
    @Published var usdToCrcRate = 500.0
    @Published var rollingExpenses = PlannerStore.sampleRolling
    @Published var plannedExpenses = PlannerStore.sampleExpenses
    static let sampleRolling: [RollingExpensePlan] = [
        RollingExpensePlan(category: "Health and Fitness", name: "Cut Hair", contributionPerPeriod: 6, targetAmount: 24, dueDate: .plannerDate(2026, 11, 15), recurrence: "Every 2 months"),
        RollingExpensePlan(category: "Health and Fitness", name: "Limpieza Dental", contributionPerPeriod: 4, targetAmount: 40, dueDate: .plannerDate(2027, 2, 15), recurrence: "Every 6 months"),
        RollingExpensePlan(category: "Health and Fitness", name: "Health Exams", contributionPerPeriod: 6, targetAmount: 72, dueDate: .plannerDate(2026, 9, 15), recurrence: "Every 6 months"),
        RollingExpensePlan(category: "Health and Fitness", name: "Eye Exam", contributionPerPeriod: 2.5, targetAmount: 30, dueDate: .plannerDate(2026, 9, 15), recurrence: "Every 6 months"),
        RollingExpensePlan(category: "Car Maintenance", name: "Marchamo", contributionPerPeriod: 75, targetAmount: 500, dueDate: .plannerDate(2026, 12, 1), recurrence: "Yearly"),
        RollingExpensePlan(category: "Car Maintenance", name: "Car Service", contributionPerPeriod: 23.33, targetAmount: 280, dueDate: .plannerDate(2027, 9, 1), recurrence: "Every 6 months"),
        RollingExpensePlan(category: "Car Maintenance", name: "Wash Car", contributionPerPeriod: 7.5, targetAmount: 30, dueDate: .plannerDate(2026, 10, 15), recurrence: "Every 2 months")
    ]

    static let sampleExpenses: [PlannedExpense] = [
        PlannedExpense(period: .first, category: "Transportation", name: "Gas", plannedAmount: 70),
        PlannedExpense(period: .first, category: "Health and Fitness", name: "Climbing", plannedAmount: 40),
        PlannedExpense(period: .first, category: "Health and Fitness", name: "Fisioterapia", plannedAmount: 30),
        PlannedExpense(period: .first, category: "Car Maintenance", name: "Car Debt", plannedAmount: 150),
        PlannedExpense(period: .first, category: "Subscriptions", name: "Seguro BAC", plannedAmount: 3),
        PlannedExpense(period: .first, category: "Subscriptions", name: "EA Play (PS)", plannedAmount: 5.99),
        PlannedExpense(period: .first, category: "Subscriptions", name: "RacingLine", plannedAmount: 1.99),
        PlannedExpense(period: .first, category: "Subscriptions", name: "PS+", plannedAmount: 10.99),
        PlannedExpense(period: .first, category: "Subscriptions", name: "iRacing", plannedAmount: 14.75),
        PlannedExpense(period: .first, category: "Subscriptions", name: "ChatGPT", plannedAmount: 20),
        PlannedExpense(period: .first, category: "Subscriptions", name: "Admin Compass", plannedAmount: 5),
        PlannedExpense(period: .second, category: "Transportation", name: "Gas", plannedAmount: 70),
        PlannedExpense(period: .second, category: "Health and Fitness", name: "Climbing", plannedAmount: 40),
        PlannedExpense(period: .second, category: "Health and Fitness", name: "SmartFit", plannedAmount: 40),
        PlannedExpense(period: .second, category: "Car Maintenance", name: "Car Debt", plannedAmount: 150),
        PlannedExpense(period: .second, category: "Subscriptions", name: "IPTV", plannedAmount: 20),
        PlannedExpense(period: .second, category: "Subscriptions", name: "Apple One", plannedAmount: 27)
    ]

    var activeSalary: Double { selectedPeriod == .first ? firstHalfSalary : secondHalfSalary }
    var activeExpenses: [PlannedExpense] { plannedExpenses.filter { $0.period == selectedPeriod } }
    var activePlanned: Double { activeExpenses.reduce(0) { $0 + $1.plannedAmount } }
    var activePaid: Double { activeExpenses.reduce(0) { $0 + $1.paidAmount } }
    var activeRemaining: Double { activeExpenses.reduce(0) { $0 + $1.remainingAmount } }
    var rollingContributionPerPeriod: Double { rollingExpenses.reduce(0) { $0 + $1.contributionPerPeriod } }
    var activeRollingContributions: Double { rollingExpenses.reduce(0) { $0 + (isFunded($1) ? $1.contributionPerPeriod : 0) } }
    var activeMinimumNeeded: Double { activeRemaining + max(0, rollingContributionPerPeriod - activeRollingContributions) }
    var activeLeftoverAfterActuals: Double { activeSalary - activePaid - activeRollingContributions }
    var activeLeftoverAfterPlanned: Double { activeSalary - activePlanned - rollingContributionPerPeriod }
    var rollingSavedTotal: Double { rollingExpenses.reduce(0) { $0 + $1.savedAmount } }
    var dueThisMonth: Double { rollingExpenses.filter { Calendar.current.isDate($0.dueDate, equalTo: Date(), toGranularity: .month) }.reduce(0) { $0 + $1.remainingAmount } }
    var rollingServiceTotals: [(String, Double)] { rollingExpenses.map { ($0.name, $0.savedAmount) }.sorted { $0.0 < $1.0 } }
    var currencyLabel: String { currency.rawValue }

    func money(_ amount: Double) -> String {
        switch currency {
        case .usd: return amount.formatted(.currency(code: "USD").precision(.fractionLength(2)))
        case .crc: return (amount * usdToCrcRate).formatted(.currency(code: "CRC").precision(.fractionLength(0)))
        }
    }
    func inputText(_ amount: Double) -> String { currency == .crc ? String(format: "%.0f", amount * usdToCrcRate) : String(format: "%.2f", amount) }
    func amountFromDisplay(_ text: String) -> Double {
        let value = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
        return currency == .crc ? value / usdToCrcRate : value
    }
    private var monthPrefix: String {
        let c = Calendar.current.dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d-", c.year ?? 0, c.month ?? 0)
    }
    private func periodKey(_ period: PlannerPayPeriod) -> String { monthPrefix + period.rawValue }
    func isFunded(_ item: RollingExpensePlan) -> Bool { item.fundedPeriods.contains(periodKey(selectedPeriod)) }
    func addContribution(to item: RollingExpensePlan) {
        guard !isFunded(item) else { return }
        var updated = item; updated.savedAmount += item.contributionPerPeriod; updated.fundedPeriods.insert(periodKey(selectedPeriod)); update(updated)
    }
    func markRollingPaid(_ item: RollingExpensePlan) {
        var updated = item; updated.savedAmount = 0; updated.fundedPeriods = [periodKey(selectedPeriod)]; update(updated)
    }
    func update(_ item: PlannedExpense) { if let index = plannedExpenses.firstIndex(where: { $0.id == item.id }) { plannedExpenses[index] = item } }
    func update(_ item: RollingExpensePlan) { if let index = rollingExpenses.firstIndex(where: { $0.id == item.id }) { rollingExpenses[index] = item } }
}
