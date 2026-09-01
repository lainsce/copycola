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

        let prefixes: [(String, CardKind)] = [
            ("note:", .stickyNote),
            ("link:", .link),
            ("map:", .map)
        ]
        for (prefix, kind) in prefixes where lowercased.hasPrefix(prefix) {
            return CanvasPromptInterpretation(
                kind: kind,
                content: String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines),
                location: nil
            )
        }

        if lowercased.contains("http://") || lowercased.contains("https://") || lowercased.contains("www.") {
            return CanvasPromptInterpretation(kind: .link, content: normalized, location: nil)
        }
        if lowercased.contains("remind me") || lowercased.contains("event") || lowercased.contains("meeting") || lowercased.contains("appointment") || lowercased.contains("schedule") || lowercased.contains("deadline") {
            return CanvasPromptInterpretation(
                kind: .stickyNote,
                content: eventTitle(in: normalized) ?? conciseSubject(normalized),
                location: location(in: normalized, lowercased: lowercased)
            )
        }
        if lowercased.contains("map") || lowercased.contains("where is") || lowercased.contains("directions") || lowercased.contains("location") || lowercased.contains("place") {
            return CanvasPromptInterpretation(kind: .map, content: normalized, location: location(in: normalized, lowercased: lowercased))
        }

        // Requests that used to create specialized cards remain useful as notes. Keeping
        // the original wording avoids silently dropping information now that the card set is
        // intentionally small.
        let inferredLocation = location(in: normalized, lowercased: lowercased)
        return CanvasPromptInterpretation(
            kind: .stickyNote,
            content: conciseSubject(normalized),
            location: inferredLocation
        )
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
        let end = remainder.range(of: " at ", options: .caseInsensitive)?.lowerBound
            ?? remainder.range(of: " on ", options: .caseInsensitive)?.lowerBound
            ?? remainder.endIndex
        var title = remainder[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        let articles = ["the ", "a ", "an ", "my "]
        for article in articles where title.lowercased().hasPrefix(article) {
            title = title.dropFirst(article.count).trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
        return title.isEmpty ? nil : String(title)
    }

    private static func value(after marker: String, in lowercased: String, original: String) -> String? {
        guard let markerRange = lowercased.range(of: marker, options: .backwards) else { return nil }
        let start = markerRange.upperBound
        let tail = lowercased[start...]
        let end = tail.range(of: ",", options: .caseInsensitive)?.lowerBound
            ?? tail.range(of: ".", options: .caseInsensitive)?.lowerBound
            ?? tail.endIndex
        let originalStart = original.index(original.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: start))
        let originalEnd = original.index(originalStart, offsetBy: tail.distance(from: tail.startIndex, to: end))
        let value = original[originalStart..<originalEnd].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : String(value)
    }

}
