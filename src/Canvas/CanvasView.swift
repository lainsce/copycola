import SwiftUI
import SwiftData
import UniformTypeIdentifiers

    /// The fixed-column card surface: draws a viewport-sized technical grid, positions cards, and
/// handles vertical scrolling, card dragging with grid + magnetic snapping, and card creation.
struct CanvasView: View {
    @Bindable var board: Board
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion
    @AppStorage("copycola.canvas.grid-style") private var canvasGridStyleRawValue = CanvasGridStyle.grid.rawValue

    @State var selectedCardID: UUID?
    @State var editingCardID: UUID?
    @State var draggingCardID: UUID?
    @State var dragTranslation: CGSize = .zero
    /// Where the currently dragged card will land, in content space (for the drop-preview ghost).
    @State var dropPreview: CGRect?
    @State var viewportSize: CGSize = .zero
    @State private var bloomZoom = CanvasZoom.defaultValue
    @State private var bloomMagnificationStart: CGFloat?

    // Add-card flows. A non-nil target id means the flow edits that existing card
    // instead of creating a new one.
    @State var showImageImporter = false
    @State var showImageProcessing = false
    @State var showLinkSheet = false
    @State var imageTargetCardID: UUID?
    @State var imageProcessingTargetCardID: UUID?
    @State var imageProcessingSourceData: Data?
    @State var imageProcessingCutoutData: Data?
    @State var imageProcessingPhase: ImageProcessingPhase = .processing
    @State var imageProcessingRequestID: UUID?
    @State var isImageDropTargeted = false
    @State var linkTargetCardID: UUID?
    @State var presentedError: CanvasError?
    @State var cardToDeleteID: UUID?
    @State var showingDeleteConfirmation = false

    var body: some View {
        canvasWithCommands
    }

    var currentCanvasGridStyle: CanvasGridStyle {
        CanvasGridStyle(rawValue: canvasGridStyleRawValue) ?? .grid
    }

