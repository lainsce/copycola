import SwiftUI

/// The sidebar is an opaque navigation surface, not a nested material layer.
struct NULSidebarSurface: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CopycoaColors.sidebarBackground(for: colorScheme)
            .ignoresSafeArea(.container, edges: .top)
            .accessibilityHidden(true)
    }
}
