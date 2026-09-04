import CoreGraphics
import Testing
@testable import Copycola

struct CardSizeTests {
    @Test func canonicalFootprintsIncludeGridGutters() {
        let cell = CanvasMetrics.cell

        #expect(CardSize.oneByOne.pointSize == CGSize(width: cell, height: cell))
        #expect(CardSize.fourByOne.pointSize == CGSize(width: CanvasMetrics.fourColumnWidth, height: CanvasMetrics.headerHeight))
        #expect(CanvasMetrics.canvasWidth == CanvasMetrics.fourColumnWidth + 2 * CanvasMetrics.canvasMargin)
        #expect(CanvasMetrics.canvasWidth - CardSize.fourByOne.pointSize.width == 2 * CanvasMetrics.canvasMargin)
        #expect(CanvasMetrics.headerHeight == 60)
        #expect(CanvasMetrics.headerContentSpacing == 8)
        #expect(CanvasMetrics.cardCornerRadius == 12)
    }

    @Test func supportedFootprintsShareOneCornerRadius() {
        #expect(CardSize.oneByOne.cornerRadius == CanvasMetrics.cardCornerRadius)
        #expect(CardSize.fourByOne.cornerRadius == CanvasMetrics.cardCornerRadius)
    }

    @Test func dragTiltIsBoundedToThreeDegrees() {
        #expect(CanvasMetrics.cardDragTiltDegrees(for: .infinity) == 3)
        #expect(CanvasMetrics.cardDragTiltDegrees(for: -.infinity) == -3)
        #expect(CanvasMetrics.cardDragTiltDegrees(for: 40) == 1.5)
    }
}
