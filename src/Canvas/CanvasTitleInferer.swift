import Foundation

enum CanvasTitleInferer {
    static func title(for prompt: String, interpretation: CanvasPromptInterpretation) -> String {
        if interpretation.kind == .calendar {
            if let location = interpretation.location, !location.isEmpty {
                return "\(location) Schedule"
            }
            return "Upcoming Schedule"
        }

        switch interpretation.kind {
        case .checklist: return "Action Plan"
        case .progress: return "Progress Tracker"
        case .palette: return "Color Studies"
        case .quote: return "Quotes & References"
        default: break
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
