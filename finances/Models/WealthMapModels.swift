import Foundation
import SwiftUI

// MARK: - Node Types

enum WealthMapNodeType: String, CaseIterable {
    case account = "Account"
    case asset = "Asset"
    case debt = "Debt"
    case income = "Income"
    case expense = "Expense"
    case investment = "Investment"
    case loan = "Loan"
    
    var color: Color {
        switch self {
        case .account:
            return .blue
        case .asset:
            return .purple
        case .debt:
            return .red
        case .income:
            return .green
        case .expense:
            return .orange
        case .investment:
            return .teal
        case .loan:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .account:
            return "building.columns"
        case .asset:
            return "cube.box"
        case .debt:
            return "exclamationmark.triangle"
        case .income:
            return "arrow.down.circle"
        case .expense:
            return "arrow.up.circle"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .loan:
            return "creditcard"
        }
    }
}

// MARK: - Connection Types

enum WealthMapConnectionType: String, CaseIterable {
    case transfer = "Transfer"
    case payment = "Payment"
    case income = "Income"
    case expense = "Expense"
    case investment = "Investment"
    case loan = "Loan"
    case appreciation = "Appreciation"
    case depreciation = "Depreciation"
    
    var color: Color {
        switch self {
        case .transfer:
            return .blue
        case .payment:
            return .red
        case .income:
            return .green
        case .expense:
            return .orange
        case .investment:
            return .teal
        case .loan:
            return .red
        case .appreciation:
            return .green
        case .depreciation:
            return .red
        }
    }
    
    var style: StrokeStyle {
        switch self {
        case .transfer, .payment, .income, .expense, .investment:
            return StrokeStyle(lineWidth: 2)
        case .loan:
            return StrokeStyle(lineWidth: 3, dash: [5, 5])
        case .appreciation, .depreciation:
            return StrokeStyle(lineWidth: 1, dash: [2, 2])
        }
    }
}

// MARK: - Node Model

struct WealthMapNode: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let amount: Double
    let type: WealthMapNodeType
    let position: CGPoint
    let category: String?
    let additionalInfo: [String: Any]?
    
    init(title: String, subtitle: String? = nil, amount: Double, type: WealthMapNodeType, position: CGPoint, category: String? = nil, additionalInfo: [String: Any]? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.type = type
        self.position = position
        self.category = category
        self.additionalInfo = additionalInfo
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        
        if abs(amount) >= 1_000_000 {
            let millions = amount / 1_000_000
            return "₡\(millions.formatted(.number.precision(.fractionLength(1))))M"
        } else if abs(amount) >= 1_000 {
            let thousands = amount / 1_000
            return "₡\(thousands.formatted(.number.precision(.fractionLength(0))))K"
        } else {
            return formatter.string(from: NSNumber(value: amount)) ?? "₡0"
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WealthMapNode, rhs: WealthMapNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Connection Model

struct WealthMapConnection: Identifiable, Hashable {
    let id = UUID()
    let fromNodeId: UUID
    let toNodeId: UUID
    let amount: Double
    let type: WealthMapConnectionType
    let frequency: String? // "monthly", "annual", "one-time"
    let description: String?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        
        let amountString: String
        if abs(amount) >= 1_000_000 {
            let millions = amount / 1_000_000
            amountString = "₡\(millions.formatted(.number.precision(.fractionLength(1))))M"
        } else if abs(amount) >= 1_000 {
            let thousands = amount / 1_000
            amountString = "₡\(thousands.formatted(.number.precision(.fractionLength(0))))K"
        } else {
            amountString = formatter.string(from: NSNumber(value: amount)) ?? "₡0"
        }
        
        if let frequency = frequency {
            switch frequency {
            case "monthly":
                return "\(amountString)/mo"
            case "annual":
                return "\(amountString)/yr"
            default:
                return amountString
            }
        }
        
        return amountString
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WealthMapConnection, rhs: WealthMapConnection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Wealth Map Data Model

struct WealthMapData {
    var nodes: [WealthMapNode]
    var connections: [WealthMapConnection]
    
    init(nodes: [WealthMapNode] = [], connections: [WealthMapConnection] = []) {
        self.nodes = nodes
        self.connections = connections
    }
    
    func node(with id: UUID) -> WealthMapNode? {
        nodes.first { $0.id == id }
    }
    
    func connections(from nodeId: UUID) -> [WealthMapConnection] {
        connections.filter { $0.fromNodeId == nodeId }
    }
    
    func connections(to nodeId: UUID) -> [WealthMapConnection] {
        connections.filter { $0.toNodeId == nodeId }
    }
}

// MARK: - Layout Constants

struct WealthMapLayoutConstants {
    static let nodeWidth: CGFloat = 140
    static let nodeHeight: CGFloat = 80
    static let nodeSpacing: CGFloat = 200
    static let layerSpacing: CGFloat = 150
    static let arrowHeadSize: CGFloat = 10
    static let connectionLabelPadding: CGFloat = 8
} 