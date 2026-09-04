import SwiftUI

/// Simple two-column form row with native controls and no material surface.
struct NULFormRow<Control: View>: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let control: Control

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.description = description
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top, spacing: CopycolaColors.formRowSpacing) {
            VStack(alignment: .leading, spacing: CopycolaColors.gridUnit) {
                Text(title)
                    .font(CopycolaTypography.caption)
                    .textCase(.uppercase)
                    .kerning(0.4)
                    .foregroundStyle(.secondary)

                if let description {
                    Text(description)
                        .font(CopycolaTypography.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: CopycolaColors.formLabelWidth, alignment: .leading)

            control
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
