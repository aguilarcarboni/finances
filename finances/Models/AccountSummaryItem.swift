import Foundation

struct AccountSummaryItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let amount: Double
    let trend: Trend?
    let icon: String
    let color: String
    
    enum Trend {
        case up(Double)
        case down(Double)
        case neutral
        
        var displayValue: String {
            switch self {
            case .up(let value):
                return "+\(value.formatted(.percent.precision(.fractionLength(1))))"
            case .down(let value):
                return "\(value.formatted(.percent.precision(.fractionLength(1))))"
            case .neutral:
                return "0%"
            }
        }
        
        var isPositive: Bool {
            switch self {
            case .up:
                return true
            case .down:
                return false
            case .neutral:
                return true
            }
        }
    }
}
