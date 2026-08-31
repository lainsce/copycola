import SwiftData
import SwiftUI

@main
struct CopycoaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        CopycoaFontRegistration.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(CopycoaTypography.body)
                .nulWindowActivityAppearance()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowBackgroundDragBehavior(.enabled)
        .defaultSize(width: 1024, height: 600)
        .windowResizability(.contentSize)
        .commands {
            CopycoaCommands()
        }
        .modelContainer(for: [Board.self, Card.self])

        Window("About Copycoa", id: CopycoaWindowID.about) {
            CopycoaAboutView()
                .font(CopycoaTypography.body)
                .nulWindowActivityAppearance()
        }
        .windowResizability(.contentSize)

        Window("Privacy Policy", id: CopycoaWindowID.privacyPolicy) {
            PrivacyPolicyView()
                .font(CopycoaTypography.body)
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
