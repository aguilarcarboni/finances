import SwiftUI

struct WealthMapView: View {
    @StateObject private var wealthMapManager = WealthMapManager.shared
    @State private var selectedNode: WealthMapNode?
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var showNodeDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // Wealth Map Content
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        // Background grid
                        GridPattern()
                            .opacity(0.1)
                        
                        // Connections Layer
                        ConnectionsLayer(
                            nodes: wealthMapManager.wealthMapData.nodes,
                            connections: wealthMapManager.wealthMapData.connections
                        )
                        
                        // Nodes Layer
                        NodesLayer(
                            nodes: wealthMapManager.wealthMapData.nodes,
                            selectedNode: $selectedNode,
                            showNodeDetails: $showNodeDetails
                        )
                    }
                    .frame(width: 1500, height: 1000) // Increased canvas size
                }
                .scaleEffect(zoomScale)
                .offset(panOffset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = max(0.5, min(value, 2.0))
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    panOffset = value.translation
                                }
                        )
                )
                
                // Controls Overlay
                VStack {
                    HStack {
                        Spacer()
                        
                        // Map Controls
                        VStack(spacing: 8) {
                            Button(action: { zoomScale = min(zoomScale + 0.2, 2.0) }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(CircularButtonStyle())
                            
                            Button(action: { zoomScale = max(zoomScale - 0.2, 0.5) }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(CircularButtonStyle())
                            
                            Button(action: { 
                                zoomScale = 1.0
                                panOffset = .zero
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(CircularButtonStyle())
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Summary Card
                    WealthMapSummaryCard(
                        summary: wealthMapManager.getNodeSummary()
                    )
                    .padding()
                }
            }
            .navigationTitle("Wealth Map")
            .toolbar {
                ToolbarItem() {
                    Button("Refresh") {
                        wealthMapManager.refreshWealthMap()
                    }
                }
            }
            .sheet(item: $selectedNode) { node in
                NodeDetailView(node: node)
            }
        }
    }
}

// MARK: - Grid Pattern

struct GridPattern: View {
    let gridSize: CGFloat = 50
    
    var body: some View {
        Canvas { context, size in
            // Vertical lines
            for x in stride(from: 0, through: size.width, by: gridSize) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(.gray),
                    lineWidth: 0.5
                )
            }
            
            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: gridSize) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(.gray),
                    lineWidth: 0.5
                )
            }
        }
    }
}

// MARK: - Connections Layer

struct ConnectionsLayer: View {
    let nodes: [WealthMapNode]
    let connections: [WealthMapConnection]
    
    var body: some View {
        ZStack {
            ForEach(connections) { connection in
                if let fromNode = nodes.first(where: { $0.id == connection.fromNodeId }),
                   let toNode = nodes.first(where: { $0.id == connection.toNodeId }) {
                    
                    ConnectionView(
                        from: fromNode,
                        to: toNode,
                        connection: connection
                    )
                }
            }
        }
    }
}

// MARK: - Nodes Layer

struct NodesLayer: View {
    let nodes: [WealthMapNode]
    @Binding var selectedNode: WealthMapNode?
    @Binding var showNodeDetails: Bool
    
    var body: some View {
        ZStack {
            ForEach(nodes) { node in
                NodeView(node: node, isSelected: selectedNode?.id == node.id)
                    .position(node.position)
                    .onTapGesture {
                        selectedNode = node
                        showNodeDetails = true
                    }
            }
        }
    }
}

// MARK: - Node View

