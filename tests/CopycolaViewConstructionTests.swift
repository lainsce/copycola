import CoreGraphics
import SwiftUI
import Testing
@testable import Copycola

struct CopycolaViewConstructionTests {
    @Test @MainActor
    func constructsNuulControlsInBothStateShapes() {
        _ = NULFormRow("Label") { Text("Value") }.body
        _ = NULMenuPicker("Choice", selection: .constant(1), options: [1, 2]) { value in
            Text("\(value)")
        }.body
        _ = NULMenuPicker("Choice", selection: .constant(1), options: [1, 2], showsTitle: false) { value in
            Text("\(value)")
        }.body
        _ = NULSearchField(text: .constant(""), prompt: "Search").body
        _ = NULSearchField(text: .constant("query"), prompt: "Search").body
        _ = NULSegmentedPicker(selection: .constant(1), options: [1, 2]) { value in
            Text("\(value)")
        }.body
        _ = NULSidebarSurface().body
        _ = NULIcon(systemImage: "plus").body
        _ = NULIcon(systemImage: "plus", foregroundColor: .red).body
        let onToggle = Toggle("Toggle", isOn: .constant(true)).toggleStyle(NULToggleStyle())
        let offToggle = Toggle("Toggle", isOn: .constant(false)).toggleStyle(NULToggleStyle())
        _ = (onToggle, offToggle)
        let primaryButton = Button(action: {}) { Text("Primary") }.buttonStyle(NULButtonStyle(kind: .primary))
        let neutralButton = Button(action: {}) { Text("Neutral") }.buttonStyle(NULButtonStyle(kind: .neutral))
        let quietButton = Button(action: {}) { Text("Quiet") }.buttonStyle(NULButtonStyle(kind: .quiet))
        _ = (primaryButton, neutralButton, quietButton)
        _ = Text("Field").modifier(NULFieldModifier())
        _ = Text("Focused").modifier(NULFieldModifier(cornerRadius: 9, isFocused: true))
    }

    @Test @MainActor
    func rendersNuulControlsThroughSwiftUI() {
        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 40, y: 56, zIndex: 1)
        header.text = "Canvas"
        header.board = board
        board.cards.append(header)
        func assertRenders<Control: View>(_ control: Control) {
            let renderer = ImageRenderer(content: control)
            renderer.scale = 1
            #expect(renderer.nsImage != nil)
        }

