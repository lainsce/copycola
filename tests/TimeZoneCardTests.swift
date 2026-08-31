import Foundation
import SwiftData
import Testing
@testable import Copycola

struct TimeZoneCardTests {
    @Test func exposesDefaultAndRegionPresets() {
        #expect(CardKind.timeZone.defaultCardSize == .oneByOne)
        #expect(String(localized: CardKind.timeZone.displayName) == "Time Zone")
        #expect(TimeZoneCardPreset.defaultPreset.identifier == "Asia/Tokyo")
        #expect(TimeZoneCardPreset.preset(for: "Asia/Tokyo").city == "Tokyo")
        #expect(TimeZoneCardPreset.preset(for: "Europe/Rome").city == "Rome")
        #expect(TimeZoneCardPreset.preset(for: "missing/zone").identifier == "Asia/Tokyo")
    }

    @Test func formatsOffsetAndDaylightForTokyo() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let morning = Date(timeIntervalSince1970: 0)
        let evening = Date(timeIntervalSince1970: 9 * 60 * 60)

        #expect(TimeZoneCardLogic.offsetText(at: morning, in: tokyo) == "+9:00")
        #expect(TimeZoneCardLogic.isDaytime(at: morning, in: tokyo))
        #expect(!TimeZoneCardLogic.isDaytime(at: evening, in: tokyo))
    }

    @Test @MainActor
    func timeZoneIdentifierPersistsInSwiftData() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let card = Card(kind: .timeZone, size: .oneByOne, x: 20, y: 20, zIndex: 0)
        card.timeZoneIdentifierValue = "Europe/London"
        context.insert(card)
        try context.save()

        let fetched = try #require(
            context.fetch(FetchDescriptor<Card>()).first(where: { $0.id == card.id })
        )
        #expect(fetched.kind == .timeZone)
        #expect(fetched.timeZoneIdentifierValue == "Europe/London")
    }
}
