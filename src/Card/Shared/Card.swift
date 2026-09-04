import Foundation
import SwiftData

/// A single card on a board. Image links remain optional metadata on image cards.
@Model
final class Card {
    var id: UUID
    private var kindRaw: String
    /// Default value lets SwiftData lightweight-migrate stores created before this attribute existed.
    // Retained for lightweight migration from older stores that persisted resize options.
    // New and normalized body cards always use `oneByOne`.
    private var sizeRaw: String = CardSize.oneByOne.rawValue

    /// Top-left position in canvas (content) space, in points.
    var x: Double
    var y: Double
    /// Derived from `cardSize`; stored so snapping math can read it directly.
    var width: Double
    var height: Double
    /// Stacking order; higher draws on top.
    var zIndex: Int

    // Shared / image content.
    var text: String
    @Attribute(.externalStorage) var imageData: Data?
    /// Changes whenever `imageData` is replaced so views can refresh decoded-image caches cheaply.
    var imageRevision: UUID?
    var urlString: String?

    var board: Board?

    init(kind: CardKind, size: CardSize, x: Double, y: Double, zIndex: Int) {
        let canonicalSize: CardSize = kind == .header ? .fourByOne : .oneByOne
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.sizeRaw = canonicalSize.rawValue
        self.x = x
        self.y = y
        self.width = canonicalSize.pointSize.width
        self.height = canonicalSize.pointSize.height
        self.zIndex = zIndex
        self.text = ""
    }

    var kind: CardKind {
        // Unsupported kinds can still exist in a migrated store. They are filtered from the
        // current UI through `isSupportedKind` instead of being misrepresented as an image.
        get { CardKind(rawValue: kindRaw) ?? .image }
        set { kindRaw = newValue.rawValue }
    }

    var isSupportedKind: Bool {
        CardKind(rawValue: kindRaw) != nil
    }

    /// The card's canonical footprint. Body cards are always 1×1; the structural header spans 4×1.
    var cardSize: CardSize {
        get {
            kind == .header ? .fourByOne : .oneByOne
        }
        set {
            let canonicalSize: CardSize = kind == .header ? .fourByOne : .oneByOne
            sizeRaw = canonicalSize.rawValue
            width = canonicalSize.pointSize.width
            height = canonicalSize.pointSize.height
        }
    }

    /// Recomputes stored dimensions after the shared canvas metrics change.
    func refreshStoredSize() {
        let size: CardSize = kind == .header ? .fourByOne : .oneByOne
        sizeRaw = size.rawValue
        width = Double(size.pointSize.width)
        height = Double(size.pointSize.height)
    }

}
