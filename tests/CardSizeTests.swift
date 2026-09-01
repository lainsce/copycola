import CoreGraphics
import Testing
@testable import Copycola

struct CardSizeTests {
    @Test func footprintsIncludeGridGutters() {
        let cell = CanvasMetrics.cell
        let gutter = CanvasMetrics.gridUnit

        #expect(CardSize.oneByOne.pointSize == CGSize(width: cell, height: cell))
        #expect(CardSize.twoByOne.pointSize == CGSize(width: 2 * cell + gutter, height: cell))
        #expect(CardSize.twoByTwo.pointSize == CGSize(width: 2 * cell + gutter, height: 2 * cell + gutter))
        #expect(CardSize.fourByOne.pointSize == CGSize(width: CanvasMetrics.fourColumnWidth, height: CanvasMetrics.headerHeight))
        #expect(CanvasMetrics.canvasWidth == CanvasMetrics.fourColumnWidth + 2 * CanvasMetrics.canvasMargin)
        #expect(CanvasMetrics.canvasWidth - CardSize.fourByOne.pointSize.width == 2 * CanvasMetrics.canvasMargin)
        #expect(CanvasMetrics.headerHeight == 60)
        #expect(CanvasMetrics.headerContentSpacing == 8)
        #expect(CanvasMetrics.cardCornerRadius == 12)
    }

    @Test func onlyTwoByTwoUsesBigCornerRadius() {
        #expect(CardSize.oneByOne.cornerRadius == CanvasMetrics.cardCornerRadius)
        #expect(CardSize.twoByOne.cornerRadius == CanvasMetrics.cardCornerRadius)
        #expect(CardSize.twoByTwo.cornerRadius == CanvasMetrics.bigCardCornerRadius)
        #expect(CardSize.fourByOne.cornerRadius == CanvasMetrics.cardCornerRadius)
    }

    @Test func dragTiltIsBoundedToThreeDegrees() {
        #expect(CanvasMetrics.cardDragTiltDegrees(for: .infinity) == 3)
        #expect(CanvasMetrics.cardDragTiltDegrees(for: -.infinity) == -3)
        #expect(CanvasMetrics.cardDragTiltDegrees(for: 40) == 1.5)
    }
}
