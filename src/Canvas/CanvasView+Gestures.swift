import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension CanvasView {
    // MARK: - Gestures

    func dragChanged(_ card: Card, translation: CGSize) {
        guard card.kind != .header else { return }
        if draggingCardID != card.id {
            draggingCardID = card.id
            bringToFront(card)
            select(card)
        }
        dragTranslation = translation
        dropPreview = landingRect(for: card, translation: translation)
    }

    func dragEnded(_ card: Card, translation: CGSize) {
        guard card.kind != .header else { return }
        let landing = landingRect(for: card, translation: translation)
        card.x = landing.minX
        card.y = landing.minY
        draggingCardID = nil
        dragTranslation = .zero
        dropPreview = nil
    }

    /// The active-lattice, collision-free rect a dragged card will land in.
    func landingRect(for card: Card, translation: CGSize) -> CGRect {
        let size = card.cardSize.pointSize
        let origin = nearestFreePosition(
            for: size,
            nearX: card.x + translation.width,
            nearY: card.y + translation.height,
            excluding: card.id,
            kind: card.kind
        )
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }

    var dropPreviewCornerRadius: CGFloat {
        guard let draggingCardID,
              let card = board.cards.first(where: { $0.id == draggingCardID }) else {
            return CanvasMetrics.cardCornerRadius
        }
        return card.cardSize.cornerRadius
    }

    /// The content grows with the lowest card while remaining at least as tall as the viewport.
    /// This gives the scroll view an effectively unbounded y-axis without creating a huge blank
    /// document when a board is still empty.
    var canvasHeight: CGFloat {
        let lowestCard = board.cards
            .filter { $0.isSupportedKind }
            .map { CGFloat($0.y) + $0.cardSize.pointSize.height }
            .max() ?? 0
        let lowestPreview = dropPreview?.maxY ?? 0
        let selectedCardBottom: CGFloat = {
            guard let selectedCardID,
                  let selectedCard = board.cards.first(where: { $0.id == selectedCardID }),
                  selectedCard.kind != .header else { return 0 }
            return CGFloat(selectedCard.y) + selectedCard.cardSize.pointSize.height + 64
        }()
        let bottom = max(lowestCard, max(lowestPreview, selectedCardBottom)) + CanvasMetrics.canvasMargin
        return max(1, max(viewportSize.height, bottom))
    }

    /// The lattice background follows the window width; card placement remains constrained to
    /// the fixed four-column area inside it.
    var canvasContentWidth: CGFloat {
        max(CanvasMetrics.canvasWidth, viewportSize.width)
    }

}
