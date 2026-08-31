import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your data stays yours", systemImage: "lock.shield.fill")
                            .font(CopycolaTypography.viewTitle)
                        Text("Copycola is a local-first canvas. This policy explains what happens when you use the app.")
                            .font(CopycolaTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        PrivacyPolicySection(
                            title: "Data stored on this Mac",
                            systemImage: "internaldrive",
                            text: "Your canvases and cards are stored on this Mac. Copycola does not require an account and does not use cloud sync."
                        )
                        PrivacyPolicySection(
                            title: "Files you choose",
                            systemImage: "photo",
                            text: "When you import an image, Copycola reads the file you select and stores it in the local canvas data. Copycola does not upload that image."
                        )
                        PrivacyPolicySection(
                            title: "Network requests",
                            systemImage: "network",
                            text: "Website cards may request page metadata and a favicon from the address you enter. Place searches are sent to Apple Maps. When a cached forecast expires, Weather cards send the selected coordinates to MET Norway. MET Norway receives the network address used for the request and may retain service logs, including coordinates, for up to 90 days. Forecasts and cache metadata are stored on this Mac."
                        )
                        PrivacyPolicySection(
                            title: "No tracking or ads",
                            systemImage: "eye.slash",
                            text: "Copycola does not use advertising, analytics, tracking, or third-party account services."
                        )
                        PrivacyPolicySection(
                            title: "Your choices",
                            systemImage: "trash",
                            text: "You can delete a card or canvas at any time from the app. Deleting a canvas also deletes its cards."
                        )
                    }
                }
                .padding(28)
                .frame(maxWidth: 680, alignment: .leading)
                .background(
                    CopycolaColors.itemSurface,
                    in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous)
                )
            }
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismissWindow(id: "privacy-policy")
                    }
                    .buttonStyle(NULButtonStyle(kind: .neutral))
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .frame(minWidth: 540, minHeight: 520)
        .background(CopycolaColors.workspaceBackground(for: colorScheme))
    }
}
