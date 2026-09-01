import Foundation

struct CanvasPromptInterpretation {
    let kind: CardKind
    let content: String
    let location: String?
}

enum CanvasPromptInterpreter {
    static func interpret(_ prompt: String) -> CanvasPromptInterpretation {
        let normalized = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = normalized.lowercased()
        if let explicit = explicitInterpretation(normalized: normalized, lowercased: lowercased) {
            return explicit
        }
        if let special = specialInterpretation(normalized: normalized, lowercased: lowercased) {
            return special
        }

        let inferredLocation = location(in: normalized, lowercased: lowercased)
        return CanvasPromptInterpretation(
            kind: .stickyNote,
            content: conciseSubject(normalized),
            location: inferredLocation
        )
    }

    private static func explicitInterpretation(
        normalized: String,
        lowercased: String
    ) -> CanvasPromptInterpretation? {
        let prefixes: [(String, CardKind)] = [
            ("note:", .stickyNote),
            ("link:", .link),
            ("map:", .map)
        ]
        guard let match = prefixes.first(where: { lowercased.hasPrefix($0.0) }) else {
            return nil
        }
        return CanvasPromptInterpretation(
            kind: match.1,
            content: String(normalized.dropFirst(match.0.count)).trimmingCharacters(in: .whitespacesAndNewlines),
            location: nil
        )
    }

    private static func specialInterpretation(
        normalized: String,
        lowercased: String
    ) -> CanvasPromptInterpretation? {
        if isLinkPrompt(lowercased) {
            return CanvasPromptInterpretation(kind: .link, content: normalized, location: nil)
        }
        if isEventPrompt(lowercased) {
            return CanvasPromptInterpretation(
                kind: .stickyNote,
                content: eventContent(for: normalized),
                location: location(in: normalized, lowercased: lowercased)
            )
        }
        if isMapPrompt(lowercased) {
            return CanvasPromptInterpretation(
                kind: .map,
                content: normalized,
                location: location(in: normalized, lowercased: lowercased)
            )
        }
        return nil
    }

    private static func isLinkPrompt(_ lowercased: String) -> Bool {
        ["http://", "https://", "www."].contains { lowercased.contains($0) }
    }

    private static func isEventPrompt(_ lowercased: String) -> Bool {
        ["remind me", "event", "meeting", "appointment", "schedule", "deadline"]
            .contains { lowercased.contains($0) }
    }

    private static func isMapPrompt(_ lowercased: String) -> Bool {
        ["map", "where is", "directions", "location", "place"]
            .contains { lowercased.contains($0) }
    }

    private static func eventContent(for prompt: String) -> String {
        eventTitle(in: prompt) ?? conciseSubject(prompt)
    }

    private static func conciseSubject(_ prompt: String) -> String {
        let subject = prompt.replacingOccurrences(of: "^(make|create|start|add|show|track)\\s+(a\\s+)?", with: "", options: [.regularExpression, .caseInsensitive]).trimmingCharacters(in: .whitespacesAndNewlines)
        return subject.isEmpty ? prompt : subject
    }

    private static func location(in prompt: String, lowercased: String) -> String? {
        for marker in ["at ", "in ", "near ", "around "] {
            if let found = value(after: marker, in: lowercased, original: prompt) { return found }
        }
        return nil
    }

    private static func eventTitle(in prompt: String) -> String? {
        guard let ofRange = prompt.range(of: "of ", options: .caseInsensitive) else { return nil }
        let remainder = prompt[ofRange.upperBound...]
        let end = eventEndIndex(in: remainder)
        let rawTitle = remainder[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        let title = removingLeadingArticle(from: rawTitle)
        return title.isEmpty ? nil : title
    }

    private static func eventEndIndex(in remainder: Substring) -> String.Index {
        remainder.range(of: " at ", options: .caseInsensitive)?.lowerBound
            ?? remainder.range(of: " on ", options: .caseInsensitive)?.lowerBound
            ?? remainder.endIndex
    }

    private static func removingLeadingArticle(from title: String) -> String {
        let articles = ["the ", "a ", "an ", "my "]
        for article in articles where title.lowercased().hasPrefix(article) {
            return title.dropFirst(article.count).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
    }

    private static func value(after marker: String, in lowercased: String, original: String) -> String? {
        guard let markerRange = lowercased.range(of: marker, options: .backwards) else { return nil }
        let start = markerRange.upperBound
        let tail = lowercased[start...]
        let end = valueEndIndex(in: tail)
        let originalStart = original.index(original.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: start))
        let originalEnd = original.index(originalStart, offsetBy: tail.distance(from: tail.startIndex, to: end))
        let value = original[originalStart..<originalEnd].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : String(value)
    }

    private static func valueEndIndex(in tail: Substring) -> String.Index {
        tail.range(of: ",", options: .caseInsensitive)?.lowerBound
            ?? tail.range(of: ".", options: .caseInsensitive)?.lowerBound
            ?? tail.endIndex
    }

}
