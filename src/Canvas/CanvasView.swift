import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct CanvasScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

    /// The fixed-column card surface: draws a viewport-sized technical grid, positions cards, and
/// handles vertical scrolling, card dragging with grid + magnetic snapping, and card creation.
struct CanvasView: View {
    @Bindable var board: Board
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCardID: UUID?
    @State private var editingCardID: UUID?
    @State private var draggingCardID: UUID?
    @State private var dragTranslation: CGSize = .zero
    /// Where the currently dragged card will land, in content space (for the drop-preview ghost).
    @State private var dropPreview: CGRect?
    @State private var viewportSize: CGSize = .zero
    @State private var scrollOffset: CGFloat = .zero

    private let scrollCoordinateSpace = "canvas-scroll"

    // Add-card flows. A non-nil target id means the flow edits that existing card
    // instead of creating a new one.
    @State private var showImageImporter = false
    @State private var showLinkSheet = false
    @State private var showMapSheet = false
    @State private var showingCardOptions = false
    @State private var imageTargetCardID: UUID?
    @State private var linkTargetCardID: UUID?
    @State private var mapTargetCardID: UUID?
    @State private var presentedError: CanvasError?
    @State private var cardToDeleteID: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var canvasPrompt = ""
    @StateObject private var voiceRecorder = CanvasVoiceRecorder()

    var body: some View {
        canvasWithCommands
    }

