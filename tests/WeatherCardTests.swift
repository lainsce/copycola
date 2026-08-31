import Foundation
import SwiftData
import Testing
@testable import Copycola

struct WeatherCardTests {
    @Test @MainActor
    func weatherCardsMatchTheReferenceDefaults() {
        let card = Card(kind: .weather, size: .oneByOne, x: 20, y: 20, zIndex: 0)

        #expect(card.kind == .weather)
        #expect(CardKind.weather.defaultCardSize == .oneByOne)
        #expect(card.weatherCondition == .partlyCloudy)
        #expect(card.weatherHighTemperatureValue == 1)
        #expect(card.weatherLowTemperatureValue == 1)
        #expect(card.weatherSummaryValue == "Still cold out there. Great day for ice cream.")
        #expect(card.weatherUsesAutomaticSummaryValue)
    }

    @Test @MainActor
    func weatherSnapshotPersistsInSwiftData() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Board.self,
            Card.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let card = Card(kind: .weather, size: .twoByOne, x: 20, y: 20, zIndex: 0)
        card.weatherLocationValue = "São Paulo"
        card.weatherSummaryValue = "Warm with late clouds."
        card.weatherHighTemperatureValue = 27
        card.weatherLowTemperatureValue = 19
        card.weatherCondition = .cloudy
        card.weatherSymbolNameValue = "cloud.fill"
        card.weatherTemperatureUnitValue = "celsius"
        card.weatherDataExpirationDate = Date(timeIntervalSince1970: 10_000)
        card.weatherLastModified = "Mon, 10 Aug 2026 04:28:23 GMT"
        context.insert(card)
        try context.save()

        let fetched = try #require(
            context.fetch(FetchDescriptor<Card>()).first(where: { $0.id == card.id })
        )
        #expect(fetched.weatherLocationValue == "São Paulo")
        #expect(fetched.weatherSummaryValue == "Warm with late clouds.")
        #expect(fetched.weatherHighTemperatureValue == 27)
        #expect(fetched.weatherLowTemperatureValue == 19)
        #expect(fetched.weatherCondition == .cloudy)
        #expect(fetched.weatherSymbolNameValue == "cloud.fill")
        #expect(fetched.weatherTemperatureUnitLabel == "°C")
        #expect(fetched.weatherDataExpirationDate == Date(timeIntervalSince1970: 10_000))
        #expect(fetched.weatherLastModified == "Mon, 10 Aug 2026 04:28:23 GMT")
    }

    @Test func exposesAllSupportedConditions() {
        #expect(Copycola.WeatherCondition.allCases.count == 7)
        #expect(Copycola.WeatherCondition.partlyCloudy.systemImage == "cloud.sun.fill")
    }

    @Test func derivesTheReferenceToneFromLiveConditions() {
        let summary = WeatherSummaryGenerator.summary(
            temperatureCelsius: 1,
            condition: .partlyCloudy,
            isDaylight: true
        )

        #expect(summary == "Still cold out there. Great day for ice cream.")
    }

    @Test func generatesDistinctDayAndNightCopyForEveryCondition() {
        for condition in WeatherCondition.allCases {
            let day = WeatherSummaryGenerator.summary(
                temperatureCelsius: 18,
                condition: condition,
                isDaylight: true
            )
            let night = WeatherSummaryGenerator.summary(
                temperatureCelsius: 18,
                condition: condition,
                isDaylight: false
            )

            #expect(!day.isEmpty)
            #expect(!night.isEmpty)
            #expect(day != night)
        }
    }

    @Test func acknowledgesTemperatureExtremesInTheEditorialCopy() {
        let freezing = WeatherSummaryGenerator.summary(
            temperatureCelsius: -20,
            condition: .clear,
            isDaylight: true
        )
        let heatwave = WeatherSummaryGenerator.summary(
            temperatureCelsius: 36,
            condition: .clear,
            isDaylight: true
        )

        #expect(freezing.hasPrefix("The cold is taking this personally."))
        #expect(heatwave.hasPrefix("The heat has entered the chat."))
    }

    @Test func groupsMETNorwaySymbolsIntoCardPalettes() {
        #expect(WeatherClient.visualCondition(forSymbolCode: "heavyrain") == .rain)
        #expect(WeatherClient.visualCondition(forSymbolCode: "lightsleet") == .snow)
        #expect(WeatherClient.visualCondition(forSymbolCode: "rainandthunder") == .storm)
        #expect(WeatherClient.visualCondition(forSymbolCode: "fog") == .fog)
        #expect(WeatherClient.visualCondition(forSymbolCode: "partlycloudy_day") == .partlyCloudy)
    }

    @Test func refreshesOnlyAfterCachedWeatherExpires() {
        let now = Date(timeIntervalSince1970: 1_000)

        #expect(WeatherClient.needsRefresh(expirationDate: nil, now: now))
        #expect(WeatherClient.needsRefresh(expirationDate: now.addingTimeInterval(-1), now: now))
        #expect(!WeatherClient.needsRefresh(expirationDate: now.addingTimeInterval(1), now: now))
    }

    @Test func identifiesAndConditionallyRevalidatesRequests() throws {
        let modified = "Mon, 10 Aug 2026 04:28:23 GMT"
        let request = try WeatherClient.request(
            latitude: -23.55052,
            longitude: -46.63329,
            lastModified: modified
        )
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let values = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        #expect(values["lat"] == "-23.5505")
        #expect(values["lon"] == "-46.6333")
        #expect(request.value(forHTTPHeaderField: "User-Agent")?.contains("Copycola/") == true)
        #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == modified)
    }

    @Test func decodesAndCachesACompactForecast() throws {
        let data = Data(
            #"""
            {
              "geometry": { "coordinates": [-46.6333, -23.5505, 738] },
              "properties": {
                "timeseries": [
                  {
                    "time": "2026-08-10T04:00:00Z",
                    "data": {
                      "instant": { "details": { "air_temperature": 15.2 } },
                      "next_1_hours": { "summary": { "symbol_code": "cloudy" } }
                    }
                  },
                  {
                    "time": "2026-08-10T16:00:00Z",
                    "data": {
                      "instant": { "details": { "air_temperature": 21.1 } },
                      "next_1_hours": { "summary": { "symbol_code": "fair_day" } }
                    }
                  },
                  {
                    "time": "2026-08-11T04:00:00Z",
                    "data": {
                      "instant": { "details": { "air_temperature": 13.1 } },
                      "next_6_hours": { "summary": { "symbol_code": "cloudy" } }
                    }
                  }
                ]
              }
            }
            """#.utf8
        )
        let now = try Date("2026-08-10T04:49:00Z", strategy: .iso8601)
        let expiration = try Date("2026-08-10T05:00:00Z", strategy: .iso8601)
        let snapshot = try WeatherClient.snapshot(
            from: data,
            now: now,
            expirationDate: expiration
        )

        #expect(snapshot.currentTemperatureCelsius == 15.2)
        #expect(snapshot.condition == .cloudy)
        #expect(snapshot.expirationDate == expiration)
        #expect(snapshot.highTemperature >= snapshot.lowTemperature)
    }
}
