import SwiftUI

private struct CopycoaSidebarRowPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var copycoaSidebarRowIsPressed: Bool {
        get { self[CopycoaSidebarRowPressedKey.self] }
        set { self[CopycoaSidebarRowPressedKey.self] = newValue }
    }
}

/// Nuul plain row treatment; list selection owns the chrome.
struct NULSidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .environment(\.copycoaSidebarRowIsPressed, configuration.isPressed)
    }
}

/// Adds the row's pressed fill without attaching a competing zero-distance
/// drag recognizer to the button. `ButtonStyle.Configuration.isPressed` keeps
/// the primary click action available on the first click.
struct CopycoaSidebarRowPressSurface<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    @Environment(\.copycoaSidebarRowIsPressed) private var isPressed

    init(
        cornerRadius: CGFloat = CopycoaColors.controlRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.accent.opacity(isPressed ? CopycoaColors.sidebarPressedFillOpacity : 0))
            }
    }
}
