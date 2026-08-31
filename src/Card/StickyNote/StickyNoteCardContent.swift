import SwiftUI

/// The editable and display states of a Sticky Note card.
struct StickyNoteCardContent: View {
    @Bindable var card: Card
    let isEditing: Bool
    let cornerRadius: CGFloat

    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if isEditing {
                TextEditor(text: $card.text)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
            } else if card.text.isEmpty {
                Text("Write a note…")
                    .foregroundStyle(CopycolaColors.itemSecondaryText(for: colorScheme).opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text(verbatim: card.text)
                    .foregroundStyle(CopycolaColors.itemText(for: colorScheme).opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .font(CopycolaTypography.contentBlockSubtitle)
        .padding(CanvasMetrics.cardContentInset)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(CopycolaColors.itemSurface)
        }
        .onChange(of: isEditing) { _, editing in
            focused = editing
        }
    }
}
