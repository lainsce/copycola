import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Copycola's two-layer surface palette. The workspace and sidebar are a
/// deliberate industrial gray; cards and controls sit on a stable, opaque
/// item surface so their content remains easy to read.
enum CopycolaColors {
    // The control layer follows a small four-point rhythm. Canvas placement
    // keeps its own card grid, while settings, toolbars, and sheets share
    // these UI measurements.
    static let gridUnit: CGFloat = 4
    static let controlGap: CGFloat = gridUnit * 2
    static let formRowSpacing: CGFloat = gridUnit * 4
    static let formLabelWidth: CGFloat = gridUnit * 32
    static let controlHeight: CGFloat = 38
    static let fieldHeight: CGFloat = gridUnit * 9
    static let fieldHorizontalPadding: CGFloat = gridUnit * 3
    static let controlRadius: CGFloat = gridUnit
    static let largeSurfaceRadius: CGFloat = gridUnit * 3
    static let controlMotion = Animation.spring(response: 0.24, dampingFraction: 0.88)
    static let navigationMotion = Animation.spring(response: 0.34, dampingFraction: 0.84)

    static func workspaceBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0, green: 0, blue: 0)
            : Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
    }

    /// Sidebars are an opaque, dedicated surface. Keeping this separate from
    /// the workspace prevents translucent system materials from leaking into
    /// the navigation column.
    static func sidebarBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255)
            : Color(red: 228 / 255, green: 228 / 255, blue: 228 / 255)
    }

    /// The only pane boundary is a single 12% black/white rule.
    static func sidebarDivider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    static func controlRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.16)
            : Color.black.opacity(0.12)
    }

    static func quietRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    static let sidebarSelectedFillOpacity: Double = 0.14
    static let sidebarPressedFillOpacity: Double = 0.22
    static let sidebarHoverFillOpacity: Double = 0.06
    static let sidebarSelectedBorderOpacity: Double = 0.72

    static var itemSurface: Color {
#if os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(srgbRed: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
                : NSColor(srgbRed: 253 / 255, green: 253 / 255, blue: 253 / 255, alpha: 1)
        })
#elseif os(iOS)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
                : UIColor(red: 253 / 255, green: 253 / 255, blue: 253 / 255, alpha: 1)
        })
#else
        Color(red: 253 / 255, green: 253 / 255, blue: 253 / 255)
#endif
    }

    /// The opaque foreground token used inside an Item surface.
    static func itemText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    /// Secondary Item text stays on the same monochrome ramp in both modes.
    static func itemSecondaryText(for colorScheme: ColorScheme) -> Color {
        itemText(for: colorScheme).opacity(0.56)
    }

    /// A quiet Item rule for dividers, chip outlines, and inactive controls.
    static func itemRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    /// Copycola's sole chromatic UI token. The asset supplies the light/dark values.
    static var accent: Color { .accent }

    static let itemSurfaceLightHex = "FDFDFD"
    static let itemSurfaceDarkHex = "111111"
    static let accentLightHex = "DE9C32"
    static let accentDarkHex = "D39224"
}
