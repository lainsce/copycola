import Foundation
import SwiftData

/// A single card on a board. Shared content fields stay optional where a card kind does not use them.
@Model
final class Card {
    var id: UUID
    private var kindRaw: String
    /// Default value lets SwiftData lightweight-migrate stores created before this attribute existed.
    private var sizeRaw: String = CardSize.twoByTwo.rawValue

    /// Top-left position in canvas (content) space, in points.
    var x: Double
    var y: Double
    /// Derived from `cardSize`; stored so snapping math can read it directly.
    var width: Double
    var height: Double
    /// Stacking order; higher draws on top.
    var zIndex: Int

    // Shared / per-kind content.
    var text: String
    var colorHex: String?
    @Attribute(.externalStorage) var imageData: Data?
    /// Changes whenever `imageData` is replaced so views can refresh decoded-image caches cheaply.
    var imageRevision: UUID?
    var urlString: String?
    var title: String?
    /// Optional description/summary shown on link cards. Optional, so it migrates cleanly.
    var detail: String?
    /// Normalized six-digit CSS theme color from the page's `theme-color` meta tag.
    var themeColorHex: String?
    @Attribute(.externalStorage) var faviconData: Data?
    /// Changes whenever `faviconData` is replaced so views can refresh decoded-image caches cheaply.
    var faviconRevision: UUID?
    var latitude: Double?
    var longitude: Double?

    var board: Board?

    init(kind: CardKind, size: CardSize, x: Double, y: Double, zIndex: Int) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.sizeRaw = size.rawValue
        self.x = x
        self.y = y
        self.width = size.pointSize.width
        self.height = size.pointSize.height
        self.zIndex = zIndex
        self.text = ""
        self.colorHex = kind == .stickyNote ? NoteColorRamp.accent : nil
        self.themeColorHex = nil
    }

    var kind: CardKind {
        get { CardKind(rawValue: kindRaw) ?? .stickyNote }
        set { kindRaw = newValue.rawValue }
    }

    /// The card's footprint. Setting it keeps the top-left anchor and resizes width/height.
    var cardSize: CardSize {
        get { CardSize(rawValue: sizeRaw) ?? .twoByTwo }
        set {
            sizeRaw = newValue.rawValue
            width = newValue.pointSize.width
            height = newValue.pointSize.height
        }
    }

    /// Recomputes stored dimensions after the shared canvas metrics change.
    func refreshStoredSize() {
        let size = cardSize.pointSize
        width = Double(size.width)
        height = Double(size.height)
    }

}
