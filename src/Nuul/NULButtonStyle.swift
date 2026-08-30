import SwiftUI

/// Nuul, non-material compatibility style for existing action buttons.
struct NULButtonStyle: ButtonStyle {
    enum Kind { case primary, neutral, quiet }
    private let kind: Kind
    private let accentColor: Color
    private let horizontalPadding: CGFloat?
    private let labelColor: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(
        kind: Kind = .primary,
        accentColor: Color = .accent,
        horizontalPadding: CGFloat? = nil,
        labelColor: Color? = nil
    ) {
        self.kind = kind
        self.accentColor = accentColor
        self.horizontalPadding = horizontalPadding
        self.labelColor = labelColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CopycoaTypography.contentBlockSubtitle)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(labelColor ?? (kind == .primary ? .black : .primary))
            .padding(
                .horizontal,
                horizontalPadding ?? (kind == .quiet ? CopycoaColors.gridUnit : CopycoaColors.gridUnit * 2)
            )
            .frame(minWidth: CopycoaColors.controlHeight, minHeight: CopycoaColors.controlHeight)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
            )
            .overlay {
                if configuration.isPressed && kind != .quiet {
                    RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                        .fill(Color.primary.opacity(0.10))
                }
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.84 : 1) : 0.42)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(
                reduceMotion ? nil : CopycoaColors.controlMotion,
                value: configuration.isPressed
            )
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            accentColor
        case .neutral, .quiet:
            CopycoaColors.itemSurface
        }
    }
}
