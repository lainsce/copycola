import SwiftUI

/// A fixed-size stack of generic card previews for a canvas row.
/// Each preview keeps the 64×72 design unit while abstracting the card's actual content.
struct SidebarCanvasThumbnail: View {
    let cards: [Card]
    let isSelected: Bool

    private enum Metrics {
        static let cardWidth: CGFloat = 64
        static let cardHeight: CGFloat = 72
        static let cardCornerRadius: CGFloat = 10
        static let stackWidth: CGFloat = 76
        static let stackHeight: CGFloat = 84
    }

    private var previewCards: [Card] {
        Array(
            cards
                .filter { $0.kind != .header }
                .prefix(3)
        )
    }

    var body: some View {
        ZStack {
            if previewCards.isEmpty {
                emptyCanvasCard
            } else {
                ForEach(Array(previewCards.enumerated()), id: \.element.id) { index, card in
                    miniatureCard(for: card)
                        .rotationEffect(.degrees(cardRotation(for: index)))
                        .offset(cardOffset(for: index))
                }
            }
        }
        .frame(width: Metrics.stackWidth, height: Metrics.stackHeight)
        .accessibilityHidden(true)
    }

    private var emptyCanvasCard: some View {
        // This is an empty-state affordance, not a card surface: keep it flat and
        // reserve the dotted outline for the add cue only.
        RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous)
            .fill(.primary.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous)
                    .strokeBorder(
                        .secondary.opacity(0.42),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
            }
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.72))
            }
            .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
    }

    private func miniatureCard(for card: Card) -> some View {
        SidebarCardPreviewArtwork(kind: card.kind)
            // Keep the rendered card surface inside its fixed design unit. The
            // stack can still rotate/offset that unit without its contents
            // growing to match the source card's actual footprint.
            .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if card.kind == .image, card.urlString != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.black.opacity(0.20), in: Circle())
                        .overlay {
                            Circle().strokeBorder(.white.opacity(0.20), lineWidth: 1.5)
                        }
                        .padding(CopycoaColors.controlGap)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: Metrics.cardCornerRadius,
                        style: .continuous
                    )
                    .strokeBorder(Color.accent.opacity(0.40), lineWidth: 0.75)
                }
            }
    }

    private func cardOffset(for index: Int) -> CGSize {
        switch index {
        case 0: CGSize(width: -4, height: -6)
        case 1: CGSize(width: 0, height: 0)
        default: CGSize(width: 4, height: 6)
        }
    }

    private func cardRotation(for index: Int) -> Double {
        switch index {
        case 0: -5
        case 1: 2
        default: 5
        }
    }

}
