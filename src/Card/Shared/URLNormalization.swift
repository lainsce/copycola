import Foundation

/// Normalizes user-typed text into a URL, adding a scheme when missing.
nonisolated func normalizedURL(_ text: String) -> URL? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let candidate = urlCandidate(for: trimmed)
    guard var components = URLComponents(string: candidate) else { return nil }
    guard let scheme = components.scheme?.lowercased(),
          validWebScheme(scheme),
          let host = components.host,
          !host.isEmpty else { return nil }

    components.scheme = scheme
    return components.url
}

private nonisolated func urlCandidate(for trimmed: String) -> String {
    trimmed.contains("://") ? trimmed : "https://\(trimmed)"
}

private nonisolated func validWebScheme(_ scheme: String) -> Bool {
    ["http", "https"].contains(scheme)
}
