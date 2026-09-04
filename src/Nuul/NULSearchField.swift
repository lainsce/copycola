import SwiftUI

/// Nuul search field used by the sidebar toolbar.
struct NULSearchField: View {
    @Binding var text: String
    var prompt: LocalizedStringKey = "Search"
    @FocusState private var isFocused

    var body: some View {
        HStack(spacing: CopycolaColors.controlGap) {
            NULIcon(systemImage: "magnifyingglass", foregroundColor: .secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(CopycolaTypography.contentBlockSubtitle)
                .focused($isFocused)
                .submitLabel(.search)
                .accessibilityLabel(prompt)

            if !text.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    text = ""
                    isFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .frame(width: CopycolaColors.fieldHeight, height: CopycolaColors.fieldHeight)
                .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
            }
        }
        .padding(.horizontal, CopycolaColors.fieldHorizontalPadding)
        .frame(width: 200, height: CopycolaColors.fieldHeight)
        .background(
            CopycolaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                .strokeBorder(
                    isFocused ? CopycolaColors.accent.opacity(0.72) : .clear,
                    lineWidth: 2
                )
        }
        .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
        .onTapGesture { isFocused = true }
    }
}
