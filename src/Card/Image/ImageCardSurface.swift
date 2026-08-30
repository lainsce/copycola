import SwiftUI

/// Composes the image payload, optional caption, and optional outbound-link affordance.
struct ImageCardSurface: View {
    @Bindable var card: Card
    let isEditing: Bool
    let cornerRadius: CGFloat

    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CardImageContent(card: card)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            if isEditing {
                captionField
                    .padding(CanvasMetrics.cardContentInset)
            } else if !card.text.isEmpty {
                CardCaptionPill(text: card.text)
                    .padding(CanvasMetrics.cardContentInset)
            }

            if imageLinkURL != nil {
                imageLinkIndicator
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .onChange(of: isEditing) { _, editing in
            focused = editing
        }
    }

    private var imageLinkURL: URL? {
        guard let urlString = card.urlString else { return nil }
        return normalizedURL(urlString)
    }

    private var imageLinkIndicator: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background {
                Circle()
                    .fill(.black.opacity(0.2))
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                    }
            }
            .accessibilityLabel(Text("Image Link"))
            .accessibilityAddTraits(.isImage)
            .allowsHitTesting(false)
    }

    private var captionField: some View {
        TextField("Caption", text: $card.text)
            .textFieldStyle(.plain)
            .font(CopycoaTypography.caption)
            .foregroundStyle(.primary)
            .focused($focused)
            .frame(maxWidth: 180)
            .padding(.horizontal, CopycoaColors.fieldHorizontalPadding)
            .padding(.vertical, CopycoaColors.gridUnit * 2)
            .background {
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius)
                    .fill(CopycoaColors.itemSurface.opacity(0.96))
                    .padding(1)
            }
    }
}
