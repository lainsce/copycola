import SwiftUI

/// Nuul's flat menu picker with a native disclosure affordance.
struct NULMenuPicker<Selection: Hashable, ItemLabel: View>: View {
    private let title: LocalizedStringKey
    @Binding private var selection: Selection
    private let options: [Selection]
    private let label: (Selection) -> ItemLabel
    private let showsTitle: Bool

    init(
        _ title: LocalizedStringKey,
        selection: Binding<Selection>,
        options: [Selection],
        showsTitle: Bool = true,
        label: @escaping (Selection) -> ItemLabel
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.showsTitle = showsTitle
        self.label = label
    }

    var body: some View {
        Menu {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    selection = option
                } label: {
                    label(option)
                }
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        } label: {
            HStack(spacing: CopycolaColors.gridUnit * 2) {
                if showsTitle {
                    Text(title)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                }

                label(selection)
                    .lineLimit(1)
                    .font(CopycolaTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: CopycolaColors.controlHeight, alignment: .leading)
            .padding(.horizontal, CopycolaColors.gridUnit * 2)
            .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel(Text(title))
        .fixedSize(horizontal: true, vertical: false)
    }
}
