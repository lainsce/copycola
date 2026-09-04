import SwiftUI

/// A restrained concentric guide for Bloom's center-out canvas composition.
///
/// The card placement path still uses the Bloom phase in `CanvasGridStyle`, but
/// the surface guide is radial: alternating ring weights, sparse cardinal ticks,
/// and a small center marker give the canvas an industrial instrument-panel feel
/// without adding gradients, fills, or decorative noise.
struct BloomGrid: View {
    let origin: CGPoint
    let center: CGPoint?
    let viewportSize: CGSize?
    let zoom: CGFloat

    init(
        origin: CGPoint,
        center: CGPoint? = nil,
        viewportSize: CGSize? = nil,
        zoom: CGFloat = 1
    ) {
        self.origin = origin
        self.center = center
        self.viewportSize = viewportSize
        self.zoom = zoom
    }

    var body: some View {
        Canvas { context, size in
            let center = center ?? CGPoint(
                x: CanvasMetrics.canvasWidth / 2,
                y: origin.y + CanvasMetrics.bloomRingCenterY
            )
            let spacing = CanvasMetrics.bloomRingSpacing
            let canvasRadius = max(
                max(center.x, abs(size.width - center.x)),
                max(center.y, abs(size.height - center.y))
            )
            // At smaller zoom levels the viewport exposes more of the unscaled plane. Use the
            // viewport extent as a second bound so rings continue to the visible edges instead
            // of stopping at the original canvas-height estimate.
            let viewportRadius = viewportSize.map {
                max($0.width, $0.height) / max(zoom, 0.01)
            } ?? 0
            let maxRadius = max(canvasRadius, viewportRadius) + spacing

            var minorRings = Path()
            var majorRings = Path()
            var ticks = Path()
            var radius = spacing
            var ringIndex = 1

            while radius <= maxRadius {
                let ringRect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                if ringIndex.isMultiple(of: 2) {
                    majorRings.addEllipse(in: ringRect)
                    addCardinalTicks(
                        around: center,
                        radius: radius,
                        length: CanvasMetrics.bloomRingTickLength,
                        to: &ticks
                    )
                } else {
                    minorRings.addEllipse(in: ringRect)
                }

                radius += spacing
                ringIndex += 1
            }

            context.stroke(
                minorRings,
                with: .color(.primary.opacity(0.055)),
                lineWidth: 1
            )
            context.stroke(
                majorRings,
                with: .color(.primary.opacity(0.11)),
                lineWidth: 1
            )
            context.stroke(
                ticks,
                with: .color(.primary.opacity(0.13)),
                lineWidth: 1
            )

            var centerMarker = Path()
            let markerRadius = CanvasMetrics.bloomRingCenterMarkerDiameter / 2
            centerMarker.addEllipse(
                in: CGRect(
                    x: center.x - markerRadius,
                    y: center.y - markerRadius,
                    width: CanvasMetrics.bloomRingCenterMarkerDiameter,
                    height: CanvasMetrics.bloomRingCenterMarkerDiameter
                )
            )
            let crosshairLength = CanvasMetrics.bloomRingTickLength
            centerMarker.move(to: CGPoint(x: center.x - crosshairLength, y: center.y))
            centerMarker.addLine(to: CGPoint(x: center.x + crosshairLength, y: center.y))
            centerMarker.move(to: CGPoint(x: center.x, y: center.y - crosshairLength))
            centerMarker.addLine(to: CGPoint(x: center.x, y: center.y + crosshairLength))
            context.stroke(
                centerMarker,
                with: .color(.primary.opacity(0.16)),
                lineWidth: 1
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func addCardinalTicks(
        around center: CGPoint,
        radius: CGFloat,
        length: CGFloat,
        to path: inout Path
    ) {
        let outer = radius + length / 2
        let inner = radius - length / 2

        path.move(to: CGPoint(x: center.x - inner, y: center.y))
        path.addLine(to: CGPoint(x: center.x - outer, y: center.y))
        path.move(to: CGPoint(x: center.x + inner, y: center.y))
        path.addLine(to: CGPoint(x: center.x + outer, y: center.y))
        path.move(to: CGPoint(x: center.x, y: center.y - inner))
        path.addLine(to: CGPoint(x: center.x, y: center.y - outer))
        path.move(to: CGPoint(x: center.x, y: center.y + inner))
        path.addLine(to: CGPoint(x: center.x, y: center.y + outer))
    }
}
