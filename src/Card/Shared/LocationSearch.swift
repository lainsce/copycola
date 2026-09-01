import Foundation
import MapKit

/// A geocoded location result for a map card.
nonisolated struct FoundLocation: Sendable {
    var name: String
    var latitude: Double
    var longitude: Double
}

nonisolated enum LocationSearchError: Error {
    case noResults
}

/// Produces a concise caption from MapKit's place name and address context.
/// Address contexts commonly repeat the place name (for example, "Cupertino, CA,
/// United States"), so prefer that complete context instead of joining both with "and".
nonisolated func locationDisplayName(
    place: String?,
    context: String?,
    fallback: String
) -> String {
    let place = place?.trimmingCharacters(in: .whitespacesAndNewlines)
    let context = context?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let context, !context.isEmpty {
        return contextualLocationName(place: place, context: context)
    }

    if let place, !place.isEmpty {
        return place
    }

    return fallback
}

private nonisolated func contextualLocationName(place: String?, context: String) -> String {
    guard let place, !place.isEmpty else { return context }
    if context.localizedCaseInsensitiveContains(place) { return context }
    return "\(place), \(context)"
}

/// Searches for a place by natural-language query and returns the first match.
nonisolated func searchLocation(_ query: String) async throws -> FoundLocation {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    let response = try await MKLocalSearch(request: request).start()
    guard let item = response.mapItems.first else {
        throw LocationSearchError.noResults
    }

    let coordinate = item.location.coordinate
    guard CLLocationCoordinate2DIsValid(coordinate) else {
        throw LocationSearchError.noResults
    }
    let place = item.name
    let context = item.addressRepresentations?.cityWithContext(.full)

    return FoundLocation(
        name: locationDisplayName(place: place, context: context, fallback: query),
        latitude: coordinate.latitude,
        longitude: coordinate.longitude
    )
}
