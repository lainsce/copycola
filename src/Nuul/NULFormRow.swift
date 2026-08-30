import SwiftUI

/// Simple two-column form row with native controls and no material surface.
struct NULFormRow<Control: View>: View {
    private let title: LocalizedStringKey
    private let control: Control

    init(_ title: LocalizedStringKey, @ViewBuilder control: () -> Control) {
        self.title = title
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top, spacing: CopycoaColors.formRowSpacing) {
            Text(title)
                .font(CopycoaTypography.caption)
                .textCase(.uppercase)
                .kerning(0.4)
                .foregroundStyle(.secondary)
                .frame(width: CopycoaColors.formLabelWidth, alignment: .leading)
            control
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
