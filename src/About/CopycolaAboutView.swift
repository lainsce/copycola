#if os(macOS)
import AppKit
import SwiftUI

/// A compact, native About surface with the app identity, release metadata, and
/// the existing privacy-policy route close at hand.
struct CopycolaAboutView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 128, height: 128)

            VStack(spacing: 8) {
                Text("Copycola")
                    .font(CopycolaTypography.display)

                Text("A calm, spatial canvas for ideas.")
                    .font(CopycolaTypography.viewSubtitle)
                    .foregroundStyle(.secondary)
            }

            Text("Keep notes, references, dates, places, and useful fragments together on a canvas you can return to.")
                .font(CopycolaTypography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(2...2)
                .frame(width: 310)

            VStack(spacing: 4) {
                Text("Version \(versionString)")
                    .font(CopycolaTypography.caption)
                    .foregroundStyle(.secondary)

                Text("Made with SwiftUI for Mac.")
                    .font(CopycolaTypography.caption)
                    .foregroundStyle(.tertiary)
            }

            Button("Privacy Policy") {
                openWindow(id: CopycolaWindowID.privacyPolicy)
            }
            .buttonStyle(NULButtonStyle(kind: .quiet))
        }
        .padding(32)
        .background(
            CopycolaColors.itemSurface,
            in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous)
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
