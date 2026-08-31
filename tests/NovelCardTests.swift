import Foundation
import SwiftData
import Testing
@testable import Copycola

struct NovelCardTests {
    @Test @MainActor
    func newCardKindsUseTheDesignedFootprintsAndDefaults() {
        let progress = Card(kind: .progress, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        let checklist = Card(kind: .checklist, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        let quote = Card(kind: .quote, size: .twoByOne, x: 0, y: 0, zIndex: 0)
        let palette = Card(kind: .palette, size: .oneByOne, x: 0, y: 0, zIndex: 0)

        #expect(CardKind.progress.defaultCardSize == .oneByOne)
        #expect(CardKind.checklist.defaultCardSize == .oneByOne)
        #expect(CardKind.quote.defaultCardSize == .twoByOne)
        #expect(CardKind.palette.defaultCardSize == .oneByOne)
        #expect(progress.progressTitleValue == "Progress")
        #expect(checklist.checklistSlots.count == 3)
        #expect(quote.quoteAttributionValue == "Steve Jobs")
        #expect(palette.paletteColorHexValues == PaletteCardDefaults.defaultColors)
    }

    @Test
    func progressCountsElapsedDaysWithinItsGoal() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let start = try #require(calendar.date(from: DateComponents(year: 2030, month: 1, day: 1)))
        let goal = try #require(calendar.date(from: DateComponents(year: 2030, month: 1, day: 31)))
        let now = try #require(calendar.date(from: DateComponents(year: 2030, month: 1, day: 11)))

        #expect(ProgressCardLogic.totalDays(start: start, goal: goal, calendar: calendar) == 30)
        #expect(
            ProgressCardLogic.completedDays(
                start: start,
                goal: goal,
                now: now,
                calendar: calendar
            ) == 10
        )
        #expect(
            ProgressCardLogic.completedDays(
                start: start,
                goal: goal,
                now: goal.addingTimeInterval(86_400),
                calendar: calendar
            ) == 30
        )
    }

    @Test @MainActor
    func checklistKeepsAtMostThreeStableSlots() {
        let card = Card(kind: .checklist, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        card.checklistItemValueOne = "Plan"
        card.checklistItemValueTwo = "Review"
        card.checklistItemValueThree = "Ship"
        card.checklistCompletedMaskValue = 0

        #expect(card.checklistSlots.map(\.id) == [0, 1, 2])
        #expect(card.checklistSlots.count == 3)
        card.setChecklistCompleted(true, at: 1)
        #expect(card.checklistSlots[1].isCompleted)

        card.checklistItemValueThree = "   "
        #expect(card.checklistSlots.count == 2)
        #expect(card.checklistSlots.map(\.id) == [0, 1])
    }

    @Test @MainActor
    func paletteColorsPersistAsFivePantoneChips() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let card = Card(kind: .palette, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        card.paletteTitleValue = "Spring"
        card.paletteColorHexValues = ["112233", "445566", "778899", "AABBCC", "DDEEFF", "FFFFFF"]
        context.insert(card)
        try context.save()

        let fetched = try #require(
            context.fetch(FetchDescriptor<Card>()).first(where: { $0.id == card.id })
        )
        #expect(fetched.paletteTitleValue == "Spring")
        #expect(fetched.paletteColorHexValues == ["112233", "445566", "778899", "AABBCC", "DDEEFF"])
    }
}