    var canvasWithCommands: some View {
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
            .focusedSceneValue(\.deleteCardAction, deleteSelectedCardAction)
            .focusedSceneValue(\.zoomInCanvasAction, zoomInCanvasAction)
            .focusedSceneValue(\.zoomOutCanvasAction, zoomOutCanvasAction)
            .focusedSceneValue(\.resetCanvasZoomAction, resetCanvasZoomAction)
            .toolbar {
                ToolbarSpacer(placement: .navigation)
                    .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Image", systemImage: "plus") {
                        requestNewCard(.image)
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(Text("Add Image"))
                    .help(Text("Add Image"))
                    .buttonStyle(NULToolbarButtonStyle(accented: true))
                }
                .sharedBackgroundVisibility(.hidden)
            }
    }

    @ViewBuilder
    var deleteConfirmationActions: some View {
        Button("Delete Card", role: .destructive, action: deletePendingCard)
        Button("Cancel", role: .cancel) { cardToDeleteID = nil }
    }

    var canvasWithSheets: some View {
        canvasViewport
            .fileImporter(isPresented: $showImageImporter, allowedContentTypes: [.image]) { result in
                handleImageImport(result)
            }
            .sheet(isPresented: $showLinkSheet, onDismiss: {
                linkTargetCardID = nil
            }) {
                linkEntrySheet
            }
            .sheet(isPresented: $showImageProcessing, onDismiss: {
                resetImageProcessing()
            }) {
                ImageProcessingPreview(
                    sourceData: $imageProcessingSourceData,
                    cutoutData: $imageProcessingCutoutData,
                    phase: $imageProcessingPhase,
                    approve: approvePendingImage,
                    cancel: cancelImageProcessing
                )
            }
    }

    var canvasViewport: some View {
        canvasScrollView
            .scrollIndicators(.automatic)
            // Let the viewport claim the remaining detail-pane width; the content frame above
            // then receives the true window width instead of stopping at its 4-column minimum.
            .frame(
                minWidth: CanvasMetrics.canvasWidth,
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
            .background {
                CanvasScrollWheelZoomInput(
                    isEnabled: currentCanvasGridStyle == .bloom,
                    onScroll: adjustBloomZoom(fromScrollDelta:precise:)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
            .clipped()
            .onDrop(of: Self.imageDropTypes, isTargeted: $isImageDropTargeted) { providers in
                handleImageDrop(providers)
            }
            .onAppear {
                ensureCanvasHeader()
                normalizeBoardGeometry()
                if currentCanvasGridStyle == .bloom {
                    reflowCards(for: currentCanvasGridStyle)
                }
            }
            .onChange(of: canvasGridStyleRawValue) { _, rawValue in
                let style = CanvasGridStyle(rawValue: rawValue) ?? .grid
                if style != .bloom {
                    resetBloomZoom(animated: false)
                }
                withAnimation(accessibilityReduceMotion ? nil : CopycolaColors.navigationMotion) {
                    reflowCards(for: style)
                }
            }
    }

    var linkEntrySheet: some View {
        let target = targetCard(linkTargetCardID)
        return TextEntrySheet(
            title: "Edit Image Link",
            fieldLabel: "Website address",
            prompt: "https://example.com",
            systemImage: "link",
            initialText: target?.urlString ?? "",
            submitTitle: "Save"
        ) { value in
            addLink(value)
        }
    }

    var canvasScrollView: some View {
        return ScrollView(.vertical) {
            canvasSurface
                // Keep the technical grid anchored at the scroll view's top-left. It fills the window
                // when the viewport is wider than the four-column card area, while the minimum
                // width still preserves the 4×1 footprint plus its one-dot side margins.
                .frame(width: canvasContentWidth, height: renderedCanvasHeight, alignment: .top)
                .background(canvasBackgroundColor)
        }
    }

    var canvasSurface: some View {
        ZStack(alignment: .topLeading) {
            canvasBackgroundColor
                .contentShape(.rect)
                .onTapGesture(perform: clearSelection)
        }
        // Keep the structural layer's layout box fixed while the Bloom body changes scale. The
        // body is composited as an overlay below, so SwiftUI cannot re-center the header during a
        // magnification animation.
        .frame(width: canvasContentWidth, height: renderedCanvasHeight, alignment: .topLeading)
        .overlay(alignment: .topLeading) {
            canvasBodyLayer
        }
        .overlay(alignment: .topLeading) {
            headerCardsLayer
        }
        .simultaneousGesture(bloomMagnifyGesture)
    }

    /// Body cards own the active visual transform. Keeping the structural header outside this
    /// layer means its title remains legible and stable while Bloom is magnified or reduced.
    @ViewBuilder
    var canvasBodyLayer: some View {
        let bodyCards = board.cards.filter { $0.isSupportedKind && $0.kind != .header }
        let body = ZStack(alignment: .topLeading) {
            canvasGrid
            dropPreviewView
            canvasCardsLayer(for: bodyCards)
        }
        .frame(width: canvasContentWidth, height: canvasHeight, alignment: .topLeading)

        if currentCanvasGridStyle == .bloom {
            body
                .scaleEffect(activeCanvasZoom, anchor: bloomZoomAnchor)
                // This is deliberately after the scale transform: the visual center is a
                // viewport coordinate, so the centering correction itself must not be magnified.
                .offset(bloomBodyOffset)
        } else {
            body
        }
    }

    /// The header is structural chrome for the canvas, not part of the zoomable Bloom plane.
    var headerCardsLayer: some View {
        canvasCardsLayer(for: board.cards.filter { $0.isSupportedKind && $0.kind == .header })
    }

    var activeCanvasZoom: CGFloat {
        currentCanvasGridStyle == .bloom ? CanvasZoom.clamped(bloomZoom) : CanvasZoom.defaultValue
    }

    /// Keep Bloom's radial center fixed while the view magnifies. The canvas has a minimum
    /// width but can receive extra detail-pane space, so the anchor is relative to that fixed
    /// placement area rather than the full window width.
    var bloomZoomAnchor: UnitPoint {
        let width = max(canvasContentWidth, CanvasMetrics.canvasWidth)
        let x = min(max(CanvasMetrics.canvasWidth / (2 * width), 0), 1)
        return UnitPoint(x: x, y: 0)
    }

    /// The persisted Bloom coordinates are intentionally stable. This correction only changes
    /// their presentation so the radial composition is centered in the visible body area, even
    /// when the detail pane is wider than the four-column placement footprint.
    var bloomBodyOffset: CGSize {
        guard currentCanvasGridStyle == .bloom else { return .zero }

        let zoom = activeCanvasZoom
        let anchorX = bloomZoomAnchor.x * canvasContentWidth
        let scaledCenterX = anchorX + (bloomBaseCenter.x - anchorX) * zoom
        let targetCenterX = canvasContentWidth / 2

        let bodyTop = cardGridOriginY
        let bodyBottom = max(bodyTop, viewportSize.height)
        let targetCenterY = bodyTop + (bodyBottom - bodyTop) / 2
        let scaledCenterY = bloomBaseCenter.y * zoom

        return CGSize(
            width: targetCenterX - scaledCenterX,
            height: targetCenterY - scaledCenterY
        )
    }

    var bloomBaseCenter: CGPoint {
        CGPoint(
            x: CanvasMetrics.canvasWidth / 2,
            y: cardGridOriginY + CanvasMetrics.bloomRingCenterY
        )
    }

    /// Keep the scroll document's top geometry independent of presentation zoom. Growing the
    /// scroll content while magnifying makes AppKit preserve the scroll position by briefly
    /// moving the structural header; the transformed body can safely render beyond this box and
    /// the viewport clips it at its own bounds.
    var renderedCanvasHeight: CGFloat {
        max(viewportSize.height, canvasHeight)
    }

    var bloomMagnifyGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                guard currentCanvasGridStyle == .bloom else { return }
                if bloomMagnificationStart == nil {
                    bloomMagnificationStart = bloomZoom
                }
                let start = bloomMagnificationStart ?? bloomZoom
                setBloomZoom(start * value.magnification, animated: false)
            }
            .onEnded { _ in
                bloomMagnificationStart = nil
            }
    }

    var zoomInCanvasAction: (() -> Void)? {
        guard currentCanvasGridStyle == .bloom else { return nil }
        return { stepBloomZoom(direction: 1) }
    }

    var zoomOutCanvasAction: (() -> Void)? {
        guard currentCanvasGridStyle == .bloom else { return nil }
        return { stepBloomZoom(direction: -1) }
    }

    var resetCanvasZoomAction: (() -> Void)? {
        guard currentCanvasGridStyle == .bloom else { return nil }
        return { resetBloomZoom() }
    }

    func setBloomZoom(_ value: CGFloat, animated: Bool = true) {
        guard currentCanvasGridStyle == .bloom else { return }
        let value = CanvasZoom.clamped(value)
        guard abs(value - bloomZoom) > 0.0001 else { return }

        if animated, !accessibilityReduceMotion {
            withAnimation(CopycolaColors.controlMotion) {
                bloomZoom = value
            }
        } else {
            bloomZoom = value
        }
    }

    func stepBloomZoom(direction: CGFloat) {
        setBloomZoom(CanvasZoom.stepped(bloomZoom, direction: direction))
    }

    func adjustBloomZoom(fromScrollDelta delta: CGFloat, precise: Bool) {
        guard currentCanvasGridStyle == .bloom else { return }
        setBloomZoom(
            CanvasZoom.value(fromScrollDelta: delta, precise: precise, startingAt: bloomZoom),
            animated: false
        )
    }

    func resetBloomZoom(animated: Bool = true) {
        bloomMagnificationStart = nil
        guard abs(bloomZoom - CanvasZoom.defaultValue) > 0.0001 else { return }

        if animated, !accessibilityReduceMotion {
            withAnimation(CopycolaColors.controlMotion) {
                bloomZoom = CanvasZoom.defaultValue
            }
        } else {
            bloomZoom = CanvasZoom.defaultValue
        }
    }

    @ViewBuilder
    var dropPreviewView: some View {
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

    var canvasBackgroundColor: Color {
        CopycolaColors.workspaceBackground(for: colorScheme)
    }

    @ViewBuilder
    var canvasGrid: some View {
        let origin = CGPoint(
            x: CanvasMetrics.canvasMargin,
            y: cardGridOriginY
        )

        switch currentCanvasGridStyle {
        case .grid:
            DotGrid(origin: origin)
        case .bloom:
            BloomGrid(
                origin: origin,
                viewportSize: viewportSize,
                zoom: activeCanvasZoom
            )
        }
    }

    /// The grid lines share the same origin as body-card placement. A header is structural and
    /// establishes a deliberately tighter first content row through `headerContentSpacing`.
    var cardGridOriginY: CGFloat {
        CGFloat(contentMinimumY(for: .image) ?? Double(CanvasMetrics.canvasMargin))
    }

    // MARK: - Cards

    @ViewBuilder
    func canvasCardsLayer(for cards: [Card]) -> some View {
        CanvasCardLayer(
            cards: cards,
            selectedCardID: selectedCardID,
            editingCardID: editingCardID,
            draggingCardID: draggingCardID,
            dragTranslation: dragTranslation,
            nudgeStep: CGSize(
                width: currentCanvasGridStyle.columnPitch,
                height: currentCanvasGridStyle.rowPitch
            ),
            actions: CanvasCardActions(
                select: select,
                edit: edit,
                delete: requestDelete,
                editLink: editLink,
                accessibilitySummary: { card in accessibilitySummary(for: card) },
                nudge: { card, deltaX, deltaY in nudge(card, x: deltaX, y: deltaY) },
                dragChanged: dragChanged,
                dragEnded: dragEnded
            )
        )
    }

}
