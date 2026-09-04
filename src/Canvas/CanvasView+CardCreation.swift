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
        } else if currentCanvasGridStyle == .bloom {
            // Bloom is an ordered composition, so keep a newly approved image at the next
            // outward point instead of leaving it in the nearest row-major vacancy.
            reflowCards(for: .bloom, appendingCardID: card.id)
        }
        selectedCardID = card.id
        return card
    }

    /// Placement for a newly created card: scan the active lattice from the first content row.
    /// Bloom reserves the next center-out ring slot before insertion; `reflowCards(for:)` then
    /// applies that same order to every body card.
    func placement(for pointSize: CGSize, kind: CardKind) -> (x: Double, y: Double) {
        let firstRowY = kind == .header
            ? Double(CanvasMetrics.headerTopInset)
            : (contentMinimumY(for: kind) ?? Double(CanvasMetrics.canvasMargin))

        if currentCanvasGridStyle == .bloom, kind != .header {
            let bodyCount = board.cards.count(where: {
                $0.isSupportedKind && $0.kind != .header
            })
            let nextSlot = CanvasGridStyle.bloom
                .bloomSlotOrder(count: bodyCount + 1)
                .last
            if let nextSlot {
                let desired = CanvasGridStyle.bloom.bloomOrigin(
                    for: nextSlot,
                    cardSize: pointSize,
                    rowOrigin: firstRowY
                )
                let origin = nearestFreePosition(
                    for: pointSize,
                    nearX: Double(desired.x),
                    nearY: Double(desired.y),
                    kind: kind,
                    style: .bloom
                )
                return (origin.x, origin.y)
            }
        }

        let origin = nearestFreePosition(
            for: pointSize,
            nearX: Double(CanvasMetrics.canvasMargin),
            nearY: firstRowY,
            kind: kind,
            style: currentCanvasGridStyle
        )
        return (origin.x, origin.y)
    }

    /// Finds an active-lattice origin nearest to (`nearX`, `nearY`) that stays inside the fixed
    /// four-column canvas and clears every existing card (except `excluding`). The y-axis
    /// continues indefinitely down the scrollable plane.
    func nearestFreePosition(for pointSize: CGSize,
                                     nearX: Double,
                                     nearY: Double,
                                     excluding: UUID? = nil,
                                     kind: CardKind? = nil,
                                     style: CanvasGridStyle? = nil) -> (x: Double, y: Double) {
        let style = style ?? currentCanvasGridStyle
        let minimumY = kind.flatMap(contentMinimumY(for:))
        let occupiedRects = board.cards.compactMap { card -> CGRect? in
            guard card.id != excluding else { return nil }
            guard card.isSupportedKind else { return nil }
            // Body rows start after the header origin, so the header itself does not impose a
            // second one-dot clearance on top of the explicit 8pt content spacing.
            if kind != .header, card.kind == .header { return nil }
            let size = card.cardSize.pointSize
            return CGRect(x: card.x, y: card.y, width: size.width, height: size.height)
        }
        let origin = CanvasPlacement.nearestFreePosition(
            for: pointSize,
            nearX: nearX,
            nearY: nearY,
            canvasWidth: Double(CanvasMetrics.canvasWidth),
            occupiedRects: occupiedRects,
            minimumY: minimumY,
            style: style
        )
        return (origin.x, origin.y)
    }

    /// Clamps legacy cards to the one-dot horizontal margins. The y-axis remains
    /// unbounded, so only its lower margin needs normalization.
    func constrainToCanvasWidth(_ card: Card) {
        if card.kind == .header {
            card.x = Double(CanvasMetrics.canvasMargin)
            card.y = Double(CanvasMetrics.headerTopInset)
            return
        }
        let style = currentCanvasGridStyle
        let minX = Double(CanvasMetrics.canvasMargin)
        let canvasRight = Double(CanvasMetrics.canvasWidth - CanvasMetrics.canvasMargin)
        let rowOrigin = contentMinimumY(for: card.kind) ?? minX
        let cardWidth = Double(card.cardSize.pointSize.width)

        // Bloom positions are radial rather than row-snapped. Keep their
        // persisted slot intact while still clamping a legacy card to the
        // fixed four-column footprint and the first content row.
        if style == .bloom {
            card.x = min(max(card.x, minX), max(minX, canvasRight - cardWidth))
            card.y = max(card.y, rowOrigin)
            return
        }

        let rowPitch = Double(style.rowPitch)
        let columnPitch = Double(style.columnPitch)
        let row = max(0, Int(((card.y - rowOrigin) / rowPitch).rounded()))
        let rowOffset = Double(style.rowOffset(for: row))
        let rowMinX = minX + rowOffset
        let rowMaxX = max(rowMinX, canvasRight - cardWidth)
        let snappedColumn = ((card.x - rowMinX) / columnPitch).rounded()
        let snappedX = rowMinX + columnPitch * snappedColumn
        let snappedY = rowOrigin + rowPitch * Double(row)
        card.x = min(max(snappedX, rowMinX), rowMaxX)
        card.y = max(snappedY, rowOrigin)
    }

    func normalizeBoardGeometry() {
        refreshCardGeometry()
        normalizeCardPositions()

        guard let headerBottomY else { return }
        clampContentCards(below: headerBottomY + Double(CanvasMetrics.headerContentSpacing))
    }

    private func refreshCardGeometry() {
        for card in board.cards where card.isSupportedKind {
            card.refreshStoredSize()
        }
    }

    private func normalizeCardPositions() {
        for card in board.cards where card.isSupportedKind {
            constrainToCanvasWidth(card)
        }
    }

    /// Repositions body cards onto the active layout. Grid keeps the existing row-major order;
    /// Bloom maps that same source sequence onto center-out rings. Headers remain structural
    /// anchors and are never repositioned by the Bloom layout.
    func reflowCards(for style: CanvasGridStyle, appendingCardID: UUID? = nil) {
        let bodyCards = board.cards
            .filter { $0.isSupportedKind && $0.kind != .header }
        let cards = orderedCardsForReflow(bodyCards, appendingCardID: appendingCardID)
        let rowOrigin = contentMinimumY(for: .image) ?? Double(CanvasMetrics.canvasMargin)
        let bloomSlots = style.bloomSlotOrder(count: max(cards.count + 32, 32))
        var occupiedRects: [CGRect] = []

        for (index, card) in cards.enumerated() {
            let target: (x: Double, y: Double)
            if style == .bloom, index < bloomSlots.count {
                let point = style.bloomOrigin(
                    for: bloomSlots[index],
                    cardSize: card.cardSize.pointSize,
                    rowOrigin: rowOrigin
                )
                target = (Double(point.x), Double(point.y))
            } else {
                target = (Double(CanvasMetrics.canvasMargin), rowOrigin)
            }

            let origin = CanvasPlacement.nearestFreePosition(
                for: card.cardSize.pointSize,
                nearX: target.x,
                nearY: target.y,
                canvasWidth: Double(CanvasMetrics.canvasWidth),
                occupiedRects: occupiedRects,
                minimumY: rowOrigin,
                style: style
            )
            card.x = origin.x
            card.y = origin.y
            occupiedRects.append(
                CGRect(
                    x: card.x,
                    y: card.y,
                    width: card.cardSize.pointSize.width,
                    height: card.cardSize.pointSize.height
                )
            )
        }
    }

    private func orderedCardsForReflow(_ cards: [Card], appendingCardID: UUID? = nil) -> [Card] {
        if let appendingCardID,
           let appendedCard = cards.first(where: { $0.id == appendingCardID }) {
            let existingCards = cards.filter { $0.id != appendingCardID }
            let orderedExisting = existingBloomOrder(of: existingCards)
                ?? existingCards.sorted(by: rowMajorCardOrder)
            return orderedExisting + [appendedCard]
        }

        // When a Bloom layout is already persisted, use its ring rank as the source order.
        // This keeps toggling between Grid and Bloom from reshuffling the canvas.
        if let bloomOrder = existingBloomOrder(of: cards) {
            return bloomOrder
        }

        return cards.sorted(by: rowMajorCardOrder)
    }

    private func rowMajorCardOrder(_ lhs: Card, _ rhs: Card) -> Bool {
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        if lhs.x != rhs.x { return lhs.x < rhs.x }
        return lhs.zIndex < rhs.zIndex
    }

    private func existingBloomOrder(of cards: [Card]) -> [Card]? {
        guard !cards.isEmpty else { return [] }

        let style = CanvasGridStyle.bloom
        let rowOrigin = contentMinimumY(for: .image) ?? Double(CanvasMetrics.canvasMargin)
        let slots = style.bloomSlotOrder(count: max(cards.count + 32, 32))
        var rankedCards: [(card: Card, rank: Int)] = []
        var occupiedSlots = Set<CanvasBloomSlot>()

        for card in cards {
            let match = slots.enumerated().first { rank, slot in
                guard !occupiedSlots.contains(slot) else { return false }
                let expected = style.bloomOrigin(
                    for: slot,
                    cardSize: card.cardSize.pointSize,
                    rowOrigin: rowOrigin
                )
                return abs(card.x - Double(expected.x)) < 1
                    && abs(card.y - Double(expected.y)) < 1
            }
            guard let (rank, slot) = match else { return nil }

            occupiedSlots.insert(slot)
            rankedCards.append((card, rank))
        }

        return rankedCards.sorted { $0.rank < $1.rank }.map(\.card)
    }

    private func clampContentCards(below minimumContentY: Double) {
        for card in board.cards where card.isSupportedKind && card.kind != .header {
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
            .map { $0.y + Double($0.cardSize.pointSize.height) }
            .max()
    }

    func contentMinimumY(for kind: CardKind) -> Double? {
        guard kind != .header, let headerBottomY else { return nil }
        return headerBottomY + Double(CanvasMetrics.headerContentSpacing)
    }

    func requestNewCard(_ kind: CardKind) {
        guard kind == .image else { return }
        imageTargetCardID = nil
        showImageImporter = true
    }
}
