import SwiftUI
import SwiftData

extension CanvasView {
    // MARK: - Selection

    func select(_ card: Card) {
        selectedCardID = card.id
        if editingCardID != card.id { editingCardID = nil }
    }

    func beginEditing(_ card: Card) {
        // Headers edit their title; images edit their caption.
        guard card.isSupportedKind else { return }
        selectedCardID = card.id
        editingCardID = card.id
    }

    func editLink(_ card: Card) {
        guard card.isSupportedKind, card.kind == .image else { return }
        linkTargetCardID = card.id
        showLinkSheet = true
    }

    func edit(_ card: Card) {
        select(card)
        switch card.kind {
        case .header, .image:
            beginEditing(card)
        }
    }

    var editSelectedCardAction: (() -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { editSelectedCard() }
    }

    func editSelectedCard() {
        guard let card = targetCard(selectedCardID) else { return }
        edit(card)
    }

    var deleteSelectedCardAction: (() -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { deleteSelectedCard() }
    }

    func deleteSelectedCard() {
        guard let card = targetCard(selectedCardID) else { return }
        requestDelete(card)
    }

    func accessibilitySummary(for card: Card) -> String {
        card.kind == .image
            ? (card.text.isEmpty ? (card.urlString ?? "") : card.text)
            : card.text
    }

    func nudge(_ card: Card, x deltaX: Double, y deltaY: Double) {
        let requestedX = card.x + deltaX
        let requestedY = card.y + deltaY
        let origin = nearestFreePosition(
            for: card.cardSize.pointSize,
            nearX: requestedX,
            nearY: requestedY,
            excluding: card.id,
            kind: card.kind
        )
        guard abs(origin.x - requestedX) < 0.5, abs(origin.y - requestedY) < 0.5 else { return }
        card.x = origin.x
        card.y = origin.y
        bringToFront(card)
        select(card)
    }

    func clearSelection() {
        selectedCardID = nil
        editingCardID = nil
    }

    func bringToFront(_ card: Card) {
        let top = board.cards.map(\.zIndex).max() ?? 0
        card.zIndex = top + 1
    }

    func requestDelete(_ card: Card) {
        cardToDeleteID = card.id
        showingDeleteConfirmation = true
    }

    func deletePendingCard() {
        guard let cardToDeleteID,
              let card = board.cards.first(where: { $0.id == cardToDeleteID }) else { return }
        if selectedCardID == card.id { clearSelection() }
        context.delete(card)
        self.cardToDeleteID = nil
    }

}
