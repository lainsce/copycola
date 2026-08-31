import SwiftUI

private struct CopycolaSidebarRowPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var copycolaSidebarRowIsPressed: Bool {
        get { self[CopycolaSidebarRowPressedKey.self] }
        set { self[CopycolaSidebarRowPressedKey.self] = newValue }
    }
}

/// Nuul plain row treatment; list selection owns the chrome.
struct NULSidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .environment(\.copycolaSidebarRowIsPressed, configuration.isPressed)
    }
}

/// Adds the row's pressed fill without attaching a competing zero-distance
/// drag recognizer to the button. `ButtonStyle.Configuration.isPressed` keeps
/// the primary click action available on the first click.
struct CopycolaSidebarRowPressSurface<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    @Environment(\.copycolaSidebarRowIsPressed) private var isPressed

    init(
        cornerRadius: CGFloat = CopycolaColors.controlRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.accent.opacity(isPressed ? CopycolaColors.sidebarPressedFillOpacity : 0))
            }
    }
}
