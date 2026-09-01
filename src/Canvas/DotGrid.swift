import SwiftUI

/// A layered positioning grid for the fixed-width canvas.
/// Fine dots stay visible between cards while the stronger rails land on each
/// card edge and module origin, so the background explains the same geometry
/// used by snapping and placement.
struct DotGrid: View {
    let origin: CGPoint

    var body: some View {
        Canvas { context, size in
            let module = CanvasMetrics.module
            let cell = CanvasMetrics.cell
            let edgeColor = Color.primary.opacity(0.08)
            let originColor = Color.primary.opacity(0.16)

            var cardEdges = Path()
            var cardOrigins = Path()

            // Start each axis far enough back to fill the leading margin while
            // preserving the card-origin phase. This keeps a header-shifted
            // content origin aligned as well.
            var x = origin.x

            // Card edges include both sides of every cell: the module origin
            // and the trailing cell edge before the next gutter. The repeated
            // rails are intentionally subtle.
            addVerticalRails(
                start: origin.x,
                spacing: module,
                limit: size.width,
                height: size.height,
                to: &cardEdges
            )
            addVerticalRails(
                start: origin.x + cell,
                spacing: module,
                limit: size.width,
                height: size.height,
                to: &cardEdges
            )
            addHorizontalRails(
                start: origin.y,
                spacing: module,
                limit: size.height,
                width: size.width,
                to: &cardEdges
            )
            addHorizontalRails(
                start: origin.y + cell,
                spacing: module,
                limit: size.height,
                width: size.width,
                to: &cardEdges
            )

            // Larger intersections mark exact origins used by CanvasPlacement.
            x = origin.x
            while x <= size.width {
                var y = origin.y
                while y <= size.height {
                    let diameter = CanvasMetrics.majorDotDiameter
                    cardOrigins.addEllipse(
                        in: CGRect(
                            x: x - diameter / 2,
                            y: y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )
                    )
                    y += module
                }
                x += module
            }

            context.stroke(cardEdges, with: .color(edgeColor), lineWidth: 1)
            context.fill(cardOrigins, with: .color(originColor))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func addVerticalRails(
        start: CGFloat,
        spacing: CGFloat,
        limit: CGFloat,
        height: CGFloat,
        to path: inout Path
    ) {
        var x = start
        while x > 0 { x -= spacing }
        while x <= limit {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
            x += spacing
        }
    }

    private func addHorizontalRails(
        start: CGFloat,
        spacing: CGFloat,
        limit: CGFloat,
        width: CGFloat,
        to path: inout Path
    ) {
        var y = start
        while y > 0 { y -= spacing }
        while y <= limit {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
            y += spacing
        }
    }
}
