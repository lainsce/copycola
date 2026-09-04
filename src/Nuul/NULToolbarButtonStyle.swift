import SwiftUI

/// Shared industrial toolbar icon treatment: a 38-point hit area containing a
/// 22-point SF Symbol. The toolbar owns any group surface; individual buttons
/// remain flat and only communicate interaction through opacity.
struct NULIcon: View {
    let systemImage: String
    let foregroundColor: Color?

    init(systemImage: String, foregroundColor: Color? = nil) {
        self.systemImage = systemImage
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        icon
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .frame(width: CopycolaColors.toolbarIconSize, height: CopycolaColors.toolbarIconSize)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var icon: some View {
        if let foregroundColor {
            Image(systemName: systemImage)
                .foregroundStyle(foregroundColor)
        } else {
            Image(systemName: systemImage)
        }
    }
}

struct NULToolbarButtonStyle: ButtonStyle {
    private let diameter: CGFloat
    private let accented: Bool
    private let showsSurface: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(diameter: CGFloat = CopycolaColors.controlHeight, accented: Bool = false, showsSurface: Bool = false) {
        self.diameter = diameter
        self.accented = accented
        self.showsSurface = showsSurface
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foregroundColor)
            .frame(width: CopycolaColors.toolbarIconSize, height: CopycolaColors.toolbarIconSize)
            .frame(
                minWidth: max(diameter, CopycolaColors.controlHeight),
                minHeight: max(diameter, CopycolaColors.controlHeight)
            )
            .background {
                if accented || showsSurface {
                    RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                        .fill(accented ? CopycolaColors.accent : CopycolaColors.itemSurface)
                }
            }
            .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
            .opacity(controlOpacity(isPressed: configuration.isPressed))
            .scaleEffect(controlScale(isPressed: configuration.isPressed))
            .animation(controlMotion, value: configuration.isPressed)
            .nulWindowActivityAppearance()
    }

    private var foregroundColor: Color {
        accented ? .black : .primary
    }

    private func controlOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.42 }
        return isPressed ? 0.82 : 1
    }

    private func controlScale(isPressed: Bool) -> Double {
        guard isPressed, !reduceMotion else { return 1 }
        return 0.97
    }

    private var controlMotion: Animation? {
        reduceMotion ? nil : CopycolaColors.controlMotion
    }
}
