import SwiftUI

/// Edits the quote copy and optional attribution while keeping the card's typographic layout
/// independent from the modal draft state.
struct QuoteEditorSheet: View {
    @Bindable var card: Card
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var quote: String
    @State private var attribution: String

    init(card: Card, onSave: @escaping () -> Void = {}) {
        self.card = card
        self.onSave = onSave
        _quote = State(initialValue: card.quoteTextValue)
        _attribution = State(initialValue: card.quoteAttributionValue)
    }

    var body: some View {
        Form {
            Section {
                NULFormRow("Quote") {
                    TextEditor(text: $quote)
                        .font(CopycoaTypography.body)
                        .frame(minHeight: 110)
                }
            } header: {
                Text("Quote")
            }

            Section("Attribution") {
                NULFormRow("Author or source") {
                    TextField("", text: $attribution, prompt: Text("Optional"))
                    .textFieldStyle(.plain)
                    .textFieldStyle(NULTextFieldStyle())
                        .accessibilityLabel("Author or source")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(CopycoaColors.itemSurface, in: RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous))
        .frame(width: 500, height: 350)
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
                    .disabled(trimmedQuote.isEmpty)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private var trimmedQuote: String {
        quote.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedQuote.isEmpty else { return }
        card.quoteTextValue = trimmedQuote
        card.quoteAttributionValue = attribution.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave()
        dismiss()
    }
}
