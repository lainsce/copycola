import SwiftUI

/// Supplies the generated, type-specific face used by a sidebar card miniature.
struct SidebarCardPreviewArtwork: View {
    let kind: CardKind

    private var resource: ImageResource? {
        switch kind {
        case .header:
            nil
        case .image:
            .sidebarPreview
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
