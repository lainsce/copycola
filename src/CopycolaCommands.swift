import SwiftUI

enum CopycolaWindowID {
    static let about = "about"
    static let privacyPolicy = "privacy-policy"
}

private struct NewCanvasActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct AddCardActionKey: FocusedValueKey {
    typealias Value = (CardKind) -> Void
}

private struct EditCardActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct DeleteCardActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct DeleteCanvasActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct RenameCanvasActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct ZoomInCanvasActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct ZoomOutCanvasActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct ResetCanvasZoomActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var newCanvasAction: (() -> Void)? {
        get { self[NewCanvasActionKey.self] }
        set { self[NewCanvasActionKey.self] = newValue }
    }

    var addCardAction: ((CardKind) -> Void)? {
        get { self[AddCardActionKey.self] }
        set { self[AddCardActionKey.self] = newValue }
    }

    var editCardAction: (() -> Void)? {
        get { self[EditCardActionKey.self] }
        set { self[EditCardActionKey.self] = newValue }
    }

    var deleteCardAction: (() -> Void)? {
        get { self[DeleteCardActionKey.self] }
        set { self[DeleteCardActionKey.self] = newValue }
    }

    var deleteCanvasAction: (() -> Void)? {
        get { self[DeleteCanvasActionKey.self] }
        set { self[DeleteCanvasActionKey.self] = newValue }
    }

    var renameCanvasAction: (() -> Void)? {
        get { self[RenameCanvasActionKey.self] }
        set { self[RenameCanvasActionKey.self] = newValue }
    }

    var zoomInCanvasAction: (() -> Void)? {
        get { self[ZoomInCanvasActionKey.self] }
        set { self[ZoomInCanvasActionKey.self] = newValue }
    }

    var zoomOutCanvasAction: (() -> Void)? {
        get { self[ZoomOutCanvasActionKey.self] }
        set { self[ZoomOutCanvasActionKey.self] = newValue }
    }

    var resetCanvasZoomAction: (() -> Void)? {
        get { self[ResetCanvasZoomActionKey.self] }
        set { self[ResetCanvasZoomActionKey.self] = newValue }
    }

}

struct CopycolaCommands: Commands {
    @FocusedValue(\.newCanvasAction) private var newCanvasAction
    @FocusedValue(\.addCardAction) private var addCardAction
    @FocusedValue(\.editCardAction) private var editCardAction
    @FocusedValue(\.deleteCardAction) private var deleteCardAction
    @FocusedValue(\.deleteCanvasAction) private var deleteCanvasAction
    @FocusedValue(\.renameCanvasAction) private var renameCanvasAction
    @FocusedValue(\.zoomInCanvasAction) private var zoomInCanvasAction
    @FocusedValue(\.zoomOutCanvasAction) private var zoomOutCanvasAction
    @FocusedValue(\.resetCanvasZoomAction) private var resetCanvasZoomAction
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Copycola", systemImage: "info.circle") {
                openWindow(id: CopycolaWindowID.about)
            }
        }

        CommandGroup(replacing: .sidebar) {
            EmptyView()
        }

        CommandGroup(replacing: .newItem) {
            Button("New Canvas") {
                newCanvasAction?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(newCanvasAction == nil)
        }

        CommandMenu("Canvas") {
            Button("Add Image", systemImage: "photo") {
                addCardAction?(.image)
            }
            .disabled(addCardAction == nil)

            Divider()

            Button("Rename Canvas") {
                renameCanvasAction?()
            }
            .disabled(renameCanvasAction == nil)

            Button("Edit Selected Card") {
                editCardAction?()
            }
            .disabled(editCardAction == nil)

            Divider()

            Button("Delete Selected Card", role: .destructive) {
                deleteCardAction?()
            }
            .disabled(deleteCardAction == nil)

            Button("Delete Canvas", role: .destructive) {
                deleteCanvasAction?()
            }
            .disabled(deleteCanvasAction == nil)

            Divider()

            Button("Zoom In") {
                zoomInCanvasAction?()
            }
            .keyboardShortcut("+", modifiers: [.command])
            .disabled(zoomInCanvasAction == nil)

            Button("Zoom Out") {
                zoomOutCanvasAction?()
            }
            .keyboardShortcut("-", modifiers: [.command])
            .disabled(zoomOutCanvasAction == nil)

            Button("Reset Bloom Zoom") {
                resetCanvasZoomAction?()
            }
            .keyboardShortcut("0", modifiers: [.command])
            .disabled(resetCanvasZoomAction == nil)
        }

        CommandGroup(after: .help) {
            Button("Privacy Policy", systemImage: "hand.raised") {
                openWindow(id: CopycolaWindowID.privacyPolicy)
            }
        }
    }
}
