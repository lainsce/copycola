import SwiftUI

/// Chooses the forecast location and whether Copycola should write the summary.
struct WeatherEditorSheet: View {
    let card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var location: String
    @State private var summary: String
    @State private var usesAutomaticSummary: Bool

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _location = State(initialValue: card.weatherLocationValue)
        _summary = State(initialValue: card.weatherSummaryValue)
        _usesAutomaticSummary = State(initialValue: card.weatherUsesAutomaticSummaryValue)
    }

    var body: some View {
        Form {
            Section("Location") {
                NULFormRow("Place") {
                    TextField("", text: $location, prompt: Text("City or address"))
                    .textFieldStyle(.plain)
                    .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Place")
                }
            }

            Section {
                NULFormRow("Automatic summary") {
                    Toggle("", isOn: $usesAutomaticSummary)
                        .labelsHidden()
                        .toggleStyle(NULToggleStyle())
                        .accessibilityLabel("Automatic summary")
                }

                if !usesAutomaticSummary {
                    NULFormRow("Custom summary") {
                        TextField("", text: $summary, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.plain)
                            .textFieldStyle(NULTextFieldStyle())
                            .accessibilityLabel("Custom summary")
                    }
                }
            } header: {
                Text("Summary")
            } footer: {
                Text("Copycola writes this from the live conditions in the same playful tone as the card design.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycolaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 520, height: 390)
        .padding(.top, 8)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
                    .buttonStyle(NULButtonStyle(kind: .neutral))
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .confirmationAction) {
                Button("Save & Update", action: save)
                    .buttonStyle(NULButtonStyle(kind: .primary))
                    .keyboardShortcut(.defaultAction)
                    .disabled(cleanedLocation.isEmpty)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func save() {
        card.weatherLocationValue = cleanedLocation
        card.weatherUsesAutomaticSummaryValue = usesAutomaticSummary
        if !usesAutomaticSummary {
            let cleanedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            card.weatherSummaryValue = cleanedSummary.isEmpty
                ? WeatherSummaryGenerator.referenceSummary
                : cleanedSummary
        }
        onSave()
        dismiss()
    }

    private var cleanedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
