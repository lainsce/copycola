import SwiftUI

/// Nuul search field used by the sidebar toolbar.
struct NULSearchField: View {
    @Binding var text: String
    var prompt: LocalizedStringKey = "Search"
    @FocusState private var isFocused

    var body: some View {
        HStack(spacing: CopycoaColors.controlGap) {
            NULIcon(systemImage: "magnifyingglass", foregroundColor: .secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(CopycoaTypography.contentBlockSubtitle)
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
            }
        }
        .padding(.horizontal, CopycoaColors.fieldHorizontalPadding)
        .frame(width: 200, height: CopycoaColors.fieldHeight)
        .background(
            CopycoaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.accent.opacity(0.72) : .clear,
                    lineWidth: 2
                )
        }
        .onTapGesture { isFocused = true }
    }
}
