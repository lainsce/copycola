import Foundation

extension CardKind {
    var displayName: LocalizedStringResource {
        switch self {
        case .header: "Header"
        case .stickyNote: "Note"
        case .image: "Image"
        case .link: "Link"
        case .map: "Map"
        }
    }

    var systemImage: String {
        switch self {
        case .header: "textformat.size.larger"
        case .stickyNote: "note.text"
        case .image: "photo"
        case .link: "link"
        case .map: "mappin.and.ellipse"
        }
    }
}
