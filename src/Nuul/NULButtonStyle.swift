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
            .font(CopycolaTypography.contentBlockSubtitle)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(resolvedLabelColor)
            .padding(.horizontal, resolvedHorizontalPadding)
            .frame(minWidth: CopycolaColors.controlHeight, minHeight: CopycolaColors.controlHeight)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
            )
            .overlay { pressedOverlay(isPressed: configuration.isPressed) }
            .contentShape(Rectangle())
            .opacity(controlOpacity(isPressed: configuration.isPressed))
            .scaleEffect(controlScale(isPressed: configuration.isPressed))
            .animation(controlMotion, value: configuration.isPressed)
            .nulWindowActivityAppearance()
    }

    @ViewBuilder
    private func pressedOverlay(isPressed: Bool) -> some View {
        if isPressed && kind != .quiet {
            RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                .fill(Color.primary.opacity(0.10))
        }
    }

    private var resolvedLabelColor: Color {
        labelColor ?? (kind == .primary ? .black : .primary)
    }

    private var resolvedHorizontalPadding: CGFloat {
        horizontalPadding ?? (kind == .quiet ? CopycolaColors.gridUnit : CopycolaColors.gridUnit * 2)
    }

    private func controlOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.42 }
        return isPressed ? 0.84 : 1
    }

    private func controlScale(isPressed: Bool) -> Double {
        guard isPressed, !reduceMotion else { return 1 }
        return 0.98
    }

    private var controlMotion: Animation? {
        reduceMotion ? nil : CopycolaColors.controlMotion
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            accentColor
        case .neutral, .quiet:
            CopycolaColors.itemSurface
        }
    }
}
