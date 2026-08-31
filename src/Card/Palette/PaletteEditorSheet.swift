import SwiftUI

/// Edits the palette title while keeping the five chips bound to the shared
/// Nuul token ramp: one accent followed by four neutral values.
struct PaletteEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _title = State(initialValue: card.paletteTitleValue)
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Title") {
                    TextField("", text: $title, prompt: Text("Palette"))
                        .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Title")
                }
            } header: {
                Text("Palette")
            }

            Section("Nuul tokens") {
                ForEach(PaletteChipSlot.allCases) { slot in
                    NULFormRow("Chip \(slot.rawValue + 1)") {
                        HStack(spacing: CopycolaColors.controlGap) {
                            RoundedRectangle(cornerRadius: CopycolaColors.controlRadius)
                                .fill(Color(hex: PaletteCardDefaults.defaultColors[slot.rawValue]))
                                .overlay {
                                    RoundedRectangle(cornerRadius: CopycolaColors.controlRadius)
                                        .strokeBorder(CopycolaColors.itemRule(for: colorScheme), lineWidth: 1)
                                }
                                .frame(width: 28, height: 28)
                            Text(PaletteCardDefaults.defaultColors[slot.rawValue])
                                .font(CopycolaTypography.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "Chip \(slot.rawValue + 1), \(PaletteCardDefaults.defaultColors[slot.rawValue])"
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycolaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 460, height: 400)
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
        card.paletteTitleValue = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Palette"
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        card.paletteColorHexValues = PaletteCardDefaults.defaultColors
        onSave()
        dismiss()
    }
}
