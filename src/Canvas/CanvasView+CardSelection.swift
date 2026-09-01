import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension CanvasView {
    // MARK: - Selection

    func select(_ card: Card) {
        selectedCardID = card.id
        if editingCardID != card.id { editingCardID = nil }
    }

    func beginEditing(_ card: Card) {
        // Header/sticky edit their text; image edits its caption.
        guard card.kind == .header || card.kind == .stickyNote || card.kind == .image else { return }
        selectedCardID = card.id
        editingCardID = card.id
    }

    func chooseImage(for card: Card) {
        imageTargetCardID = card.id
        showImageImporter = true
    }

    func cropImageToSubject(for card: Card) {
        guard card.kind == .image, let data = card.imageData else { return }
        Task { @MainActor in
            let cropped = await Task.detached(priority: .userInitiated) {
                ImageSubjectCropper.crop(data: data)
            }.value
            guard let cropped, !card.isDeleted else { return }
            card.imageData = cropped
            card.imageRevision = UUID()
        }
    }

    func editLink(_ card: Card) {
        linkTargetCardID = card.id
        showLinkSheet = true
    }

    func editLocation(_ card: Card) {
        mapTargetCardID = card.id
        showMapSheet = true
    }

    func edit(_ card: Card) {
        select(card)
        switch card.kind {
        case .header, .stickyNote, .image:
            beginEditing(card)
        case .link:
            linkTargetCardID = card.id
            showLinkSheet = true
        case .map:
            mapTargetCardID = card.id
            showMapSheet = true
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

    var resizeSelectedCardAction: ((CardSize) -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { size in resizeSelectedCard(size) }
    }

    func resizeSelectedCard(_ size: CardSize) {
        guard let card = targetCard(selectedCardID), card.kind != .header else { return }
        setCardSize(size, for: card)
    }

    func setCardSize(_ size: CardSize, for card: Card) {
        card.cardSize = size
        constrainToCanvasWidth(card)
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
        if card.kind == .link {
            return linkAccessibilitySummary(for: card)
        }
        if card.kind == .map {
            return card.title ?? ""
        }
        return card.text
    }

    private func linkAccessibilitySummary(for card: Card) -> String {
        card.title ?? card.urlString ?? ""
    }

    func nudge(_ card: Card, x deltaX: Double, y deltaY: Double) {
        let requestedX = card.x + deltaX
        let requestedY = card.y + deltaY
        let origin = nearestFreePosition(
            for: CGSize(width: card.width, height: card.height),
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
        showingCardOptions = false
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
