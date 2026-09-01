import Foundation

extension CardKind {
    /// The footprint a freshly created card of this kind starts at.
    var defaultCardSize: CardSize {
        switch self {
        case .header: .fourByOne
        case .stickyNote: .oneByOne
        case .image: .oneByOne
        case .link: .oneByOne
        case .map: .oneByOne
        }
    }
}
