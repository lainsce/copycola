import CoreGraphics
import Foundation

/// The fixed footprints used by the canvas.
///
/// Body cards intentionally have one canonical footprint. The structural header is
/// the only wider surface; it spans the four-column canvas and is not user-resizable.
nonisolated enum CardSize: String, Codable, CaseIterable, Identifiable {
    case oneByOne
    case fourByOne

    var id: String { rawValue }

    var cols: Int {
        switch self {
        case .oneByOne: 1
        case .fourByOne: 4
        }
    }

    var rows: Int {
        switch self {
        case .oneByOne, .fourByOne: 1
        }
    }

    var label: String {
        switch self {
        case .oneByOne: "1×1"
        case .fourByOne: "4×1"
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .oneByOne: "Image card, 1 by 1"
        case .fourByOne: "Canvas header, 4 by 1"
        }
    }

    /// All supported card surfaces share the same restrained radius.
    var cornerRadius: CGFloat {
        CanvasMetrics.cardCornerRadius
    }

    /// Pixel dimensions of this footprint.
    var pointSize: CGSize {
        switch self {
        case .fourByOne:
            // Header banner: wide enough for four 1×1 cards each separated by one dot.
            let height = CanvasMetrics.headerHeight
            return CGSize(width: CanvasMetrics.fourColumnWidth, height: height)
        case .oneByOne:
            return CanvasMetrics.footprintSize(columns: 1, rows: 1)
        }
    }
}
