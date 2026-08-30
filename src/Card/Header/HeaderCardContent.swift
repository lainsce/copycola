import SwiftUI

/// The header card is the one card type without rounded card chrome. Its content
/// stays separate from the shared renderer so the type-specific layout is easy to
/// find alongside the other card implementations.
struct HeaderCardContent: View {
    @Bindable var card: Card
    let isEditing: Bool

    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField("Header", text: $card.text)
                    .textFieldStyle(.plain)
                    .focused($focused)
            } else if card.text.isEmpty {
                Text("Header")
                    .foregroundStyle(.secondary)
            } else {
                Text(verbatim: card.text)
                    .foregroundStyle(.primary)
            }
        }
        .font(CopycoaTypography.display)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: isEditing) { _, editing in
            focused = editing
        }
    }
}
