import SwiftUI

/// Legacy note-color values kept for lightweight migration. New notes use the
/// same restrained Item/mono palette as every other card.
nonisolated enum StickyPalette {
    static let accent = "AC7721"
    /// Source-compatible name for stores created before the Nuul treatment.
    static let yellow = accent
    static let all = [accent, "F2F2F2", "E4E4E4", "BDBDBD", "747474", "111111"]

    static func name(for colorHex: String) -> LocalizedStringResource {
        switch colorHex {
        case accent: "Accent"
        case "F2F2F2": "Light Gray"
        case "E4E4E4": "Quiet Gray"
        case "BDBDBD": "Mid Gray"
        case "747474": "Graphite"
        case "111111": "Ink"
        default: "Note Color"
        }
    }
}
