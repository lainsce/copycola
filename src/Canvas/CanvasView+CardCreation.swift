import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension CanvasView {
    // MARK: - Creating cards

    func newCard(_ kind: CardKind) -> Card {
        let size = kind.defaultCardSize
        let origin = placement(for: size.pointSize, kind: kind)
        let card = Card(
            kind: kind,
            size: size,
            x: origin.x,
            y: origin.y,
            zIndex: (board.cards.map(\.zIndex).max() ?? 0) + 1
        )
        context.insert(card)
        card.board = board
        board.cards.append(card)
        if kind == .header {
            normalizeBoardGeometry()
        }
        selectedCardID = card.id
        return card
    }

    /// Placement for a newly created card: scan the plane row-first from the first content row,
    /// filling columns left-to-right before advancing to the next row.
    func placement(for pointSize: CGSize, kind: CardKind) -> (x: Double, y: Double) {
        let firstRowY = kind == .header
            ? Double(CanvasMetrics.headerTopInset)
            : (contentMinimumY(for: kind) ?? Double(CanvasMetrics.canvasMargin))
        let origin = nearestFreePosition(
            for: pointSize,
            nearX: Double(CanvasMetrics.canvasMargin),
            nearY: firstRowY,
            kind: kind
        )
        return (origin.x, origin.y)
    }

    /// Finds a grid-aligned origin nearest to (`nearX`, `nearY`) that stays inside the fixed
    /// four-column canvas and clears every existing card (except `excluding`) by at least one
    /// dot. Both axes use the module lattice and continue indefinitely down the scrollable
    /// y-axis.
    func nearestFreePosition(for pointSize: CGSize,
                                     nearX: Double,
                                     nearY: Double,
                                     excluding: UUID? = nil,
                                     kind: CardKind? = nil) -> (x: Double, y: Double) {
        let minimumY = kind.flatMap(contentMinimumY(for:))
        let occupiedRects = board.cards.compactMap { card -> CGRect? in
            guard card.id != excluding else { return nil }
            // Body rows start after the header origin, so the header itself does not impose a
            // second one-dot clearance on top of the explicit 8pt content spacing.
            if kind != .header, card.kind == .header { return nil }
            return CGRect(x: card.x, y: card.y, width: card.width, height: card.height)
        }
        let origin = CanvasPlacement.nearestFreePosition(
            for: pointSize,
            nearX: nearX,
            nearY: nearY,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: occupiedRects,
            minimumY: minimumY
        )
        return (origin.x, origin.y)
    }

    /// Clamps legacy or resized cards to the one-dot horizontal margins. The y-axis remains
    /// unbounded, so only its lower margin needs normalization.
    func constrainToCanvasWidth(_ card: Card) {
        if card.kind == .header {
            card.x = Double(CanvasMetrics.canvasMargin)
            card.y = Double(CanvasMetrics.headerTopInset)
            return
        }
        let minX = Double(CanvasMetrics.canvasMargin)
        let maxX = max(minX, Double(CanvasMetrics.canvasWidth - CanvasMetrics.canvasMargin) - card.width)
        let snappedX = minX + Double(CanvasMetrics.module) * ((card.x - minX) / Double(CanvasMetrics.module)).rounded()
        let rowOrigin = contentMinimumY(for: card.kind) ?? minX
        let snappedY = rowOrigin + Double(CanvasMetrics.module) * ((card.y - rowOrigin) / Double(CanvasMetrics.module)).rounded()
        card.x = min(max(snappedX, minX), maxX)
        card.y = max(snappedY, rowOrigin)
    }

    func normalizeBoardGeometry() {
        refreshCardGeometry()
        normalizeCardPositions()

        guard let headerBottomY else { return }
        clampContentCards(below: headerBottomY + Double(CanvasMetrics.headerContentSpacing))
    }

    private func refreshCardGeometry() {
        for card in board.cards {
            card.refreshStoredSize()
        }
    }

    private func normalizeCardPositions() {
        for card in board.cards {
            constrainToCanvasWidth(card)
        }
    }

    private func clampContentCards(below minimumContentY: Double) {
        for card in board.cards where card.kind != .header {
            card.y = max(card.y, minimumContentY)
        }
    }

    /// Every canvas gets one structural header anchored to the top of the plane. It sits behind
    /// later cards in the persisted z-order while remaining part of the same grid.
    @discardableResult
    func ensureCanvasHeader() -> Card {
        if let existing = board.cards.first(where: { $0.kind == .header }) {
            constrainToCanvasWidth(existing)
            existing.zIndex = max(existing.zIndex, 1)
            return existing
        }
        let size = CardKind.header.defaultCardSize
        let header = Card(
            kind: .header,
            size: size,
            x: Double(CanvasMetrics.canvasMargin),
            y: Double(CanvasMetrics.headerTopInset),
            zIndex: 1
        )
        header.text = board.name
        context.insert(header)
        header.board = board
        board.cards.append(header)
        return header
    }

    var headerBottomY: Double? {
        board.cards
            .filter { $0.kind == .header }
            .map { $0.y + $0.height }
            .max()
    }

    func contentMinimumY(for kind: CardKind) -> Double? {
        guard kind != .header, let headerBottomY else { return nil }
        return headerBottomY + Double(CanvasMetrics.headerContentSpacing)
    }

    func addSimpleCard(_ kind: CardKind) {
        let card = newCard(kind)
        if kind == .header || kind == .stickyNote {
            editingCardID = card.id
        }
    }

    func submitCanvasPrompt() {
        let prompt = canvasPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        let interpretation = CanvasAIRecon.shared.interpret(prompt)
        let supportedKind = interpretation.kind.isCreatable ? interpretation.kind : .stickyNote
        let canvasTitle = CanvasTitleInferer.title(for: prompt, interpretation: interpretation)
        board.name = canvasTitle
        let header = ensureCanvasHeader()
        header.text = canvasTitle
        normalizeBoardGeometry()
        let card = newCard(supportedKind)
        applyPromptContent(interpretation.content, to: card, kind: supportedKind)
        canvasPrompt = ""
        scheduleLocationContext(for: interpretation.location)
    }

    private func applyPromptContent(_ content: String, to card: Card, kind: CardKind) {
        card.text = content
        switch kind {
        case .header, .stickyNote, .image:
            editingCardID = card.id
        default:
            break
        }
    }

    private func scheduleLocationContext(for location: String?) {
        guard let location else { return }
        Task { @MainActor in
            await setupLocationContext(location)
        }
    }

    /// A location-bearing request sets up the useful spatial context around the event.
    func setupLocationContext(_ query: String) async {
        guard let found = try? await searchLocation(query) else { return }

        let map = newCard(.map)
        map.title = found.name
        map.latitude = found.latitude
        map.longitude = found.longitude
    }

    func requestNewCard(_ kind: CardKind) {
        showingCardOptions = false
        guard kind.isCreatable else { return }
        guard !requestSpecialCard(kind) else { return }
        addSimpleCard(kind)
    }

    private func requestSpecialCard(_ kind: CardKind) -> Bool {
        if kind == .image {
            imageTargetCardID = nil
            showImageImporter = true
            return true
        }
        if kind == .link {
            linkTargetCardID = nil
            showLinkSheet = true
            return true
        }
        if kind == .map {
            mapTargetCardID = nil
            showMapSheet = true
            return true
        }
        return false
    }
}
