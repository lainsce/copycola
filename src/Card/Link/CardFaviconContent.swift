import SwiftUI

/// Decodes link icon data asynchronously and caches it in view-local state.
struct CardFaviconContent: View {
    let card: Card
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .saturation(0)
            } else {
                ZStack {
                    CopycoaColors.itemSurface
                        .overlay(Color.accent.opacity(0.10))
                    Image(systemName: "globe")
                        .foregroundStyle(.primary)
                }
            }
        }
        .background(CopycoaColors.itemSurface)
        .task(id: card.faviconRevision) {
            image = await decodeImage(from: card.faviconData)
        }
        .accessibilityHidden(true)
    }
}
