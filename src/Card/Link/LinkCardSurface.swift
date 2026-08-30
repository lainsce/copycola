import SwiftUI

/// The link card's favicon and metadata hierarchy on the shared Item surface.
struct LinkCardSurface: View {
    let card: Card
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardFaviconContent(card: card)
                .frame(width: 40, height: 40)
                .clipShape(.rect(cornerRadius: CopycoaColors.largeSurfaceRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius)
                        .strokeBorder(CopycoaColors.itemRule(for: colorScheme).opacity(0.35), lineWidth: 1)
                }

            Spacer(minLength: CanvasMetrics.gridUnit / 5)

            Text(verbatim: card.title ?? card.urlString ?? String(localized: "Link"))
                .font(CopycoaTypography.contentBlockTitle)
                .foregroundStyle(.primary)
                .lineLimit(card.cardSize == .oneByOne ? 1 : 2)
            if let host = URL(string: card.urlString ?? "")?.host {
                Text(verbatim: host)
                    .font(CopycoaTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.top, CanvasMetrics.gridUnit / 10)
            }
            if let detail = card.detail, !detail.isEmpty {
                Text(verbatim: detail)
                    .font(CopycoaTypography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(card.cardSize == .oneByOne ? 2 : 3)
                    .padding(.top, CanvasMetrics.gridUnit / 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(CanvasMetrics.cardContentInset)
        .background(linkCardSurface)
    }

    private var linkCardSurface: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(CopycoaColors.itemSurface)
    }
}
