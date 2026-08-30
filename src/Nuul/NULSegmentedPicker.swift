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
                    withAnimation(reduceMotion ? nil : CopycoaColors.controlMotion) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .font(CopycoaTypography.body)
                        .foregroundStyle(option == selection ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: CopycoaColors.controlHeight)
                        .padding(.horizontal, CopycoaColors.gridUnit * 2)
                        .background {
                            RoundedRectangle(cornerRadius: CopycoaColors.gridUnit / 2, style: .continuous)
                                .fill(option == selection ? Color.primary.opacity(0.12) : .clear)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(CopycoaColors.gridUnit / 2)
        .background(
            CopycoaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                .strokeBorder(CopycoaColors.controlRule(for: colorScheme), lineWidth: 1)
        }
    }
}
