import SwiftUI

/// Shared monochrome surface treatment for cards whose content should remain visually quiet.
enum CardSurfaceStyle {
    /// Every populated card resolves to the opaque Item surface in the active appearance.
    static var item: Color {
        CopycoaColors.itemSurface
    }

    /// Kept as a source-compatible alias for older card implementations.
    static var subtleGrayGradient: some ShapeStyle { item }
}
