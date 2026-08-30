import SwiftUI

/// Chooses the region represented by a Time Zone card. Draft state keeps Cancel reversible.
struct TimeZoneEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var identifier: String

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _identifier = State(initialValue: TimeZoneCardPreset.preset(for: card.timeZoneIdentifier).identifier)
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Region") {
                    NULMenuPicker(
                        "Region",
                        selection: $identifier,
                        options: TimeZoneCardPreset.all.map(\.identifier),
                        showsTitle: false
                    ) { identifier in
                        Text(TimeZoneCardPreset.preset(for: identifier).city)
                    }
                }

                if let preset = TimeZoneCardPreset.all.first(where: { $0.identifier == identifier }) {
                    NULFormRow("Time zone") {
                        Text(verbatim: preset.identifier)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Time Zone")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycoaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 460, height: 220)
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
        card.timeZoneIdentifierValue = TimeZoneCardPreset.preset(for: identifier).identifier
        onSave()
        dismiss()
    }
}
