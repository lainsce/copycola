import SwiftData
import Testing
@testable import Copycola

struct SwiftDataPersistenceTests {
    @Test @MainActor
    func assigningABoardDoesNotDuplicateItsCardRelationship() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let board = Board(name: "Test")
        let card = Card(kind: .image, size: .oneByOne, x: 0, y: 0, zIndex: 0)

        context.insert(board)
        context.insert(card)
        card.board = board
        board.cards.append(card)

        #expect(board.cards.count == 1)
        #expect(board.cards.first?.id == card.id)
    }

    @Test @MainActor
    func imageLinkPersistsWithTheCard() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let card = Card(kind: .image, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        card.urlString = "https://example.com/image"
        context.insert(card)
        try context.save()

        let fetched = try #require(
            context.fetch(FetchDescriptor<Card>()).first(where: { $0.id == card.id })
        )
        #expect(fetched.urlString == "https://example.com/image")
    }
}
