import Foundation

enum CanvasTitleInferer {
    static func title(for prompt: String, interpretation: CanvasPromptInterpretation) -> String {
        switch interpretation.kind {
        case .map:
            if let location = interpretation.location, !location.isEmpty {
                return "\(location) Places"
            }
            return "Places & Context"
        case .link:
            if let host = URL(string: prompt.trimmingCharacters(in: .whitespacesAndNewlines))?.host,
               !host.isEmpty {
                return host.replacingOccurrences(of: "www.", with: "")
            }
        case .image:
            return "Visual Notes"
        case .header, .stickyNote:
            break
        }

        let firstThought = prompt
            .split(whereSeparator: { $0 == "." || $0 == "\n" })
            .first.map(String.init) ?? prompt
        let cleaned = firstThought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "Untitled Canvas" }
        if cleaned.count <=  thirtyTwoCharacters { return cleaned }
        return String(cleaned.prefix(thirtyTwoCharacters)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private static let thirtyTwoCharacters = 32
}
