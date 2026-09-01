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

private struct ResizeCardActionKey: FocusedValueKey {
    typealias Value = (CardSize) -> Void
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

    var resizeCardAction: ((CardSize) -> Void)? {
        get { self[ResizeCardActionKey.self] }
        set { self[ResizeCardActionKey.self] = newValue }
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

}

struct CopycolaCommands: Commands {
    @FocusedValue(\.newCanvasAction) private var newCanvasAction
    @FocusedValue(\.addCardAction) private var addCardAction
    @FocusedValue(\.editCardAction) private var editCardAction
    @FocusedValue(\.resizeCardAction) private var resizeCardAction
    @FocusedValue(\.deleteCardAction) private var deleteCardAction
    @FocusedValue(\.deleteCanvasAction) private var deleteCanvasAction
    @FocusedValue(\.renameCanvasAction) private var renameCanvasAction
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

        CommandGroup(after: .newItem) {
            Button("New Canvas") {
                newCanvasAction?()
            }
            .disabled(newCanvasAction == nil)
        }

        CommandMenu("Canvas") {
            Menu("Add Card") {
                ForEach(CardKind.creatable) { kind in
                    Button(kind.displayName, systemImage: kind.systemImage) {
                        addCardAction?(kind)
                    }
                }
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
        }

        CommandGroup(after: .help) {
            Button("Privacy Policy", systemImage: "hand.raised") {
                openWindow(id: CopycolaWindowID.privacyPolicy)
            }
        }
    }
}
