import Foundation

extension CardKind {
    var editActionName: LocalizedStringResource {
        switch self {
        case .header: "Edit Header"
        case .stickyNote: "Edit Note"
        case .image: "Edit Caption"
        case .link: "Edit Link"
        case .map: "Edit Map Location"
        }
    }
}
