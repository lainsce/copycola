import AppKit
import SwiftUI

/// Observes Command-scroll inside the canvas without taking ordinary scroll events away from
/// SwiftUI's vertical ScrollView. Trackpad pinch is handled by CanvasView's MagnifyGesture.
struct CanvasScrollWheelZoomInput: NSViewRepresentable {
    let isEnabled: Bool
    let onScroll: (CGFloat, Bool) -> Void

    func makeNSView(context: Context) -> MonitorView {
        MonitorView(isEnabled: isEnabled, onScroll: onScroll)
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.isEnabled = isEnabled
        nsView.onScroll = onScroll
    }

    @MainActor
    final class MonitorView: NSView {
        var isEnabled: Bool
        var onScroll: (CGFloat, Bool) -> Void
        private var eventMonitor: Any?

        init(isEnabled: Bool, onScroll: @escaping (CGFloat, Bool) -> Void) {
            self.isEnabled = isEnabled
            self.onScroll = onScroll
            super.init(frame: .zero)
            wantsLayer = false
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            removeEventMonitor()
            guard window != nil else { return }

            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event) ?? event
            }
        }

        isolated deinit {
            removeEventMonitor()
        }

        private func removeEventMonitor() {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
            }
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard isEnabled, let window, event.window === window else { return event }

            let location = convert(event.locationInWindow, from: nil)
            guard bounds.contains(location) else { return event }

            // Ordinary wheel/trackpad scrolling continues to move through the vertical canvas.
            // Command-scroll is the explicit macOS zoom convention and avoids stealing that path.
            guard event.modifierFlags.contains(.command) else { return event }

            let delta = event.scrollingDeltaY == 0 ? event.deltaY : event.scrollingDeltaY
            guard delta != 0 else { return event }

            onScroll(delta, event.hasPreciseScrollingDeltas)
            return nil
        }
    }
}
