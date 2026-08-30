import SwiftUI

/// Shared industrial toolbar icon treatment: a 38-point hit area containing a
/// 22-point SF Symbol. The toolbar owns any group surface; individual buttons
/// remain flat and only communicate interaction through opacity.
struct NULIcon: View {
    let systemImage: String
    let foregroundColor: Color

    init(systemImage: String, foregroundColor: Color = .primary) {
        self.systemImage = systemImage
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foregroundColor)
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
    }
}

struct NULToolbarButtonStyle: ButtonStyle {
    private let diameter: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(diameter: CGFloat = 38) {
        self.diameter = diameter
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
            .frame(width: 22, height: 22)
            .frame(minWidth: max(diameter, 38), minHeight: max(diameter, 38))
            .background(
                CopycoaColors.itemSurface,
                in: .rect(cornerRadius: CopycoaColors.controlRadius)
            )
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.42)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : CopycoaColors.controlMotion,
                value: configuration.isPressed
            )
    }
}
