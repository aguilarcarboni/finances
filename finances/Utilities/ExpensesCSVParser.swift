import Foundation
import UniformTypeIdentifiers

struct ExpensesCSVParser {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    /// Parses the given CSV file URL into an array of `Transaction` objects.
    /// The expected column headers are (Spanish):
    /// - Fecha de Transacción
    /// - Descripción de Transacción
    /// - Débito de Transacción
    /// - Crédito de Transacción
    ///
    /// If the file format deviates, the parser will attempt a best-effort mapping based on those keywords.
    static func parseCSV(at url: URL) -> [Transaction] {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return [] }
        return parseCSV(from: content)
    }

    static func parseCSV(from content: String) -> [Transaction] {
        var transactions: [Transaction] = []
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard lines.count > 1 else { return [] }

        // Build header map (index lookup)
        let headerColumns = lines[0].components(separatedBy: ",")
        func index(containing keyword: String) -> Int? {
            headerColumns.firstIndex { $0.localizedCaseInsensitiveContains(keyword) }
        }
        guard let dateIdx = index(containing: "Fecha"),
              let descriptionIdx = index(containing: "Descripción"),
              let debitIdx = index(containing: "Débito"),
              let creditIdx = index(containing: "Crédito") else { return [] }

        for rawLine in lines.dropFirst() {
            let fields = rawLine.components(separatedBy: ",")
            if fields.count <= max(max(dateIdx, descriptionIdx), max(debitIdx, creditIdx)) { continue }

            let dateString = fields[dateIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let date = dateFormatter.date(from: dateString) else { continue }

            let description = fields[descriptionIdx].trimmingCharacters(in: .whitespacesAndNewlines)

            // Clean numeric strings (remove grouping separators, quotes, etc.).
            func cleanNumber(_ str: String) -> Double {
                let cleaned = str.replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return Double(cleaned) ?? 0
            }

            let debitValue = cleanNumber(fields[debitIdx])
            let creditValue = cleanNumber(fields[creditIdx])

            let (amount, type): (Double, TransactionType)
            if debitValue > 0 {
                amount = debitValue
                type = .debit
            } else if creditValue > 0 {
                amount = creditValue
                type = .credit
            } else {
                continue // Skip zero-value rows
            }

            let category = categorize(description: description)
            let transaction = Transaction(name: description,
                                          category: category,
                                          amount: amount,
                                          type: type,
                                          date: date)
            transactions.append(transaction)
        }

        return transactions
    }

    /// Basic heuristic categorization based on keywords in the transaction description.
    private static func categorize(description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("uber") || lower.contains("taxi") || lower.contains("gasoline") || lower.contains("gasolina") {
            return "Transportation"
        } else if lower.contains("netflix") || lower.contains("spotify") || lower.contains("gym") {
            return "Subscriptions"
        } else if lower.contains("loan") || lower.contains("payment") || lower.contains("pago") {
            return "Debt"
        } else if lower.contains("savings") || lower.contains("ahorro") {
            return "Savings"
        } else if lower.contains("walmart") || lower.contains("automercado") || lower.contains("pali") || lower.contains("maxi") {
            return "Groceries"
        } else {
            return "Misc"
        }
    }
} 