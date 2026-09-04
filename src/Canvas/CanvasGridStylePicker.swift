import SwiftUI

/// Compact toolbar control for choosing the canvas background guide.
///
/// The raw-value binding lets the preference live in `@AppStorage` without
/// adding view-specific state to the persisted `Board` model.
struct CanvasGridStylePicker: View {
    @Binding var selection: String

    private var selectedStyle: CanvasGridStyle {
        CanvasGridStyle(rawValue: selection) ?? .grid
    }

    var body: some View {
        NULSegmentedPicker(
            selection: $selection,
            options: CanvasGridStyle.allCases.map(\.rawValue)
        ) { rawValue in
            let style = CanvasGridStyle(rawValue: rawValue) ?? .grid
            return Label(style.title, systemImage: style.systemImage)
                .labelStyle(.iconOnly)
                .accessibilityLabel(Text(style.title))
        }
        .frame(
            width: CopycolaColors.toolbarViewOptionsWidth,
            height: CopycolaColors.controlHeight
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Canvas View"))
        .accessibilityValue(Text(selectedStyle.title))
        .help(Text("Canvas View"))
        .onAppear(perform: normalizeSelection)
    }

    private func normalizeSelection() {
        guard CanvasGridStyle(rawValue: selection) == nil else { return }
        selection = CanvasGridStyle.grid.rawValue
    }
}
