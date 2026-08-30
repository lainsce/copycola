import Foundation

struct CanvasPromptInterpretation {
    let kind: CardKind
    let content: String
    let date: Date?
    let location: String?
}

enum CanvasPromptInterpreter {
    static func interpret(_ prompt: String) -> CanvasPromptInterpretation {
        let normalized = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = normalized.lowercased()

        let prefixes: [(String, CardKind)] = [
            ("header:", .header), ("title:", .header), ("quote:", .quote),
            ("checklist:", .checklist), ("progress:", .progress), ("palette:", .palette),
            ("note:", .stickyNote)
        ]
        for (prefix, kind) in prefixes where lowercased.hasPrefix(prefix) {
            return CanvasPromptInterpretation(
                kind: kind,
                content: String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines),
                date: nil,
                location: nil
            )
        }

        if lowercased.contains("http://") || lowercased.contains("https://") || lowercased.contains("www.") {
            return CanvasPromptInterpretation(kind: .link, content: normalized, date: nil, location: nil)
        }
        if lowercased.contains("weather") || lowercased.contains("forecast") || lowercased.contains("temperature") {
            return CanvasPromptInterpretation(kind: .weather, content: normalized, date: nil, location: location(in: normalized, lowercased: lowercased))
        }
        if lowercased.contains("time zone") || lowercased.contains("timezone") || lowercased.contains("gmt") {
            return CanvasPromptInterpretation(kind: .timeZone, content: normalized, date: nil, location: location(in: normalized, lowercased: lowercased))
        }
        if lowercased.contains("remind me") || lowercased.contains("event") || lowercased.contains("meeting") || lowercased.contains("appointment") || lowercased.contains("schedule") || lowercased.contains("deadline") {
            return CanvasPromptInterpretation(kind: .calendar, content: eventTitle(in: normalized) ?? normalized, date: eventDate(in: normalized), location: location(in: normalized, lowercased: lowercased))
        }
        if lowercased.contains("map") || lowercased.contains("where is") || lowercased.contains("directions") || lowercased.contains("location") || lowercased.contains("place") {
            return CanvasPromptInterpretation(kind: .map, content: normalized, date: nil, location: location(in: normalized, lowercased: lowercased))
        }
        if lowercased.contains("checklist") || lowercased.contains("to-do") || lowercased.contains("todo") || lowercased.contains("tasks") || lowercased.contains("steps") {
            return CanvasPromptInterpretation(kind: .checklist, content: conciseSubject(normalized), date: nil, location: nil)
        }
        if lowercased.contains("quote") || lowercased.contains("saying") || lowercased.contains("citation") {
            return CanvasPromptInterpretation(kind: .quote, content: conciseSubject(normalized), date: nil, location: nil)
        }
        if lowercased.contains("progress") || lowercased.contains("goal") || lowercased.contains("milestone") || lowercased.contains("track") {
            return CanvasPromptInterpretation(kind: .progress, content: conciseSubject(normalized), date: nil, location: nil)
        }
        if lowercased.contains("palette") || lowercased.contains("colors") || lowercased.contains("colour") {
            return CanvasPromptInterpretation(kind: .palette, content: conciseSubject(normalized), date: nil, location: nil)
        }
        return CanvasPromptInterpretation(kind: .stickyNote, content: normalized, date: nil, location: nil)
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

    private static func eventDate(in prompt: String) -> Date? {
        let pattern = "(?i)(?:at\\s+)?(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm).*?(?:on\\s+)?(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{1,2})(?:st|nd|rd|th)?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)) else { return nil }

        func capture(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: prompt) else { return nil }
            return String(prompt[range])
        }
        guard let hour = Int(capture(1) ?? ""), let meridiem = capture(3), let month = capture(4), let day = Int(capture(5) ?? "") else { return nil }
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: .now)
        components.month = DateFormatter().monthSymbols.firstIndex { $0.caseInsensitiveCompare(month) == .orderedSame }.map { $0 + 1 }
        components.day = day
        components.hour = (hour % 12) + (meridiem.lowercased() == "pm" ? 12 : 0)
        components.minute = Int(capture(2) ?? "0")
        return Calendar.current.date(from: components)
    }
}
