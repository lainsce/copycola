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
    /// Shared design-pixel inset between card content and its card edge.
    static let cardContentInset: CGFloat = 16
    /// Maximum rotation applied to a card while it is being dragged.
    static let cardDragTiltLimit: Double = 3
    /// Horizontal drag distance that reaches the tilt limit.
    static let cardDragTiltDistance: CGFloat = 80
    /// Placement pitch: one cell plus its trailing one-dot gutter.
    static let module: CGFloat = cell + gridUnit
    /// Bloom keeps the same placement rhythm as the card lattice while its
    /// visual guide uses a radial, center-out composition.
    static let bloomPitch: CGFloat = module
    static let bloomRowPitch: CGFloat = module * 0.8660254
    /// The overlap clearance used by Bloom's compressed placement rows.
    static let bloomCollisionInset: CGFloat = 4
    /// Concentric guide spacing is half a card module so the rings stay aligned
    /// with the center-out card sequence without becoming visually dense.
    static let bloomRingSpacing: CGFloat = module / 2
    /// Six slots keep the first visible ring open enough for full-size cards.
    static let bloomRingSlotCount: Int = 6
    /// The first outer ring is one module from the center card, matching the
    /// card-center spacing of the regular canvas geometry.
    static let bloomRingRadius: CGFloat = module
    static let bloomRingStartAngle: CGFloat = 0
    /// The first Bloom slot is the radial center; this is its card-center offset
    /// from the body-card origin used by `BloomGrid`.
    static let bloomRingCenterY: CGFloat = bloomRowPitch + cell / 2
    static let bloomRingCenterMarkerDiameter: CGFloat = 6
    static let bloomRingTickLength: CGFloat = 6
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
