import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CanvasScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

    /// The fixed-column card surface: draws a viewport-sized technical grid, positions cards, and
/// handles vertical scrolling, card dragging with grid + magnetic snapping, and card creation.
struct CanvasView: View {
    @Bindable var board: Board
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme

    @State var selectedCardID: UUID?
    @State var editingCardID: UUID?
    @State var draggingCardID: UUID?
    @State var dragTranslation: CGSize = .zero
    /// Where the currently dragged card will land, in content space (for the drop-preview ghost).
    @State var dropPreview: CGRect?
    @State var viewportSize: CGSize = .zero
    @State var scrollOffset: CGFloat = .zero

    let scrollCoordinateSpace = "canvas-scroll"

    // Add-card flows. A non-nil target id means the flow edits that existing card
    // instead of creating a new one.
    @State var showImageImporter = false
    @State var showLinkSheet = false
    @State var showMapSheet = false
    @State var showingCardOptions = false
    @State var imageTargetCardID: UUID?
    @State var linkTargetCardID: UUID?
    @State var mapTargetCardID: UUID?
    @State var presentedError: CanvasError?
    @State var cardToDeleteID: UUID?
    @State var showingDeleteConfirmation = false
    @State var canvasPrompt = ""
    @StateObject var voiceRecorder = CanvasVoiceRecorder()

    var body: some View {
        canvasWithCommands
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
            .sheet(isPresented: $showMapSheet, onDismiss: {
                mapTargetCardID = nil
            }) {
                mapEntrySheet
            }
    }

    var canvasViewport: some View {
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

    var linkEntrySheet: some View {
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

    var mapEntrySheet: some View {
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

    var canvasScrollView: some View {
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

    var canvasSurface: some View {
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

    var scrollOffsetReader: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: CanvasScrollOffsetKey.self,
                value: max(0, -geometry.frame(in: .named(scrollCoordinateSpace)).minY)
            )
        }
    }

    var canvasBackgroundColor: Color {
        CopycolaColors.workspaceBackground(for: colorScheme)
    }

    /// The grid lines share the same origin as body-card placement. A header is structural and
    /// establishes a deliberately tighter first content row through `headerContentSpacing`.
    var cardGridOriginY: CGFloat {
        CGFloat(contentMinimumY(for: .stickyNote) ?? Double(CanvasMetrics.canvasMargin))
    }

    // MARK: - Cards

    var cardsLayer: some View {
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

}
