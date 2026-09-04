import Foundation

extension CardKind {
    var editActionName: LocalizedStringResource {
        switch self {
        case .header: "Edit Header"
        case .image: "Edit Caption"
        }
    }
}