        assertRenders(Button(action: {}) { Text("Primary") }.buttonStyle(NULButtonStyle(kind: .primary)))
        assertRenders(Button(action: {}) { Text("Neutral") }.buttonStyle(NULButtonStyle(kind: .neutral)))
        assertRenders(Button(action: {}) { Text("Quiet") }.buttonStyle(NULButtonStyle(kind: .quiet)))
        assertRenders(Toggle("Toggle", isOn: .constant(true)).toggleStyle(NULToggleStyle()))
        assertRenders(Toggle("Toggle", isOn: .constant(false)).toggleStyle(NULToggleStyle()))
        assertRenders(TextField("Field", text: .constant("Value")).textFieldStyle(NULTextFieldStyle()))
        for phase in [
            ImageProcessingPhase.processing,
            .settling,
            .ready,
            .unavailable
        ] {
            assertRenders(ImageProcessingPreview(
                sourceData: .constant(nil),
                cutoutData: .constant(nil),
                phase: .constant(phase),
                approve: {},
                cancel: {}
            ))
        }
        assertRenders(ImageProcessingGrid().frame(width: 320, height: 240))
        assertRenders(ImageProcessingGrid(isMoving: true).frame(width: 320, height: 240))
        assertRenders(BloomGrid(origin: CGPoint(x: 40, y: 124)).frame(width: 320, height: 240))
        assertRenders(CanvasGridStylePicker(selection: .constant(CanvasGridStyle.grid.rawValue)))
        assertRenders(SidebarCanvasThumbnail(cards: [header], isSelected: true))
    }

    @Test
    func canvasGridStylesKeepTheirVisualOptionsAndBloomRingGeometry() {
        #expect(CanvasGridStyle.allCases == [.grid, .bloom])
        #expect(CanvasGridStyle.grid.systemImage == "square.grid.2x2")
        #expect(CanvasGridStyle.bloom.systemImage == "circle.circle")
        #expect(CanvasMetrics.bloomRowPitch < CanvasMetrics.bloomPitch)
        #expect(CanvasMetrics.bloomPitch == CanvasMetrics.module)
        #expect(CanvasMetrics.bloomCollisionInset > 0)
        #expect(CanvasMetrics.bloomRingSpacing > 0)
        #expect(CanvasMetrics.bloomRingRadius == CanvasMetrics.bloomPitch)
        #expect(CanvasMetrics.bloomRingSlotCount == 6)
        #expect(CanvasMetrics.bloomRingCenterY > CanvasMetrics.bloomRowPitch)
        #expect(CanvasMetrics.bloomRingCenterMarkerDiameter > 0)
        #expect(CanvasMetrics.bloomRingTickLength > 0)
        #expect(
            CanvasGridStyle.bloom.bloomSlotOrder(count: 7) == [
                CanvasBloomSlot(ring: 0, index: 0),
                CanvasBloomSlot(ring: 1, index: 0),
                CanvasBloomSlot(ring: 1, index: 1),
                CanvasBloomSlot(ring: 1, index: 2),
                CanvasBloomSlot(ring: 1, index: 3),
                CanvasBloomSlot(ring: 1, index: 4),
                CanvasBloomSlot(ring: 1, index: 5)
            ]
        )
    }

    @Test @MainActor
    func constructsCardSurfacesForEveryKindAndContentState() {
        let header = Card(kind: .header, size: .fourByOne, x: 0, y: 0, zIndex: 0)
        header.text = "Header"
        _ = HeaderCardContent(card: header, isEditing: false).body
        _ = HeaderCardContent(card: header, isEditing: true).body
        header.text = ""
        _ = HeaderCardContent(card: header, isEditing: false).body

        let image = Card(kind: .image, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        _ = CardImageContent(card: image).body
        _ = ImageCardSurface(card: image, isEditing: false, cornerRadius: 12).body
        _ = ImageCardSurface(card: image, isEditing: true, cornerRadius: 12).body
        image.text = "Caption"
        image.urlString = "https://example.com/image"
        _ = ImageCardSurface(card: image, isEditing: false, cornerRadius: 12).body

        _ = CardCaptionPill(text: "Caption").body
    }

    @Test @MainActor
    func constructsCardViewSelectionAndActionBranches() {
        for kind in CardKind.allCases {
            let card = Card(kind: kind, size: kind.defaultCardSize, x: 0, y: 0, zIndex: 0)
            card.text = "Content"
            card.urlString = "https://example.com"

            _ = CardView(
                card: card,
                isSelected: false,
                isEditing: false,
                isDragging: false,
                dragTranslation: .zero,
                onDelete: {},
                onEditLink: {}
            ).body
            _ = CardView(
                card: card,
                isSelected: true,
                isEditing: true,
                isDragging: false,
                dragTranslation: CGSize(width: 80, height: 0),
                onDelete: {},
                onEditLink: {}
            ).body
            _ = CardView(
                card: card,
                isSelected: true,
                isEditing: false,
                isDragging: true,
                dragTranslation: CGSize(width: -80, height: 0),
                onDelete: {},
                onEditLink: {}
            ).body
        }
    }

    @Test @MainActor
    func constructsCanvasAndSidebarViews() {
        _ = CopycolaAboutView().body
        _ = PrivacyPolicySection(
            title: "Local",
            systemImage: "lock",
            text: "Stored on this Mac"
        ).body
        _ = PrivacyPolicyView().body

        let board = Board(name: "Canvas")
        let header = Card(kind: .header, size: .fourByOne, x: 40, y: 56, zIndex: 1)
        header.text = "Canvas"
        header.board = board
        board.cards.append(header)
        let image = Card(kind: .image, size: .oneByOne, x: 40, y: 124, zIndex: 2)
        image.board = board
        board.cards.append(image)
        _ = SidebarCanvasThumbnail(cards: [], isSelected: false).body
        _ = SidebarCanvasThumbnail(cards: [header, image], isSelected: true).body
        _ = SidebarCardPreviewArtwork(kind: .header).body
        _ = SidebarCardPreviewArtwork(kind: .image).body
        _ = SidebarBoardButton(
            board: board,
            isSelected: true,
            isEditing: false,
            select: {},
            beginEditing: {},
            finishEditing: {},
            delete: {}
        ).body
        _ = SidebarBoardButton(
            board: board,
            isSelected: false,
            isEditing: true,
            select: {},
            beginEditing: {},
            finishEditing: {},
            delete: {}
        ).body

        _ = TextEntrySheet(
            title: "Edit Image Link",
            fieldLabel: "URL",
            prompt: "https://example.com",
            systemImage: "link",
            initialText: "https://example.com",
            onSubmit: { _ in }
        ).body
    }
}