    private var canvasWithCommands: some View {
        canvasWithSheets
            .alert(error: $presentedError) { _ in
            } message: { error in
                if let reason = error.failureReason {
                    Text(verbatim: reason)
                }
            }
            .confirmationDialog(
                "Delete Card?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationActions
            } message: {
                Text("This cannot be undone.")
            }
            .onChange(of: showingDeleteConfirmation) { _, isPresented in
                if !isPresented { cardToDeleteID = nil }
            }
            .focusedSceneValue(\.addCardAction) { kind in
                requestNewCard(kind)
            }
            .focusedSceneValue(\.editCardAction, editSelectedCardAction)
            .focusedSceneValue(\.resizeCardAction, resizeSelectedCardAction)
            .focusedSceneValue(\.deleteCardAction, deleteSelectedCardAction)
            .toolbar {
                ToolbarSpacer(placement: .navigation)
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .primaryAction) {
                    AddCardFanView(
                        isExpanded: $showingCardOptions,
                        addCard: requestNewCard
                    )
                }
                .sharedBackgroundVisibility(.hidden)
            }
    }

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button("Delete Card", role: .destructive, action: deletePendingCard)
        Button("Cancel", role: .cancel) { cardToDeleteID = nil }
    }

    private var canvasWithSheets: some View {
        canvasViewport
            .fileImporter(isPresented: $showImageImporter, allowedContentTypes: [.image]) { result in
                handleImageImport(result)
            }
            .sheet(isPresented: $showLinkSheet, onDismiss: {
                linkTargetCardID = nil
            }) {
                linkEntrySheet
            }
            .sheet(isPresented: $showMapSheet, onDismiss: {
                mapTargetCardID = nil
            }) {
                mapEntrySheet
            }
    }

    private var canvasViewport: some View {
        canvasScrollView
            .coordinateSpace(name: scrollCoordinateSpace)
            .scrollIndicators(.automatic)
            .onPreferenceChange(CanvasScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
            // Let the viewport claim the remaining detail-pane width; the content frame above
            // then receives the true window width instead of stopping at its 4-column minimum.
            .frame(
                minWidth: CanvasMetrics.canvasWidth,
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
            .overlay(alignment: .bottom) {
                CanvasPromptComposer(
                    text: $canvasPrompt,
                    submit: submitCanvasPrompt,
                    recorder: voiceRecorder
                )
                .padding(.bottom, 20)
            }
            .clipped()
            .onAppear {
                ensureCanvasHeader()
                normalizeBoardGeometry()
            }
    }

    private var linkEntrySheet: some View {
        let target = targetCard(linkTargetCardID)
        let editing = target != nil
        let title: LocalizedStringResource = if editing && target?.kind == .image {
            "Edit Image Link"
        } else if editing {
            "Edit Website Link"
        } else {
            "Add Website Link"
        }
        let submitTitle: LocalizedStringResource = editing ? "Save" : "Add"

        return TextEntrySheet(
            title: title,
            fieldLabel: "Website address",
            prompt: "https://example.com",
            systemImage: "link",
            initialText: target?.urlString ?? "",
            submitTitle: submitTitle
        ) { value in
            addLink(value)
        }
    }

    private var mapEntrySheet: some View {
        let target = targetCard(mapTargetCardID)
        let editing = target != nil
        let title: LocalizedStringResource = editing ? "Edit Map Location" : "Add Map Location"
        let submitTitle: LocalizedStringResource = editing ? "Save" : "Add"

        return TextEntrySheet(
            title: title,
            fieldLabel: "Place",
            prompt: "Search a place…",
            systemImage: "mappin.and.ellipse",
            initialText: target?.title ?? "",
            submitTitle: submitTitle
        ) { value in
            addMap(value)
        }
    }

    private var canvasScrollView: some View {
        ScrollView(.vertical) {
            canvasSurface
                // Keep the technical grid anchored at the scroll view's top-left. It fills the window
                // when the viewport is wider than the four-column card area, while the minimum
                // width still preserves the 4×1 footprint plus its one-dot side margins.
                .frame(width: canvasContentWidth, height: canvasHeight)
                .background {
                    scrollOffsetReader
                }
        }
    }

    private var canvasSurface: some View {
        ZStack(alignment: .topLeading) {
            canvasBackgroundColor
                .contentShape(.rect)
                .onTapGesture(perform: clearSelection)

            DotGrid(
                origin: CGPoint(
                    x: CanvasMetrics.canvasMargin,
                    y: cardGridOriginY
                )
            )

            dropPreviewView
            cardsLayer
        }
    }

    @ViewBuilder
    private var dropPreviewView: some View {
        if let preview = dropPreview {
            // The landing ghost is a flat placement cue so it never reads as a second card.
            RoundedRectangle(cornerRadius: dropPreviewCornerRadius)
                .fill(.primary.opacity(0.08))
                .frame(width: preview.width, height: preview.height)
                .position(x: preview.midX, y: preview.midY)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var scrollOffsetReader: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: CanvasScrollOffsetKey.self,
                value: max(0, -geometry.frame(in: .named(scrollCoordinateSpace)).minY)
            )
        }
    }

    private var canvasBackgroundColor: Color {
        CopycolaColors.workspaceBackground(for: colorScheme)
    }

    /// The grid lines share the same origin as body-card placement. A header is structural and
    /// establishes a deliberately tighter first content row through `headerContentSpacing`.
    private var cardGridOriginY: CGFloat {
        CGFloat(contentMinimumY(for: .stickyNote) ?? Double(CanvasMetrics.canvasMargin))
    }

    // MARK: - Cards

    private var cardsLayer: some View {
        CanvasCardLayer(
            cards: board.cards,
            selectedCardID: selectedCardID,
            editingCardID: editingCardID,
            draggingCardID: draggingCardID,
            dragTranslation: dragTranslation,
            actions: CanvasCardActions(
                select: select,
                edit: edit,
                beginEditing: beginEditing,
                delete: requestDelete,
                setSize: { card, size in setCardSize(size, for: card) },
                chooseImage: chooseImage,
                cropImageToSubject: cropImageToSubject,
                editLink: editLink,
                editLocation: editLocation,
                accessibilitySummary: { card in accessibilitySummary(for: card) },
                nudge: { card, deltaX, deltaY in nudge(card, x: deltaX, y: deltaY) },
                dragChanged: dragChanged,
                dragEnded: dragEnded
            )
        )
    }

    // MARK: - Gestures

    private func dragChanged(_ card: Card, translation: CGSize) {
        guard card.kind != .header else { return }
        if draggingCardID != card.id {
            draggingCardID = card.id
            bringToFront(card)
            select(card)
        }
        dragTranslation = translation
        dropPreview = landingRect(for: card, translation: translation)
    }

    private func dragEnded(_ card: Card, translation: CGSize) {
        guard card.kind != .header else { return }
        let landing = landingRect(for: card, translation: translation)
        card.x = landing.minX
        card.y = landing.minY
        draggingCardID = nil
        dragTranslation = .zero
        dropPreview = nil
    }

    /// The grid-aligned, collision-free rect a dragged card will land in.
    private func landingRect(for card: Card, translation: CGSize) -> CGRect {
        let size = CGSize(width: card.width, height: card.height)
        let origin = nearestFreePosition(
            for: size,
            nearX: card.x + translation.width,
            nearY: card.y + translation.height,
            excluding: card.id,
            kind: card.kind
        )
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }

    private var dropPreviewCornerRadius: CGFloat {
        guard let draggingCardID,
              let card = board.cards.first(where: { $0.id == draggingCardID }) else {
            return CanvasMetrics.cardCornerRadius
        }
        return card.cardSize.cornerRadius
    }

    /// The content grows with the lowest card while remaining at least as tall as the viewport.
    /// This gives the scroll view an effectively unbounded y-axis without creating a huge blank
    /// document when a board is still empty.
    private var canvasHeight: CGFloat {
        let lowestCard = board.cards.map { CGFloat($0.y + $0.height) }.max() ?? 0
        let lowestPreview = dropPreview?.maxY ?? 0
        let selectedCardBottom: CGFloat = {
            guard let selectedCardID,
                  let selectedCard = board.cards.first(where: { $0.id == selectedCardID }),
                  selectedCard.kind != .header else { return 0 }
            return CGFloat(selectedCard.y + selectedCard.height) + 64
        }()
        let bottom = max(lowestCard, max(lowestPreview, selectedCardBottom)) + CanvasMetrics.canvasMargin
        return max(1, max(viewportSize.height, bottom))
    }

    /// The dot background follows the window width; card placement remains constrained to the
    /// fixed four-column area inside it.
    private var canvasContentWidth: CGFloat {
        max(CanvasMetrics.canvasWidth, viewportSize.width)
    }

    // MARK: - Selection

    private func select(_ card: Card) {
        selectedCardID = card.id
        if editingCardID != card.id { editingCardID = nil }
    }

    private func beginEditing(_ card: Card) {
        // Header/sticky edit their text; image edits its caption.
        guard card.kind == .header || card.kind == .stickyNote || card.kind == .image else { return }
        selectedCardID = card.id
        editingCardID = card.id
    }

    private func chooseImage(for card: Card) {
        imageTargetCardID = card.id
        showImageImporter = true
    }

    private func cropImageToSubject(for card: Card) {
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

    private func editLink(_ card: Card) {
        linkTargetCardID = card.id
        showLinkSheet = true
    }

    private func editLocation(_ card: Card) {
        mapTargetCardID = card.id
        showMapSheet = true
    }

    private func edit(_ card: Card) {
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

    private var editSelectedCardAction: (() -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { editSelectedCard() }
    }

    private func editSelectedCard() {
        guard let card = targetCard(selectedCardID) else { return }
        edit(card)
    }

    private var resizeSelectedCardAction: ((CardSize) -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { size in resizeSelectedCard(size) }
    }

    private func resizeSelectedCard(_ size: CardSize) {
        guard let card = targetCard(selectedCardID), card.kind != .header else { return }
        setCardSize(size, for: card)
    }

    private func setCardSize(_ size: CardSize, for card: Card) {
        card.cardSize = size
        constrainToCanvasWidth(card)
    }

    private var deleteSelectedCardAction: (() -> Void)? {
        guard selectedCardID != nil else { return nil }
        return { deleteSelectedCard() }
    }

    private func deleteSelectedCard() {
        guard let card = targetCard(selectedCardID) else { return }
        requestDelete(card)
    }

    private func accessibilitySummary(for card: Card) -> String {
        switch card.kind {
        case .header, .stickyNote, .image:
            return card.text
        case .link:
            return card.title ?? card.urlString ?? ""
        case .map:
            return card.title ?? ""
        }
    }

    private func nudge(_ card: Card, x deltaX: Double, y deltaY: Double) {
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

    private func clearSelection() {
        selectedCardID = nil
        editingCardID = nil
        showingCardOptions = false
    }

    private func bringToFront(_ card: Card) {
        let top = board.cards.map(\.zIndex).max() ?? 0
        card.zIndex = top + 1
    }

    private func requestDelete(_ card: Card) {
        cardToDeleteID = card.id
        showingDeleteConfirmation = true
    }

    private func deletePendingCard() {
        guard let cardToDeleteID,
              let card = board.cards.first(where: { $0.id == cardToDeleteID }) else { return }
        if selectedCardID == card.id { clearSelection() }
        context.delete(card)
        self.cardToDeleteID = nil
    }

    // MARK: - Creating cards

    private func newCard(_ kind: CardKind) -> Card {
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
    private func placement(for pointSize: CGSize, kind: CardKind) -> (x: Double, y: Double) {
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
    private func nearestFreePosition(for pointSize: CGSize,
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
    private func constrainToCanvasWidth(_ card: Card) {
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

    private func normalizeBoardGeometry() {
        for card in board.cards {
            card.refreshStoredSize()
        }
        for card in board.cards where card.kind == .header {
            constrainToCanvasWidth(card)
        }
        for card in board.cards where card.kind != .header {
            constrainToCanvasWidth(card)
        }

        guard let headerBottomY else { return }
        let minimumContentY = headerBottomY + Double(CanvasMetrics.headerContentSpacing)
        for card in board.cards where card.kind != .header {
            card.y = max(card.y, minimumContentY)
        }
    }

    /// Every canvas gets one structural header anchored to the top of the plane. It sits behind
    /// later cards in the persisted z-order while remaining part of the same grid.
    @discardableResult
    private func ensureCanvasHeader() -> Card {
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

    private var headerBottomY: Double? {
        board.cards
            .filter { $0.kind == .header }
            .map { $0.y + $0.height }
            .max()
    }

    private func contentMinimumY(for kind: CardKind) -> Double? {
        guard kind != .header, let headerBottomY else { return nil }
        return headerBottomY + Double(CanvasMetrics.headerContentSpacing)
    }

    private func addSimpleCard(_ kind: CardKind) {
        let card = newCard(kind)
        if kind == .header || kind == .stickyNote {
            editingCardID = card.id
        }
    }

    private func submitCanvasPrompt() {
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
        switch supportedKind {
        case .header, .stickyNote, .image:
            card.text = interpretation.content
            editingCardID = card.id
        default:
            card.text = interpretation.content
        }
        canvasPrompt = ""

        if let location = interpretation.location {
            Task { @MainActor in
                await setupLocationContext(location)
            }
        }
    }

    /// A location-bearing request sets up the useful spatial context around the event.
    private func setupLocationContext(_ query: String) async {
        guard let found = try? await searchLocation(query) else { return }

        let map = newCard(.map)
        map.title = found.name
        map.latitude = found.latitude
        map.longitude = found.longitude
    }

    private func requestNewCard(_ kind: CardKind) {
        showingCardOptions = false
        guard kind.isCreatable else { return }

        switch kind {
        case .image:
            imageTargetCardID = nil
            showImageImporter = true
        case .link:
            linkTargetCardID = nil
            showLinkSheet = true
        case .map:
            mapTargetCardID = nil
            showMapSheet = true
        default:
            addSimpleCard(kind)
        }
    }

    private func addLink(_ text: String) {
        let target = linkTargetCardID
        linkTargetCardID = nil
        guard let url = normalizedURL(text) else {
            presentedError = .invalidLink
            return
        }

        guard let card = cardForOperation(targetID: target, kind: .link) else { return }
        selectedCardID = card.id
        card.urlString = url.absoluteString
        card.title = url.host ?? url.absoluteString
        card.detail = nil
        card.themeColorHex = nil
        card.faviconData = nil
        card.faviconRevision = UUID()
        Task {
            let meta = await fetchLinkMetadata(for: url)

            // Do not apply metadata from an older request after the card URL changed.
            guard !card.isDeleted, card.urlString == url.absoluteString else { return }

            if let title = meta.title { card.title = title }
            card.faviconData = meta.iconData
            card.faviconRevision = UUID()
            card.detail = meta.description
            card.themeColorHex = meta.themeColorHex
        }
    }

    private func addMap(_ query: String) {
        let target = mapTargetCardID
        mapTargetCardID = nil
        Task {
            do {
                let location = try await searchLocation(query)
                guard let card = cardForOperation(targetID: target, kind: .map) else { return }
                selectedCardID = card.id
                card.title = location.name
                card.latitude = location.latitude
                card.longitude = location.longitude
            } catch LocationSearchError.noResults {
                presentedError = .locationNotFound
            } catch {
                presentedError = .locationSearchFailed(error.localizedDescription)
            }
        }
    }

    private func handleImageImport(_ result: Result<URL, Error>) {
        let target = imageTargetCardID
        imageTargetCardID = nil
        switch result {
        case .failure(let error):
            guard (error as NSError).code != NSUserCancelledError else { return }
            presentedError = .fileImportFailed(error.localizedDescription)
        case .success(let url):
            Task {
                do {
                    let data = try await loadSecurityScopedData(from: url)
                    guard let card = cardForOperation(targetID: target, kind: .image) else { return }
                    selectedCardID = card.id
                    card.imageData = data
                    card.imageRevision = UUID()
                } catch ImageLoadingError.securityScopeDenied {
                    presentedError = .imageAccessDenied
                } catch {
                    presentedError = .fileImportFailed(error.localizedDescription)
                }
            }
        }
    }

    /// Resolves a target id to an existing card, when a flow is editing rather than creating.
    private func targetCard(_ id: UUID?) -> Card? {
        guard let id else { return nil }
        return board.cards.first { $0.id == id }
    }

    private func cardForOperation(targetID: UUID?, kind: CardKind) -> Card? {
        guard let targetID else { return newCard(kind) }
        guard let card = targetCard(targetID), !card.isDeleted else {
            presentedError = .targetCardMissing
            return nil
        }
        return card
    }

}
