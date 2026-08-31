import Testing
@testable import Copycola

struct LocationSearchTests {
    @Test
    func prefersAddressContextWhenItAlreadyContainsThePlace() {
        #expect(
            locationDisplayName(
                place: "Cupertino",
                context: "Cupertino, CA, United States",
                fallback: "query"
            ) == "Cupertino, CA, United States"
        )
    }

    @Test
    func joinsDistinctPlaceAndContextWithCommas() {
        #expect(
            locationDisplayName(
                place: "Eiffel Tower",
                context: "Paris, France",
                fallback: "query"
            ) == "Eiffel Tower, Paris, France"
        )
    }

    @Test
    func usesFallbackWhenMapKitReturnsNoName() {
        #expect(locationDisplayName(place: nil, context: nil, fallback: "query") == "query")
    }
}
