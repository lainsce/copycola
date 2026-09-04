import SwiftUI

/// Platform text field style.
struct NULTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(CopycolaTypography.body)
            .padding(.horizontal, CopycolaColors.fieldHorizontalPadding)
            .frame(minHeight: CopycolaColors.fieldHeight)
            .textFieldStyle(.plain)
            .background(
                CopycolaColors.itemSurface,
                in: RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                    .strokeBorder(CopycolaColors.controlRule(for: colorScheme), lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
            .opacity(isEnabled ? 1 : 0.42)
    }
}
