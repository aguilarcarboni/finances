import Foundation

/// Parser for Wise (formerly TransferWise) CSV exports.
/// Expected header columns (case-insensitive):
/// - "Date" or "Date Time" (format: dd-MM-yyyy or dd/MM/yyyy)
/// - "Description"
/// - "Amount"
///
/// Amount is positive for credits (money in) and negative for debits (money out).
/// The parser attempts a best-effort extraction and categorisation suitable for a pass-through account.
struct WiseCSVParser {
    private static let dateFormats = [
        "dd-MM-yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd",
        "yyyy/MM/dd"
    ]

    private static func parseDate(_ string: String) -> Date? {
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let d = formatter.date(from: string) { return d }
        }
        return nil
    }

    static func parseCSV(at url: URL) -> [Transaction] {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return [] }
        return parseCSV(from: content)
    }

    static func parseCSV(from content: String) -> [Transaction] {
        // Split lines, drop empty ones
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard lines.count > 1 else { return [] }

        // Headers
        let headers = lines[0].components(separatedBy: ",")
        func index(of keyword: String) -> Int? {
            headers.firstIndex { $0.localizedCaseInsensitiveContains(keyword) }
        }

        guard let dateIdx = index(of: "Date"),
              let descIdx = index(of: "Description"),
              let amountIdx = index(of: "Amount") else { return [] }

        var transactions: [Transaction] = []

        for rawLine in lines.dropFirst() {
            let fields = rawLine.components(separatedBy: ",")
            if fields.count <= max(dateIdx, max(descIdx, amountIdx)) { continue }

            let dateString = fields[dateIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let date = parseDate(dateString) else { continue }

            let description = fields[descIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let amountString = fields[amountIdx].trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "CRC", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let amountValue = Double(amountString) else { continue }

            let type: TransactionType = amountValue < 0 ? .debit : .credit
            let amount = abs(amountValue)

            let category = categorize(description: description, type: type)
            let transaction = Transaction(name: description,
                                          category: category,
                                          amount: amount,
                                          type: type,
                                          date: date)
            transactions.append(transaction)
        }

        return transactions
    }

    /// Simple categoriser for Wise transactions depending on direction and keywords.
    private static func categorize(description: String, type: TransactionType) -> String {
        let lower = description.lowercased()

        // Money sent to Interactive Brokers or IBKR
        if lower.contains("interactive brokers") || lower.contains("ibkr") {
            return "Interactive Brokers"
        }

        // Transfers between own accounts (e.g., Expenses) – heuristic
        if lower.contains("expenses") || lower.contains("expense") {
            return "Wise"
        }

        // Generic fallback – categorise all Wise movements under a single category
        return "Wise"
    }
} 