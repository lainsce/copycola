import CoreGraphics
import Testing
@testable import Copycola

struct CanvasZoomTests {
    @Test
    func clampsBloomZoomToReadableBounds() {
        #expect(CanvasZoom.clamped(0) == CanvasZoom.minimum)
        #expect(CanvasZoom.clamped(3) == CanvasZoom.maximum)
        #expect(CanvasZoom.clamped(1.25) == 1.25)
    }

    @Test
    func mapsWheelAndTrackpadDeltasWithoutJumpingPastBounds() {
        let wheel = CanvasZoom.value(
            fromScrollDelta: 1,
            precise: false,
            startingAt: CanvasZoom.defaultValue
        )
        let trackpad = CanvasZoom.value(
            fromScrollDelta: 4,
            precise: true,
            startingAt: CanvasZoom.defaultValue
        )

        #expect(abs(wheel - 1.08) < 0.0001)
        #expect(abs(trackpad - 1.032) < 0.0001)
        #expect(CanvasZoom.value(fromScrollDelta: 100, precise: false, startingAt: 1.75) == CanvasZoom.maximum)
        #expect(CanvasZoom.value(fromScrollDelta: -100, precise: true, startingAt: 0.65) == CanvasZoom.minimum)
    }

    @Test
    func stepsUseTheSameDirectionForKeyboardCommands() {
        #expect(CanvasZoom.stepped(1, direction: 1) == 1.1)
        #expect(CanvasZoom.stepped(1, direction: -1) == 0.9)
        #expect(CanvasZoom.stepped(1, direction: 0) == 1)
    }
}
