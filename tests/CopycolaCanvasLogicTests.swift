import SwiftUI
import Testing
@testable import Copycola

struct CopycolaCanvasLogicTests {
    @Test @MainActor
    func selectionAndCardActionStateCoversExistingCards() throws {
        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 8, y: 8, zIndex: 1)
        header.text = "Canvas"
        let note = Card(kind: .stickyNote, size: .oneByOne, x: 8, y: 180, zIndex: 2)
        note.text = "Note"
        let link = Card(kind: .link, size: .twoByOne, x: 398, y: 180, zIndex: 3)
        link.urlString = "https://example.com"
        link.title = "Example"
        let map = Card(kind: .map, size: .oneByOne, x: 8, y: 360, zIndex: 4)
        map.title = "Lisbon"
        board.cards = [header, note, link, map]
        let canvas = CanvasView(board: board)

        #expect(canvas.targetCard(note.id) === note)
        #expect(canvas.targetCard(nil) == nil)
        #expect(canvas.cardForOperation(targetID: note.id, kind: .stickyNote) === note)
        #expect(canvas.cardForOperation(targetID: UUID(), kind: .stickyNote) == nil)

        canvas.select(note)
        canvas.beginEditing(note)
        canvas.beginEditing(link)
        canvas.edit(link)
        canvas.edit(map)

        #expect(canvas.accessibilitySummary(for: link) == "Example")
        #expect(canvas.accessibilitySummary(for: map) == "Lisbon")
        #expect(canvas.accessibilitySummary(for: note) == "Note")
        canvas.editSelectedCard()
        canvas.chooseImage(for: note)
        canvas.editLocation(map)
        canvas.setCardSize(.oneByOne, for: note)
        #expect(note.cardSize == .oneByOne)

        canvas.clearSelection()
        canvas.select(note)
        canvas.requestDelete(note)
        canvas.clearSelection()
    }

    @Test @MainActor
    func creationAndImportGuardsCoverSpecialCardsAndFailures() {
        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 0, y: 0, zIndex: 1)
        board.cards = [header]
        let canvas = CanvasView(board: board)

        #expect(canvas.contentMinimumY(for: .stickyNote) == canvas.headerBottomY.map { $0 + Double(CanvasMetrics.headerContentSpacing) })
        #expect(canvas.contentMinimumY(for: .header) == nil)
        canvas.constrainToCanvasWidth(header)
        #expect(header.x == Double(CanvasMetrics.canvasMargin))
        #expect(header.y == Double(CanvasMetrics.headerTopInset))
        #expect(canvas.ensureCanvasHeader() === header)
        canvas.normalizeBoardGeometry()

        canvas.requestNewCard(.header)
        canvas.requestNewCard(.image)
        canvas.requestNewCard(.link)
        canvas.requestNewCard(.map)

        canvas.addLink("not a URL")
        canvas.handleImageImport(.failure(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)))
        canvas.handleImageImport(.failure(NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad image"])))

        canvas.bringToFront(header)
        #expect(header.zIndex == 2)
        canvas.nudge(header, x: 1, y: 1)
        canvas.addLink(" ")
    }
}
