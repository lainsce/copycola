import Foundation

/// The kinds of cards a user can place on a board.
nonisolated enum CardKind: String, Codable, CaseIterable, Identifiable {
    case header
    case stickyNote
    case image
    case link
    case map

    var id: String { rawValue }

    /// The intentionally small set of card types users can create. Headers are structural
    /// and are inserted automatically for every canvas.
    static let creatable: [CardKind] = [.link, .image, .stickyNote, .map]

    var isCreatable: Bool {
        Self.creatable.contains(self)
    }
}