struct NodeView: View {
    let node: WealthMapNode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: node.type.icon)
                    .font(.caption)
                    .foregroundColor(node.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = node.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Spacer()
                Text(node.formattedAmount)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(node.amount >= 0 ? .green : .red)
                    .monospacedDigit()
            }
        }
        .padding(8)
        .frame(width: WealthMapLayoutConstants.nodeWidth, height: WealthMapLayoutConstants.nodeHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? node.type.color : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Connection View

struct ConnectionView: View {
    let from: WealthMapNode
    let to: WealthMapNode
    let connection: WealthMapConnection
    
    var body: some View {
        ZStack {
            // Connection line with arrow
            ConnectionLine(
                from: from.position,
                to: to.position,
                connection: connection
            )
            
            // Amount label
            if connection.amount > 0 {
                ConnectionLabel(
                    from: from.position,
                    to: to.position,
                    connection: connection
                )
            }
        }
    }
}

// MARK: - Connection Line

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let connection: WealthMapConnection
    
    var body: some View {
        Path { path in
            // Calculate better control points for curved connections
            let dx = to.x - from.x
            let dy = to.y - from.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Calculate connection points at the edges of nodes
            let nodeRadius: CGFloat = WealthMapLayoutConstants.nodeWidth / 2
            let fromEdge = CGPoint(
                x: from.x + (dx / distance) * nodeRadius,
                y: from.y + (dy / distance) * nodeRadius
            )
            let toEdge = CGPoint(
                x: to.x - (dx / distance) * nodeRadius,
                y: to.y - (dy / distance) * nodeRadius
            )
            
            // Adjust curve based on connection direction and distance
            let curveHeight: CGFloat = min(60, distance * 0.3)
            let edgeDx = toEdge.x - fromEdge.x
            let controlPoint1 = CGPoint(
                x: fromEdge.x + edgeDx * 0.3,
                y: fromEdge.y - curveHeight
            )
            let controlPoint2 = CGPoint(
                x: fromEdge.x + edgeDx * 0.7,
                y: toEdge.y - curveHeight
            )
            
            path.move(to: fromEdge)
            path.addCurve(to: toEdge, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(connection.type.color, style: connection.type.style)
        .overlay(
            // Arrow head
            ArrowHead(from: from, to: to, color: connection.type.color)
        )
    }
}

// MARK: - Arrow Head

struct ArrowHead: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    
    var body: some View {
        // Calculate arrow position at the edge of the target node
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Position arrow at the edge of the node (accounting for node size)
        let nodeRadius: CGFloat = WealthMapLayoutConstants.nodeWidth / 2
        let arrowPosition = CGPoint(
            x: to.x - (dx / distance) * nodeRadius,
            y: to.y - (dy / distance) * nodeRadius
        )
        
        let angle = atan2(dy, dx)
        let arrowSize: CGFloat = 10
        
        Path { path in
            path.move(to: arrowPosition)
            path.addLine(to: CGPoint(
                x: arrowPosition.x - arrowSize * cos(angle - .pi/6),
                y: arrowPosition.y - arrowSize * sin(angle - .pi/6)
            ))
            path.move(to: arrowPosition)
            path.addLine(to: CGPoint(
                x: arrowPosition.x - arrowSize * cos(angle + .pi/6),
                y: arrowPosition.y - arrowSize * sin(angle + .pi/6)
            ))
        }
        .stroke(color, lineWidth: 2)
    }
}

// MARK: - Connection Label

struct ConnectionLabel: View {
    let from: CGPoint
    let to: CGPoint
    let connection: WealthMapConnection
    
    var body: some View {
        // Position label away from the direct line to avoid overlapping
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        let curveHeight: CGFloat = min(60, distance * 0.3)
        
        let midpoint = CGPoint(
            x: (from.x + to.x) / 2,
            y: (from.y + to.y) / 2 - curveHeight - 15 // Position above the curve
        )
        
        Text(connection.formattedAmount)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
            .position(midpoint)
    }
}

// MARK: - Summary Card

struct WealthMapSummaryCard: View {
    let summary: (totalAssets: Double, totalDebt: Double, monthlyIncome: Double, monthlyExpenses: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(summary.totalAssets))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(summary.totalDebt))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(summary.monthlyIncome))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(summary.monthlyExpenses))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
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
}

// MARK: - Node Detail View

struct NodeDetailView: View {
    let node: WealthMapNode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: node.type.icon)
                                .font(.title2)
                                .foregroundColor(node.type.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                if let subtitle = node.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Text(node.formattedAmount)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(node.amount >= 0 ? .green : .red)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VisualDetailRow(title: "Type", value: node.type.rawValue)
                            
                            if let category = node.category {
                                VisualDetailRow(title: "Category", value: category)
                            }
                            
                            VisualDetailRow(title: "Amount", value: formatCurrency(node.amount))
                            
                            if node.amount >= 0 {
                                VisualDetailRow(title: "Status", value: "Positive")
                            } else {
                                VisualDetailRow(title: "Status", value: "Negative")
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Node Details")
            .toolbar {
                ToolbarItem() {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₡"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₡0"
    }
}

// MARK: - Detail Row

struct VisualDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Circular Button Style

struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 
