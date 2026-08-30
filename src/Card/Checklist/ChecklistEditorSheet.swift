import SwiftUI

/// Edits the three fixed checklist slots. Empty slots are omitted from the card, so users can
/// make a one- or two-item checklist without the editor growing beyond its compact design.
struct ChecklistEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var itemOne: String
    @State private var itemTwo: String
    @State private var itemThree: String
    @State private var completed: [Bool]

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _title = State(initialValue: card.checklistTitleValue)
        _itemOne = State(initialValue: card.checklistItemValueOne)
        _itemTwo = State(initialValue: card.checklistItemValueTwo)
        _itemThree = State(initialValue: card.checklistItemValueThree)
        _completed = State(initialValue: (0..<3).map { card.checklistCompletedMaskValue & (1 << $0) != 0 })
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Title") {
                    TextField("", text: $title, prompt: Text("Checklist"))
                        .textFieldStyle(.plain)
                        .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Title")
                }
            } header: {
                Text("Checklist")
            }

            Section("Checks") {
                ChecklistEditorRow(
                    title: "Check 1",
                    text: $itemOne,
                    isCompleted: $completed[0]
                )
                ChecklistEditorRow(
                    title: "Check 2",
                    text: $itemTwo,
                    isCompleted: $completed[1]
                )
                ChecklistEditorRow(
                    title: "Check 3",
                    text: $itemThree,
                    isCompleted: $completed[2]
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycoaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 500, height: 390)
        .padding(.top, 8)
        .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                        .buttonStyle(NULButtonStyle(kind: .neutral))
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .buttonStyle(NULButtonStyle(kind: .primary))
                    .keyboardShortcut(.defaultAction)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func save() {
        let values = [itemOne, itemTwo, itemThree].map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        card.checklistTitleValue = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Checklist"
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        card.checklistItemValueOne = values[0]
        card.checklistItemValueTwo = values[1]
        card.checklistItemValueThree = values[2]
        card.checklistCompletedMaskValue = completed.enumerated().reduce(0) { mask, entry in
            entry.element && !values[entry.offset].isEmpty
                ? mask | (1 << entry.offset)
                : mask
        }
        onSave()
        dismiss()
    }
}

private struct ChecklistEditorRow: View {
    let title: LocalizedStringKey
    @Binding var text: String
    @Binding var isCompleted: Bool

    var body: some View {
        NULFormRow(title) {
            VStack(alignment: .leading, spacing: CopycoaColors.controlGap) {
                TextField("", text: $text, prompt: Text("Optional"))
                    .textFieldStyle(.plain)
                    .textFieldStyle(NULTextFieldStyle())
                    .accessibilityLabel(title)
                Toggle("Completed", isOn: $isCompleted)
                    .labelsHidden()
                    .toggleStyle(NULToggleStyle())
                    .accessibilityLabel("Completed")
            }
        }
    }
}
