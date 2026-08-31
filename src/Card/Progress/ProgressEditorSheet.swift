import SwiftUI

/// Edits a Progress card's date range and label. The card always uses the
/// shared Item surface and Copycola accent, so appearance is shown as a
/// read-only token preview rather than a per-card color picker.
struct ProgressEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String
    @State private var startDate: Date
    @State private var goalDate: Date

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _title = State(initialValue: card.progressTitleValue)
        _startDate = State(initialValue: card.progressStartDateValue)
        _goalDate = State(initialValue: max(card.progressStartDateValue, card.progressGoalDateValue))
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Title") {
                    TextField("", text: $title, prompt: Text("Progress"))
                        .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Title")
                }
            } header: {
                Text("Progress")
            }

            Section("Goal") {
                NULFormRow("Starts") {
                    DatePicker("", selection: $startDate, displayedComponents: [.date])
                        .labelsHidden()
                        .padding(.horizontal, 8)
                        .frame(minWidth: 150, minHeight: 36, alignment: .leading)
                        .modifier(NULFieldModifier())
                        .accessibilityLabel("Starts")
                }
                NULFormRow("Goal date") {
                    DatePicker("", selection: $goalDate, in: startDate..., displayedComponents: [.date])
                        .labelsHidden()
                        .padding(.horizontal, 8)
                        .frame(minWidth: 150, minHeight: 36, alignment: .leading)
                        .modifier(NULFieldModifier())
                        .accessibilityLabel("Goal date")
                }
            }

            Section("Appearance") {
                NULFormRow("Surface") {
                    HStack(spacing: CopycolaColors.controlGap) {
                        RoundedRectangle(cornerRadius: CopycolaColors.controlRadius)
                            .fill(CopycolaColors.itemSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: CopycolaColors.controlRadius)
                                    .strokeBorder(CopycolaColors.itemRule(for: colorScheme), lineWidth: 1)
                            }
                            .frame(width: 28, height: 28)
                        Text("Item")
                            .foregroundStyle(.secondary)
                    }
                }
                NULFormRow("Accent") {
                    HStack(spacing: CopycolaColors.controlGap) {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 20, height: 20)
                        Text("Copycola")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycolaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 460, height: 370)
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
        .onChange(of: startDate) { _, newValue in
            if goalDate < newValue {
                goalDate = newValue
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        card.progressTitleValue = trimmedTitle.isEmpty ? "Progress" : trimmedTitle
        card.progressStartDateValue = startDate
        card.progressGoalDateValue = max(startDate, goalDate)
        card.progressDotColorHexValue = ProgressCardDefaults.dotColorHex
        card.progressBackgroundColorHexValue = ProgressCardDefaults.backgroundColorHex
        onSave()
        dismiss()
    }
}
