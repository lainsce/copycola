#if os(macOS)
import AppKit
import SwiftUI

/// A compact, native About surface with the app identity, release metadata, and
/// the existing privacy-policy route close at hand.
struct CopycolaAboutView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: CopycolaColors.formRowSpacing) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 128, height: 128)

            VStack(spacing: CopycolaColors.controlGap) {
                Text("Copycola")
                    .font(CopycolaTypography.viewTitle)
                    .tracking(-0.4)

                Text("A calm, spatial canvas for ideas.")
                    .font(CopycolaTypography.viewSubtitle)
                    .foregroundStyle(.secondary)
            }

            Text("Keep images and useful references together on a canvas you can return to.")
                .font(CopycolaTypography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(2...2)
                .frame(width: 310)

            VStack(spacing: CopycolaColors.gridUnit) {
                Text("Version \(versionString)")
                    .font(CopycolaTypography.technicalFont(.caption))
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
        .padding(CopycolaColors.gridUnit * 8)
        .frame(width: 400)
        .background(CopycolaColors.itemSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CopycolaColors.accent)
                .frame(height: 3)
        }
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
