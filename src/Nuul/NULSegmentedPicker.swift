import SwiftUI

/// A compact, geometric segmented control. It keeps the familiar grouped
/// affordance while avoiding the platform's translucent segmented chrome.
struct NULSegmentedPicker<Selection: Hashable, ItemLabel: View>: View {
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(
        selection: Binding<Selection>,
        options: [Selection],
        label: @escaping (Selection) -> ItemLabel
    ) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    withAnimation(reduceMotion ? nil : CopycolaColors.controlMotion) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .font(CopycolaTypography.body)
                        .foregroundStyle(option == selection ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: CopycolaColors.controlHeight)
                        .padding(.horizontal, CopycolaColors.gridUnit * 2)
                        .background {
                            RoundedRectangle(cornerRadius: CopycolaColors.gridUnit / 2, style: .continuous)
                                .fill(option == selection ? Color.primary.opacity(0.12) : .clear)
                        }
                        .contentShape(.rect(cornerRadius: CopycolaColors.gridUnit / 2))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(CopycolaColors.gridUnit / 2)
        .background(
            CopycolaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                .strokeBorder(CopycolaColors.controlRule(for: colorScheme), lineWidth: 1)
        }
    }
}
