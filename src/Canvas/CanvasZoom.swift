import CoreGraphics

/// Bounds and input mapping for Bloom's visual zoom.
///
/// Zoom is a presentation affordance only: persisted card coordinates remain in the same
/// canvas space, so switching back to Grid never changes a card's stored placement.
nonisolated enum CanvasZoom {
    static let minimum: CGFloat = 0.6
    static let maximum: CGFloat = 1.8
    static let defaultValue: CGFloat = 1
    static let keyboardStep: CGFloat = 0.1

    /// Precise trackpads emit small, high-frequency deltas; a wheel emits larger detents.
    static func value(
        fromScrollDelta delta: CGFloat,
        precise: Bool,
        startingAt zoom: CGFloat
    ) -> CGFloat {
        let boundedDelta = min(max(delta, -12), 12)
        let sensitivity: CGFloat = precise ? 0.008 : 0.08
        return clamped(zoom + boundedDelta * sensitivity)
    }

    static func stepped(_ zoom: CGFloat, direction: CGFloat) -> CGFloat {
        let step = direction == 0 ? 0 : (direction > 0 ? keyboardStep : -keyboardStep)
        return clamped(zoom + step)
    }

    static func clamped(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, minimum), maximum)
    }
}
