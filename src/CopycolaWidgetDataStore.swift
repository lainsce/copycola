import AppKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftData
import WidgetKit

/// Publishes board images to Copycoa's widget without exposing the SwiftData store to the
/// extension. Image cards use the board relationship's persisted order, which is the order in
/// which CanvasView appends them. zIndex is intentionally ignored because selection, dragging,
/// and nudging raise cards for display and must not change the widget's added-order cycle.
@MainActor
enum CopycolaWidgetDataStore {
    static let kind = "CopycolaCanvasWidget"

    private static let appGroupIdentifier = "GXLP3297S8.com.github.lainsce.Copycola"
    private static let rootDirectoryName = "copycola-widget"
    private static let metadataFileName = "copycola-widget.json"

    private struct Snapshot: Codable, Sendable {
        let boards: [BoardRecord]
    }

    private struct BoardRecord: Codable, Sendable {
        let id: String
        let name: String
        let images: [ImageRecord]
    }

    private struct ImageRecord: Codable, Sendable {
        let id: String
        let fileName: String
        let order: Int
    }

    static func save(boards: [Board]) {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { return }

        let fileManager = FileManager.default
        let root = container.appendingPathComponent(rootDirectoryName, isDirectory: true)
        try? fileManager.removeItem(at: root)
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        var boardRecords: [BoardRecord] = []
        for board in boards {
            let boardDirectory = root.appendingPathComponent(board.id.uuidString, isDirectory: true)
            try? fileManager.createDirectory(at: boardDirectory, withIntermediateDirectories: true)
            let imageCards = board.cards.filter {
                $0.isSupportedKind && $0.kind == .image && $0.imageData != nil
            }

            var imageRecords: [ImageRecord] = []
            for (order, card) in imageCards.enumerated() {
                guard let imageData = normalizedPNGData(from: card.imageData) else { continue }
                let fileName = "\(card.id.uuidString).png"
                try? imageData.write(
                    to: boardDirectory.appendingPathComponent(fileName),
                    options: .atomic
                )
                imageRecords.append(
                    ImageRecord(id: card.id.uuidString, fileName: fileName, order: order)
                )
            }

            boardRecords.append(
                BoardRecord(id: board.id.uuidString, name: board.name, images: imageRecords)
            )
        }

        guard let data = try? JSONEncoder().encode(Snapshot(boards: boardRecords)) else { return }
        try? data.write(
            to: container.appendingPathComponent(metadataFileName),
            options: .atomic
        )
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private static func normalizedPNGData(from data: Data?) -> Data? {
        guard let data, let image = NSImage(data: data), let cgImage = image.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            "public.png" as CFString,
            1,
            nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
