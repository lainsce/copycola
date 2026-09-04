import Foundation

/// The kinds of cards a user can place on a board.
nonisolated enum CardKind: String, Codable, CaseIterable, Identifiable {
    case header
    case image

    var id: String { rawValue }

    /// Headers are structural and are inserted automatically for every canvas.
    static let creatable: [CardKind] = [.image]

    var isCreatable: Bool {
        Self.creatable.contains(self)
    }
}
