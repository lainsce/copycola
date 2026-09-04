import CoreGraphics
import Testing
@testable import Copycola

struct CanvasPlacementTests {
    @Test func snapsANewCardToTheGrid() {
        let margin = CanvasMetrics.canvasMargin
        let pitch = Double(CanvasMetrics.module)

        let origin = CanvasPlacement.nearestFreePosition(
            for: CardSize.oneByOne.pointSize,
            nearX: Double(margin) + pitch * 0.2,
            nearY: Double(margin) + pitch * 0.2,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: []
        )

        #expect(origin == CGPoint(x: margin, y: margin))
    }

    @Test func everyCardOriginUsesTheDotLattice() {
        let margin = CanvasMetrics.canvasMargin
        let pitch = CanvasMetrics.module

        for column in 0..<4 {
            let originX = margin + CGFloat(column) * pitch
            #expect((originX - margin).truncatingRemainder(dividingBy: pitch) == 0)
        }

        let contentOriginY = margin + CanvasMetrics.headerHeight + CanvasMetrics.headerContentSpacing
        for row in 0..<4 {
            let originY = contentOriginY + CGFloat(row) * pitch
            #expect((originY - contentOriginY).truncatingRemainder(dividingBy: pitch) == 0)
        }
    }

    @Test func startsContentAfterHeaderSpacing() {
        let margin = CanvasMetrics.canvasMargin
        let minimumY = margin + CanvasMetrics.headerHeight + CanvasMetrics.headerContentSpacing

        let origin = CanvasPlacement.nearestFreePosition(
            for: CardSize.oneByOne.pointSize,
            nearX: margin,
            nearY: margin,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: [],
            minimumY: Double(minimumY)
        )

        #expect(origin == CGPoint(x: margin, y: minimumY))
    }

    @Test func avoidsOccupiedCardsAndKeepsAGutter() {
        let margin = CanvasMetrics.canvasMargin
        let unit = CanvasMetrics.gridUnit
        let occupied = CGRect(
            x: margin,
            y: margin + unit,
            width: CardSize.oneByOne.pointSize.width,
            height: CardSize.oneByOne.pointSize.height
        )
        let origin = CanvasPlacement.nearestFreePosition(
            for: occupied.size,
            nearX: occupied.minX,
            nearY: occupied.minY,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: [occupied]
        )
        let result = CGRect(origin: origin, size: occupied.size)

        #expect(!result.insetBy(dx: -(unit - 1), dy: -(unit - 1)).intersects(occupied))
        #expect(origin == CGPoint(x: margin + CanvasMetrics.module, y: margin))
        #expect(origin.x >= margin && origin.y >= margin)
        #expect(origin.x + result.width <= CanvasMetrics.canvasWidth - margin)
    }

    @Test func continuesDownwardWhenTheFourColumnsAreOccupied() {
        let margin = CanvasMetrics.canvasMargin
        let unit = CanvasMetrics.gridUnit
        let size = CardSize.oneByOne.pointSize
        let occupied = (0..<4).map { column in
            CGRect(
                x: margin + CGFloat(column) * CanvasMetrics.module,
                y: margin,
                width: size.width,
                height: size.height
            )
        }

        let origin = CanvasPlacement.nearestFreePosition(
            for: size,
            nearX: margin,
            nearY: margin,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: occupied
        )

        let firstClearRow = ceil((size.height + unit - 1) / CanvasMetrics.module)
        #expect(origin == CGPoint(x: margin, y: margin + CGFloat(firstClearRow) * CanvasMetrics.module))
    }

    @Test func bloomPlacementUsesAFreeRadialSlot() {
        let margin = CanvasMetrics.canvasMargin
        let minimumY = margin + CanvasMetrics.headerHeight + CanvasMetrics.headerContentSpacing
        let size = CardSize.oneByOne.pointSize
        let pitch = CanvasMetrics.bloomPitch
        let rowOrigin = Double(minimumY)
        let occupied = (0..<4).map { column in
            CGRect(
                x: margin + CGFloat(column) * pitch,
                y: minimumY,
                width: size.width,
                height: size.height
            )
        }

        let origin = CanvasPlacement.nearestFreePosition(
            for: size,
            nearX: Double(margin),
            nearY: rowOrigin,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: occupied,
            minimumY: rowOrigin,
            style: .bloom
        )

        #expect(origin.x == margin + CanvasMetrics.bloomPitch / 2)
        #expect(origin.y == minimumY + CanvasMetrics.bloomRowPitch)
    }
}
