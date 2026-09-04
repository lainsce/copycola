import SwiftUI

/// A discrete cell in the canvas placement lattice.
nonisolated struct CanvasLatticeCell: Hashable, Sendable {
    let row: Int
    let column: Int
}

/// A slot in Bloom's center-out ring sequence.
nonisolated struct CanvasBloomSlot: Hashable, Sendable {
    let ring: Int
    let index: Int
}

/// The two visual systems available for the canvas surface and card placement.
nonisolated enum CanvasGridStyle: String, CaseIterable, Identifiable {
    case grid
    case bloom

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .grid:
            "Grid"
        case .bloom:
            "Bloom"
        }
    }

    var systemImage: String {
        switch self {
        case .grid:
            "square.grid.2x2"
        case .bloom:
            "circle.circle"
        }
    }

    /// Horizontal distance between adjacent placement cells.
    var columnPitch: CGFloat {
        CanvasMetrics.module
    }

    /// Vertical distance between placement rows.
    var rowPitch: CGFloat {
        switch self {
        case .grid:
            CanvasMetrics.module
        case .bloom:
            CanvasMetrics.bloomRowPitch
        }
    }

    /// Bloom alternates a half-column phase on every other placement row.
    func rowOffset(for row: Int) -> CGFloat {
        switch self {
        case .grid:
            0
        case .bloom:
            row.isMultiple(of: 2) ? 0 : columnPitch / 2
        }
    }

    /// Returns Bloom slots in center-out order, completing a ring before opening
    /// the next one. The first ring slot is the center card; each outer ring has
    /// six evenly spaced positions and proceeds counter-clockwise from the right.
    func bloomSlotOrder(count: Int) -> [CanvasBloomSlot] {
        guard self == .bloom, count > 0 else { return [] }

        let ringSize = CanvasMetrics.bloomRingSlotCount
        var slots: [CanvasBloomSlot] = [CanvasBloomSlot(ring: 0, index: 0)]
        var ring = 1
        while slots.count < count {
            for index in 0..<ringSize {
                slots.append(CanvasBloomSlot(ring: ring, index: index))
                if slots.count == count { return slots }
            }
            ring += 1
        }
        return slots
    }

    /// Returns the top-left origin for a Bloom slot and card footprint.
    func bloomOrigin(
        for slot: CanvasBloomSlot,
        cardSize: CGSize,
        rowOrigin: Double
    ) -> CGPoint {
        let center = CGPoint(
            x: CanvasMetrics.canvasWidth / 2,
            y: CGFloat(rowOrigin) + CanvasMetrics.bloomRingCenterY
        )
        guard slot.ring > 0 else {
            return CGPoint(
                x: center.x - cardSize.width / 2,
                y: center.y - cardSize.height / 2
            )
        }

        let slotCount = CGFloat(CanvasMetrics.bloomRingSlotCount)
        let angle = CanvasMetrics.bloomRingStartAngle
            - (2 * .pi * CGFloat(slot.index) / slotCount)
        let radius = CanvasMetrics.bloomRingRadius * CGFloat(slot.ring)
        let cardCenter = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        return CGPoint(
            x: cardCenter.x - cardSize.width / 2,
            y: cardCenter.y - cardSize.height / 2
        )
    }

    /// A Bloom row leaves a smaller inter-card clearance because its compressed
    /// row pitch intentionally leaves about 11 points between 1×1 cards.
    var collisionInset: CGFloat {
        switch self {
        case .grid:
            CanvasMetrics.gridUnit - 1
        case .bloom:
            CanvasMetrics.bloomCollisionInset
        }
    }

    /// Legacy lattice ranking retained for compatibility with older callers. Active Bloom
    /// placement uses `bloomSlotOrder(_:)` so every radial ring is completed before the next.
    func bloomCellOrder(count: Int) -> [CanvasLatticeCell] {
        guard self == .bloom, count > 0 else { return [] }

        let start = CanvasLatticeCell(row: 1, column: 1)
        let directions = [
            (row: 0, column: 1),   // right
            (row: -1, column: 0),  // up
            (row: 0, column: -1),  // left
            (row: 1, column: 0)    // down
        ]

        var result: [CanvasLatticeCell] = []
        var visited = Set<CanvasLatticeCell>()
        var row = start.row
        var column = start.column

        func appendIfValid(row: Int, column: Int) {
            guard row >= 0, column >= 0 else { return }
            let cell = CanvasLatticeCell(row: row, column: column)
            guard !visited.contains(cell), isValidBloomCell(cell) else { return }
            visited.insert(cell)
            result.append(cell)
        }

        appendIfValid(row: row, column: column)

        var stepLength = 1
        var directionIndex = 0
        while result.count < count {
            for _ in 0..<2 {
                let direction = directions[directionIndex]
                for _ in 0..<stepLength {
                    row += direction.row
                    column += direction.column
                    appendIfValid(row: row, column: column)
                    if result.count == count { return result }
                }
                directionIndex = (directionIndex + 1) % directions.count
            }
            stepLength += 1
        }

        return result
    }

    private func isValidBloomCell(_ cell: CanvasLatticeCell) -> Bool {
        let x = CanvasMetrics.canvasMargin
            + rowOffset(for: cell.row)
            + columnPitch * CGFloat(cell.column)
        let rightEdge = CanvasMetrics.canvasWidth - CanvasMetrics.canvasMargin - CanvasMetrics.cell
        return x <= rightEdge + 0.5
    }
}
