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

    @Test func keepsAGutterAfterATwoByTwoCard() {
        let margin = CanvasMetrics.canvasMargin
        let unit = CanvasMetrics.gridUnit
        let largeCardSize = CardSize.twoByTwo.pointSize
        let largeCards = [
            CGRect(origin: CGPoint(x: margin, y: margin), size: largeCardSize),
            CGRect(
                origin: CGPoint(x: margin + CanvasMetrics.module * 2, y: margin),
                size: largeCardSize
            )
        ]

        let origin = CanvasPlacement.nearestFreePosition(
            for: CardSize.oneByOne.pointSize,
            nearX: margin,
            nearY: margin,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: largeCards
        )

        #expect(origin == CGPoint(x: margin, y: margin + 2 * CanvasMetrics.module))
        #expect(origin.y - largeCards[0].maxY == unit)
    }
}
