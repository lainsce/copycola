import SwiftData
import SwiftUI

@main
struct CopycolaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        CopycolaFontRegistration.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(CopycolaTypography.body)
                .nulWindowActivityAppearance()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowBackgroundDragBehavior(.enabled)
        .defaultSize(width: 1024, height: 600)
        .windowResizability(.contentSize)
        .commands {
            CopycolaCommands()
        }
        .modelContainer(for: [Board.self, Card.self])

        Window("About Copycola", id: CopycolaWindowID.about) {
            CopycolaAboutView()
                .font(CopycolaTypography.body)
                .nulWindowActivityAppearance()
        }
        .windowResizability(.contentSize)

        Window("Privacy Policy", id: CopycolaWindowID.privacyPolicy) {
            PrivacyPolicyView()
                .font(CopycolaTypography.body)
                .nulWindowActivityAppearance()
        }
        .defaultSize(width: 540, height: 540)
        .windowResizability(.contentSize)
    }
}

/// Quits the app once its last window is closed, matching single-window macOS app behaviour.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
