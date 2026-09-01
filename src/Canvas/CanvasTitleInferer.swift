import Foundation

enum CanvasTitleInferer {
    static func title(for prompt: String, interpretation: CanvasPromptInterpretation) -> String {
        if interpretation.kind == .map {
            return mapTitle(for: interpretation.location)
        }
        if interpretation.kind == .link {
            return linkOrGenericTitle(for: prompt)
        }
        if interpretation.kind == .image {
            return "Visual Notes"
        }

        return genericTitle(for: prompt)
    }

    private static func mapTitle(for location: String?) -> String {
        guard let location, !location.isEmpty else { return "Places & Context" }
        return "\(location) Places"
    }

    private static func linkTitle(for prompt: String) -> String? {
        guard let host = URL(string: prompt.trimmingCharacters(in: .whitespacesAndNewlines))?.host,
              !host.isEmpty else {
            return nil
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private static func linkOrGenericTitle(for prompt: String) -> String {
        if let linkTitle = linkTitle(for: prompt) {
            return linkTitle
        }
        return genericTitle(for: prompt)
    }

    private static func genericTitle(for prompt: String) -> String {
        let firstThought = firstThought(in: prompt)
        let cleaned = firstThought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "Untitled Canvas" }
        if cleaned.count <=  thirtyTwoCharacters { return cleaned }
        return String(cleaned.prefix(thirtyTwoCharacters)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private static func firstThought(in prompt: String) -> String {
        prompt
            .split(whereSeparator: { $0 == "." || $0 == "\n" })
            .first.map(String.init) ?? prompt
    }

    private static let thirtyTwoCharacters = 32
}
