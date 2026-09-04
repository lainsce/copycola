import Foundation

extension CardKind {
    var displayName: LocalizedStringResource {
        switch self {
        case .header: "Header"
        case .image: "Image"
        }
    }

    var systemImage: String {
        switch self {
        case .header: "textformat.size.larger"
        case .image: "photo"
        }
    }
}
