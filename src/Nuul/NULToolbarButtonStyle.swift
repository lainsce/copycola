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
            .frame(width: 22, height: 22)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(diameter: CGFloat = 38, accented: Bool = false) {
        self.diameter = diameter
        self.accented = accented
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(accented ? .black : .primary)
            .frame(width: 22, height: 22)
            .frame(minWidth: max(diameter, 38), minHeight: max(diameter, 38))
            .background(
                accented ? CopycoaColors.accent : CopycoaColors.itemSurface,
                in: .rect(cornerRadius: CopycoaColors.controlRadius)
            )
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.42)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : CopycoaColors.controlMotion,
                value: configuration.isPressed
            )
            .nulWindowActivityAppearance()
    }
}
