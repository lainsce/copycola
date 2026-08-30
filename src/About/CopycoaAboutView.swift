#if os(macOS)
import AppKit
import SwiftUI

/// A compact, native About surface with the app identity, release metadata, and
/// the existing privacy-policy route close at hand.
struct CopycoaAboutView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 128, height: 128)

            VStack(spacing: 8) {
                Text("Copycoa")
                    .font(CopycoaTypography.display)

                Text("A calm, spatial canvas for ideas.")
                    .font(CopycoaTypography.viewSubtitle)
                    .foregroundStyle(.secondary)
            }

            Text("Keep notes, references, dates, places, and useful fragments together on a canvas you can return to.")
                .font(CopycoaTypography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(2...2)
                .frame(width: 310)

            VStack(spacing: 4) {
                Text("Version \(versionString)")
                    .font(CopycoaTypography.caption)
                    .foregroundStyle(.secondary)

                Text("Made with SwiftUI for Mac.")
                    .font(CopycoaTypography.caption)
                    .foregroundStyle(.tertiary)
            }

            Button("Privacy Policy") {
                openWindow(id: CopycoaWindowID.privacyPolicy)
            }
            .buttonStyle(NULButtonStyle(kind: .quiet))
        }
        .padding(32)
        .background(
            CopycoaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius, style: .continuous)
        )
        .frame(width: 400)
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "1"
        return "\(version) (\(build))"
    }
}
#endif
