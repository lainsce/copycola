import AppKit
import Foundation
import LinkPresentation

/// Metadata fetched for a website-link card.
nonisolated struct FetchedLink: Sendable {
    var title: String?
    var iconData: Data?
    var description: String?
    var themeColorHex: String?
}

/// HTML metadata needed by a link card. Keeping this value type separate makes the parser
/// deterministic and testable without performing a network request.
nonisolated struct FetchedHTMLMetadata: Sendable, Equatable {
    var description: String?
    var themeColorHex: String?
}

/// Fetches a page title and favicon plus a description from page metadata.
nonisolated func fetchLinkMetadata(for url: URL) async -> FetchedLink {
    let provider = LPMetadataProvider()
    async let htmlMetadata = fetchHTMLMetadata(for: url)
    do {
        let metadata = try await provider.startFetchingMetadata(for: url)
        let page = await htmlMetadata
        var iconData: Data?
        if let iconProvider = metadata.iconProvider {
            iconData = await loadImageData(from: iconProvider)
        }
        return FetchedLink(
            title: metadata.title ?? url.host,
            iconData: iconData,
            description: page.description,
            themeColorHex: page.themeColorHex
        )
    } catch {
        let page = await htmlMetadata
        return FetchedLink(
            title: url.host,
            iconData: nil,
            description: page.description,
            themeColorHex: page.themeColorHex
        )
    }
}

/// Fetches a page's description and theme color in one request.
private nonisolated func fetchHTMLMetadata(for url: URL) async -> FetchedHTMLMetadata {
    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 10
    guard let (data, _) = try? await URLSession.shared.data(for: request),
          let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
        return FetchedHTMLMetadata(description: nil, themeColorHex: nil)
    }
    return parseHTMLMetadata(html)
}

/// Parses the metadata used by a link card from an HTML document.
nonisolated func parseHTMLMetadata(_ html: String) -> FetchedHTMLMetadata {
    let description = firstMetaContent(
        attribute: "property",
        value: "og:description",
        in: html
    ) ?? firstMetaContent(attribute: "name", value: "description", in: html)

    let themeColor = firstMetaContent(attribute: "name", value: "theme-color", in: html)

    return FetchedHTMLMetadata(
        description: cleanedMetadataValue(description),
        themeColorHex: normalizedThemeColorHex(themeColor)
    )
}

private nonisolated func firstMetaContent(
    attribute: String,
    value: String,
    in html: String
) -> String? {
    let pattern = "<meta\\b[^>]*>"
    guard let regex = try? NSRegularExpression(
        pattern: pattern,
        options: [.caseInsensitive, .dotMatchesLineSeparators]
    ) else {
        return nil
    }

    let range = NSRange(html.startIndex..., in: html)
    return regex.matches(in: html, range: range)
        .compactMap { metaContent(for: $0, in: html, attribute: attribute, value: value) }
        .first
}

private nonisolated func metaContent(
    for match: NSTextCheckingResult,
    in html: String,
    attribute: String,
    value: String
) -> String? {
    guard let tagRange = Range(match.range, in: html) else { return nil }
    let tag = String(html[tagRange])
    guard attributeValue(attribute, in: tag)?.caseInsensitiveCompare(value) == .orderedSame,
          let content = attributeValue("content", in: tag) else {
        return nil
    }
    return content
}

private nonisolated func attributeValue(_ attribute: String, in tag: String) -> String? {
    let escapedAttribute = NSRegularExpression.escapedPattern(for: attribute)
    let pattern = "\\b\(escapedAttribute)\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s>]+))"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
          let match = regex.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)) else {
        return nil
    }

    for index in 1..<match.numberOfRanges {
        guard match.range(at: index).location != NSNotFound,
              let valueRange = Range(match.range(at: index), in: tag) else {
            continue
        }
        return String(tag[valueRange])
    }
    return nil
}

private nonisolated func cleanedMetadataValue(_ value: String?) -> String? {
    guard let value else { return nil }
    let cleaned = decodeHTMLEntities(value).trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? nil : cleaned
}

/// Converts the common CSS color forms used by `theme-color` into a six-digit RGB hex value.
/// Unsupported CSS functions/named colors are ignored rather than risking a misleading tint.
private nonisolated func normalizedThemeColorHex(_ value: String?) -> String? {
    guard let value = cleanedMetadataValue(value)?.lowercased() else { return nil }

    if value.hasPrefix("#") {
        return normalizedHexColor(String(value.dropFirst()))
    }

    return normalizedRGBColor(value)
}

private nonisolated func normalizedHexColor(_ digits: String) -> String? {
    guard digits.allSatisfy(\.isHexDigit) else { return nil }
    let expanded = digits.count == 3
        ? digits.map { "\($0)\($0)" }.joined()
        : digits
    guard [6, 8].contains(expanded.count) else { return nil }
    // Alpha is intentionally ignored; the card applies its own subtle opacity.
    return String(expanded.prefix(6)).uppercased()
}

private nonisolated func normalizedRGBColor(_ value: String) -> String? {
    let rgbPattern = "^rgba?\\(\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})(?:\\s*,\\s*[0-9.]+)?\\s*\\)$"
    guard let regex = try? NSRegularExpression(pattern: rgbPattern),
          let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) else {
        return nil
    }

    var components: [Int] = []
    for index in 1...3 {
        guard let componentRange = Range(match.range(at: index), in: value),
              let component = Int(value[componentRange]), component <= 255 else {
            return nil
        }
        components.append(component)
    }
    return components.map { String(format: "%02X", $0) }.joined()
}

private nonisolated func decodeHTMLEntities(_ text: String) -> String {
    var result = text
    let replacements = [
        "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
        "&#39;": "'", "&apos;": "'", "&nbsp;": " ",
    ]
    for (entity, character) in replacements {
        result = result.replacing(entity, with: character)
    }
    return result
}

/// Loads PNG data from an item provider that vends an image.
private nonisolated func loadImageData(from provider: NSItemProvider) async -> Data? {
    await withCheckedContinuation { continuation in
        provider.loadObject(ofClass: NSImage.self) { object, _ in
            guard let image = object as? NSImage,
                  let tiff = image.tiffRepresentation,
                  let representation = NSBitmapImageRep(data: tiff),
                  let png = representation.representation(using: .png, properties: [:]) else {
                continuation.resume(returning: nil)
                return
            }
            continuation.resume(returning: png)
        }
    }
}
