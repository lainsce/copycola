import Foundation
import SwiftData
import Testing
@testable import Copycola

struct CalendarCardTests {
    @Test func exposesAllThreeDateModes() {
        #expect(CalendarDateKind.allCases == [.dateRange, .singleDate, .recurring])
        #expect(String(localized: CalendarDateKind.dateRange.displayName) == "Date Range")
    }

    @Test @MainActor
    func calendarCardsStartWithEditableEventDefaults() throws {
        let card = Card(kind: .calendar, size: .oneByOne, x: 20, y: 20, zIndex: 0)

        #expect(card.kind == .calendar)
        #expect(CardKind.calendar.defaultCardSize == .oneByOne)
        #expect(card.cardSize == .oneByOne)
        #expect(card.calendarDateKind == .singleDate)
        #expect(card.calendarEventTitleValue == "Event")
        #expect(card.calendarEmojiValue == "📅")
        #expect(card.calendarEndDateValue > card.calendarStartDateValue)
    }

    @Test @MainActor
    func calendarFieldsPersistInSwiftData() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let card = Card(kind: .calendar, size: .oneByOne, x: 20, y: 20, zIndex: 0)
        card.calendarDateKind = .recurring
        card.calendarEventTitleValue = "FaceTime"
        card.calendarEmojiValue = "💬"
        context.insert(card)
        try context.save()

        let fetched = try #require(
            context.fetch(FetchDescriptor<Card>()).first(where: { $0.id == card.id })
        )
        #expect(fetched.calendarDateKind == .recurring)
        #expect(fetched.calendarEventTitleValue == "FaceTime")
        #expect(fetched.calendarEmojiValue == "💬")
    }

    @Test
    func calendarStickerEntryPreservesOrderAndLimitsToThree() {
        #expect(calendarStickerValues(from: "🇮🇹 ❤️ 🎉 🔥") == ["🇮🇹", "❤️", "🎉"])
    }
}
