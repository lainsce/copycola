import Foundation

extension CardKind {
    /// The footprint a freshly created card of this kind starts at.
    var defaultCardSize: CardSize {
        switch self {
        case .header: .fourByOne
        case .image: .oneByOne
        }
    }
}
