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
        var fanExpanded = false
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
        assertRenders(AddCardPickerView(addCard: { _ in }, animation: nil))
        assertRenders(AddCardFanView(isExpanded: Binding(get: { fanExpanded }, set: { fanExpanded = $0 }), addCard: { _ in }))
        assertRenders(SidebarCanvasThumbnail(cards: [header], isSelected: true))
    }

    @Test @MainActor
    func constructsCardSurfacesForEveryKindAndContentState() {
        let header = Card(kind: .header, size: .fourByOne, x: 0, y: 0, zIndex: 0)
        header.text = "Header"
        _ = HeaderCardContent(card: header, isEditing: false).body
        _ = HeaderCardContent(card: header, isEditing: true).body
        header.text = ""
        _ = HeaderCardContent(card: header, isEditing: false).body

        let note = Card(kind: .stickyNote, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        _ = StickyNoteCardContent(card: note, isEditing: false, cornerRadius: 12).body
        note.text = "A note"
        _ = StickyNoteCardContent(card: note, isEditing: false, cornerRadius: 12).body
        _ = StickyNoteCardContent(card: note, isEditing: true, cornerRadius: 12).body

        let image = Card(kind: .image, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        _ = CardImageContent(card: image).body
        _ = ImageCardSurface(card: image, isEditing: false, cornerRadius: 12).body
        _ = ImageCardSurface(card: image, isEditing: true, cornerRadius: 12).body
        image.text = "Caption"
        image.urlString = "https://example.com/image"
        _ = ImageCardSurface(card: image, isEditing: false, cornerRadius: 12).body

        let link = Card(kind: .link, size: .twoByOne, x: 0, y: 0, zIndex: 0)
        link.urlString = "https://example.com"
        link.title = "Example"
        link.detail = "Description"
        _ = LinkCardSurface(card: link, cornerRadius: 12).body
        link.title = nil
        link.detail = ""
        _ = LinkCardSurface(card: link, cornerRadius: 12).body
        _ = CardFaviconContent(card: link).body

        let map = Card(kind: .map, size: .oneByOne, x: 0, y: 0, zIndex: 0)
        _ = MapCardSurface(card: map, cornerRadius: 12).body
        map.latitude = 38.7223
        map.longitude = -9.1393
        map.title = "Lisbon"
        _ = MapCardSurface(card: map, cornerRadius: 12).body
        _ = MapCardContent(coordinate: MapCoordinate(latitude: 38.7223, longitude: -9.1393)).body
        _ = CardCaptionPill(text: "Caption").body
    }

    @Test @MainActor
    func constructsCardViewSelectionAndActionBranches() {
        for kind in CardKind.allCases {
            let card = Card(kind: kind, size: kind.defaultCardSize, x: 0, y: 0, zIndex: 0)
            card.text = "Content"
            card.urlString = "https://example.com"
            card.title = "Place"
            card.latitude = 38.7
            card.longitude = -9.1

            _ = CardView(
                card: card,
                isSelected: false,
                isEditing: false,
                isDragging: false,
                dragTranslation: .zero,
                onDelete: {},
                onSetSize: { _ in },
                onBeginEdit: {},
                onChooseImage: {},
                onCropImageToSubject: {},
                onEditLink: {},
                onEditLocation: {}
            ).body
            _ = CardView(
                card: card,
                isSelected: true,
                isEditing: true,
                isDragging: false,
                dragTranslation: CGSize(width: 80, height: 0),
                onDelete: {},
                onSetSize: { _ in },
                onBeginEdit: {},
                onChooseImage: {},
                onCropImageToSubject: {},
                onEditLink: {},
                onEditLocation: {}
            ).body
            _ = CardView(
                card: card,
                isSelected: true,
                isEditing: false,
                isDragging: true,
                dragTranslation: CGSize(width: -80, height: 0),
                onDelete: {},
                onSetSize: { _ in },
                onBeginEdit: {},
                onChooseImage: {},
                onCropImageToSubject: {},
                onEditLink: {},
                onEditLocation: {}
            ).body
        }
    }

    @Test @MainActor
    func constructsCanvasAndSidebarViews() {
        var expanded = false
        _ = AddCardFanView(isExpanded: Binding(get: { expanded }, set: { expanded = $0 }), addCard: { _ in }).body
        _ = AddCardPickerView(addCard: { _ in }, animation: nil).body
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
        let note = Card(kind: .stickyNote, size: .oneByOne, x: 40, y: 124, zIndex: 2)
        note.text = "Note"
        note.board = board
        board.cards.append(note)
        _ = SidebarCanvasThumbnail(cards: [], isSelected: false).body
        _ = SidebarCanvasThumbnail(cards: [header, note], isSelected: true).body
        _ = SidebarCardPreviewArtwork(kind: .header).body
        _ = SidebarCardPreviewArtwork(kind: .stickyNote).body
        _ = SidebarCardPreviewArtwork(kind: .image).body
        _ = SidebarCardPreviewArtwork(kind: .link).body
        _ = SidebarCardPreviewArtwork(kind: .map).body
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
            title: "Add Link",
            fieldLabel: "URL",
            prompt: "https://example.com",
            systemImage: "link",
            initialText: "https://example.com",
            onSubmit: { _ in }
        ).body
    }
}
