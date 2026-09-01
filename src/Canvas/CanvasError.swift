import Foundation

/// User-facing failures originating from canvas actions.
nonisolated enum CanvasError: LocalizedError {
    case invalidLink
    case locationNotFound
    case locationSearchFailed(String)
    case fileImportFailed(String)
    case imageAccessDenied
    case targetCardMissing

    var errorDescription: String? {
        switch self {
        case .invalidLink:
            String(localized: "Unable to Add Link")
        case .locationNotFound, .locationSearchFailed:
            String(localized: "Unable to Find Location")
        case .fileImportFailed, .imageAccessDenied:
            String(localized: "Unable to Import Image")
        case .targetCardMissing:
            String(localized: "Card No Longer Available")
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidLink:
            String(localized: "Enter a complete website address and try again.")
        case .locationNotFound:
            String(localized: "No matching place was found. Try a more specific search.")
        case .locationSearchFailed(let details):
            String(localized: "The location search failed: \(details)")
        case .fileImportFailed(let details):
            String(localized: "The selected file could not be imported: \(details)")
        case .imageAccessDenied:
            String(localized: "Copycola could not access the selected file.")
        case .targetCardMissing:
            String(localized: "The card was deleted before the operation completed.")
        }
    }
}
