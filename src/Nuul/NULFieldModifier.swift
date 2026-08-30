import SwiftUI

/// Retained for call-site compatibility; fields now use native chrome.
struct NULFieldModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isFocused: Bool

    init(cornerRadius: CGFloat = CopycoaColors.controlRadius, isFocused: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isFocused = isFocused
    }

    func body(content: Content) -> some View {
        content.frame(minHeight: 36)
    }
}
