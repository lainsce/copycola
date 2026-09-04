import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Copycola

struct CopycolaCanvasLogicTests {
    @Test @MainActor
    func selectionAndCardActionStateCoversExistingCards() throws {
        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 8, y: 8, zIndex: 1)
        header.text = "Canvas"
        let image = Card(kind: .image, size: .oneByOne, x: 8, y: 180, zIndex: 2)
        image.text = "Image"
        board.cards = [header, image]
        let canvas = CanvasView(board: board)

        #expect(canvas.targetCard(image.id) === image)
        #expect(canvas.targetCard(nil) == nil)
        #expect(canvas.cardForOperation(targetID: image.id, kind: .image) === image)
        #expect(canvas.cardForOperation(targetID: UUID(), kind: .image) == nil)

        canvas.select(image)
        canvas.beginEditing(image)
        canvas.edit(image)

        #expect(canvas.accessibilitySummary(for: image) == "Image")
        canvas.editSelectedCard()
        canvas.editLink(image)
        #expect(image.cardSize == .oneByOne)

        canvas.clearSelection()
        canvas.select(image)
        canvas.requestDelete(image)
        canvas.clearSelection()
    }

    @Test @MainActor
    func creationAndImportGuardsCoverSupportedCardsAndFailures() {
        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 0, y: 0, zIndex: 1)
        board.cards = [header]
        let canvas = CanvasView(board: board)

        #expect(canvas.contentMinimumY(for: .image) == canvas.headerBottomY.map { $0 + Double(CanvasMetrics.headerContentSpacing) })
        #expect(canvas.contentMinimumY(for: .header) == nil)
        canvas.constrainToCanvasWidth(header)
        #expect(header.x == Double(CanvasMetrics.canvasMargin))
        #expect(header.y == Double(CanvasMetrics.headerTopInset))
        #expect(canvas.ensureCanvasHeader() === header)
        canvas.normalizeBoardGeometry()

        canvas.requestNewCard(.header)
        canvas.requestNewCard(.image)

        canvas.addLink("not a URL")
        canvas.handleImageImport(.failure(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)))
        canvas.handleImageImport(.failure(NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad image"])))

        canvas.bringToFront(header)
        #expect(header.zIndex == 2)
        canvas.nudge(header, x: 1, y: 1)
        canvas.addLink(" ")
    }

    @Test @MainActor
    func imageDropTypesCoverCommonRasterFormatsAndFileURLs() {
        let dropTypes = Set(CanvasView.imageDropTypes.map(\.identifier))

        #expect(dropTypes.contains(UTType.image.identifier))
        #expect(dropTypes.contains(UTType.webP.identifier))
        #expect(dropTypes.contains(UTType.jpeg.identifier))
        #expect(dropTypes.contains(UTType.png.identifier))
        #expect(dropTypes.contains(UTType.bmp.identifier))
        #expect(dropTypes.contains(UTType.gif.identifier))
        #expect(dropTypes.contains(UTType.fileURL.identifier))
        #expect(dropTypes.contains(UTType.url.identifier))
    }

    @Test @MainActor
    func bloomReflowCompletesTheFirstRingBeforeOpeningTheNext() {
        let margin = CanvasMetrics.canvasMargin
        let header = Card(
            kind: .header,
            size: .fourByOne,
            x: margin,
            y: CanvasMetrics.headerTopInset,
            zIndex: 1
        )
        let firstContentY = CanvasMetrics.headerTopInset
            + CanvasMetrics.headerHeight
            + CanvasMetrics.headerContentSpacing
        let images = (0..<6).map { index in
            Card(
                kind: .image,
                size: .oneByOne,
                x: Double(margin + CGFloat(index % 4) * CanvasMetrics.module),
                y: Double(firstContentY + CGFloat(index / 4) * CanvasMetrics.module),
                zIndex: index + 2
            )
        }
        let board = Board(name: "Canvas")
        board.cards = [header] + images
        let canvas = CanvasView(board: board)

        canvas.reflowCards(for: .bloom)

        let centerX = CanvasMetrics.canvasWidth / 2
        let cardHalf = CardSize.oneByOne.pointSize.width / 2
        let ringRadius = CanvasMetrics.bloomRingRadius
        let centerY = firstContentY + CanvasMetrics.bloomRingCenterY
        #expect(abs(images[0].x - Double(centerX - cardHalf)) < 0.5)
        #expect(abs(images[0].y - Double(centerY - cardHalf)) < 0.5)
        #expect(abs(images[1].x - Double(centerX + ringRadius - cardHalf)) < 0.5)
        #expect(abs(images[1].y - Double(centerY - cardHalf)) < 0.5)
        #expect(abs(images[2].x - Double(centerX + ringRadius / 2 - cardHalf)) < 0.5)
        #expect(abs(images[2].y - Double(firstContentY)) < 0.5)
        #expect(abs(images[3].x - Double(centerX - ringRadius / 2 - cardHalf)) < 0.5)
        #expect(abs(images[3].y - Double(firstContentY)) < 0.5)
        #expect(abs(images[4].x - Double(centerX - ringRadius - cardHalf)) < 0.5)
        #expect(abs(images[4].y - Double(centerY - cardHalf)) < 0.5)
        #expect(abs(images[5].x - Double(centerX - ringRadius / 2 - cardHalf)) < 0.5)
        #expect(abs(images[5].y - Double(firstContentY + 2 * CanvasMetrics.bloomRowPitch)) < 0.5)

        let bloomOrigins = images.map { CGPoint(x: $0.x, y: $0.y) }
        canvas.reflowCards(for: .grid)
        canvas.reflowCards(for: .bloom)
        #expect(images.map { CGPoint(x: $0.x, y: $0.y) } == bloomOrigins)
    }
}
