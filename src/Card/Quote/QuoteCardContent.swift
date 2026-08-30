import SwiftUI

struct QuoteCardContent: View {
    @Bindable var card: Card

    var body: some View {
        GeometryReader { proxy in
            let metrics = QuoteCardMetrics(size: proxy.size)

            ZStack(alignment: .topLeading) {
                Text(verbatim: "“")
                    .font(CopycoaTypography.display)
                    .foregroundStyle(Color.accent.opacity(0.42))
                    .offset(x: metrics.quoteMarkOffset, y: -metrics.quoteMarkOffset / 2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                    Spacer(minLength: metrics.quoteMarkFont * 0.38)

                    Text(verbatim: card.quoteTextValue)
                        .font(CopycoaTypography.viewSubtitle)
                        .italic()
                        .foregroundStyle(.primary)
                        .lineSpacing(metrics.lineSpacing)
                        .lineLimit(metrics.lineLimit)
                        .minimumScaleFactor(0.65)

                    if !card.quoteAttributionValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("— \(card.quoteAttributionValue)")
                            .font(CopycoaTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer(minLength: 0)
                }
                .padding(metrics.inset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            RoundedRectangle(cornerRadius: card.cardSize.cornerRadius, style: .continuous)
                .fill(CardSurfaceStyle.item)
        }
        .clipShape(.rect(cornerRadius: card.cardSize.cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Quote"))
        .accessibilityValue(Text(accessibilityValue))
    }

    private var accessibilityValue: String {
        let attribution = card.quoteAttributionValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return attribution.isEmpty ? card.quoteTextValue : "\(card.quoteTextValue), \(attribution)"
    }
}

private struct QuoteCardMetrics {
    let size: CGSize

    var scale: CGFloat {
        max(0.75, min(size.width / CanvasMetrics.footprintSize(columns: 2, rows: 1).width, size.height / CanvasMetrics.cell))
    }

    var inset: CGFloat { CanvasMetrics.cardContentInset }
    var sectionSpacing: CGFloat { max(8, 10 * scale) }
    var quoteMarkFont: CGFloat { CopycoaTypography.Role.display.size }
    var quoteMarkOffset: CGFloat { max(3, 8 * scale) }
    var quoteFont: CGFloat { CopycoaTypography.Role.viewSubtitle.size }
    var attributionFont: CGFloat { CopycoaTypography.Role.caption.size }
    var lineSpacing: CGFloat { max(1, 2 * scale) }
    var lineLimit: Int { size.width >= 300 ? 4 : 3 }
}
