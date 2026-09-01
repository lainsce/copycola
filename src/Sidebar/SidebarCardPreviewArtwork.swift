import SwiftUI

/// Supplies the generated, type-specific face used by a sidebar card miniature.
struct SidebarCardPreviewArtwork: View {
    let kind: CardKind

    private var resource: ImageResource? {
        switch kind {
        case .header:
            nil
        case .stickyNote:
            .sidebarPreviewStickyNote
        case .image:
            .sidebarPreview
        case .link:
            .sidebarPreviewLink
        case .map:
            .sidebarPreviewMap
        }
    }

    var body: some View {
        if let resource {
            Image(resource)
                .resizable()
                .scaledToFill()
                .saturation(0)
        }
    }
}
