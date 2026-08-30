import SwiftUI

/// Platform text field style.
struct NULTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(CopycoaTypography.body)
            .padding(.horizontal, CopycoaColors.fieldHorizontalPadding)
            .frame(minHeight: CopycoaColors.fieldHeight)
            .textFieldStyle(.plain)
            .background(
                CopycoaColors.itemSurface,
                in: RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                    .strokeBorder(CopycoaColors.controlRule(for: colorScheme), lineWidth: 2)
            }
            .opacity(isEnabled ? 1 : 0.42)
    }
}
