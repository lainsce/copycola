import CoreGraphics

/// Shared geometry values for the canvas grid and magnetic snapping.
nonisolated enum CanvasMetrics {
    /// Structural gutter between adjacent cards, in points.
    static let gridUnit: CGFloat = 40
    /// Diameter of an emphasized card-grid origin marker.
    static let majorDotDiameter: CGFloat = 3
    /// Base size of a 1×1 card cell, in points.
    static let cell: CGFloat = 175
    /// Fixed footprint height for a header card.
    static let headerHeight: CGFloat = 60
    /// The canvas content runs beneath the unified toolbar; keep the structural header below it.
    static let headerTopInset: CGFloat = 56
    /// Minimum breathing room between a header's divider and the cards below it.
    static let headerContentSpacing: CGFloat = 8
    /// Industrial geometry: tight enough to feel structural without becoming sharp.
    static let cardCornerRadius: CGFloat = 12
    static let bigCardCornerRadius: CGFloat = 12
    /// Shared design-pixel inset between card content and its card edge.
    static let cardContentInset: CGFloat = 16
    /// Maximum rotation applied to a card while it is being dragged.
    static let cardDragTiltLimit: Double = 3
    /// Horizontal drag distance that reaches the tilt limit.
    static let cardDragTiltDistance: CGFloat = 80
    /// Placement pitch: one cell plus its trailing one-dot gutter.
    static let module: CGFloat = cell + gridUnit
    /// Width occupied by a 4×1 card, including the three internal one-dot gutters.
    static let fourColumnWidth: CGFloat = 4 * cell + 3 * gridUnit
    /// The fixed inset around the canvas content.
    static let canvasMargin: CGFloat = gridUnit
    /// The canvas is four columns wide with one structural gutter on either side.
    static let canvasWidth: CGFloat = fourColumnWidth + 2 * canvasMargin

    /// Returns a card footprint using the current base cell and dot gutter metrics.
    static func footprintSize(columns: Int, rows: Int) -> CGSize {
        let columns = max(1, columns)
        let rows = max(1, rows)
        return CGSize(
            width: CGFloat(columns) * cell + CGFloat(columns - 1) * gridUnit,
            height: CGFloat(rows) * cell + CGFloat(rows - 1) * gridUnit
        )
    }

    /// Rounds a value to the nearest multiple of an arbitrary pitch.
    static func snap(_ value: Double, to pitch: Double) -> Double {
        (value / pitch).rounded() * pitch
    }

    /// Rounds a value to the nearest grid line.
    static func snap(_ value: Double) -> Double {
        snap(value, to: Double(gridUnit))
    }

    /// Maps horizontal drag distance to a bounded card tilt.
    static func cardDragTiltDegrees(for horizontalTranslation: CGFloat) -> Double {
        let normalized = min(max(horizontalTranslation / cardDragTiltDistance, -1), 1)
        return Double(normalized) * cardDragTiltLimit
    }
}
