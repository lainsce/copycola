import AppIntents
import AppKit
import Foundation
import SwiftUI
import WidgetKit

nonisolated private enum CopycolaWidgetConstants {
    static let kind = "CopycolaCanvasWidget"
    static let rootDirectoryName = "copycola-widget"
    static let metadataFileName = "copycola-widget.json"
    static let appGroupIdentifier = "GXLP3297S8.com.github.lainsce.Copycola"
}

nonisolated struct CopycolaWidgetImageRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let fileName: String
    let order: Int
}

nonisolated struct CopycolaWidgetBoardRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let images: [CopycolaWidgetImageRecord]
}

nonisolated struct CopycolaWidgetSnapshot: Codable, Sendable {
    let boards: [CopycolaWidgetBoardRecord]

    nonisolated static func load() -> CopycolaWidgetSnapshot {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: CopycolaWidgetConstants.appGroupIdentifier
        ) else {
            return CopycolaWidgetSnapshot(boards: [])
        }
        let url = container.appendingPathComponent(CopycolaWidgetConstants.metadataFileName)
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(Self.self, from: data) else {
            return CopycolaWidgetSnapshot(boards: [])
        }
        return snapshot
    }

    nonisolated static func imageData(
        for image: CopycolaWidgetImageRecord,
        boardID: String
    ) -> Data? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: CopycolaWidgetConstants.appGroupIdentifier
        ) else { return nil }
        let url = container
            .appendingPathComponent(CopycolaWidgetConstants.rootDirectoryName, isDirectory: true)
            .appendingPathComponent(boardID, isDirectory: true)
            .appendingPathComponent(image.fileName)
        return try? Data(contentsOf: url)
    }
}

struct CopycolaWidgetBoardEntity: AppEntity, Hashable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Canvas")
    static let defaultQuery = CopycolaWidgetBoardQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name.isEmpty ? "Untitled canvas" : name))
    }
}

struct CopycolaWidgetBoardQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CopycolaWidgetBoardEntity] {
        let boards = CopycolaWidgetSnapshot.load().boards
        return identifiers.compactMap { id in
            guard let board = boards.first(where: { $0.id == id }) else { return nil }
            return CopycolaWidgetBoardEntity(id: board.id, name: board.name)
        }
    }

    func suggestedEntities() async throws -> [CopycolaWidgetBoardEntity] {
        CopycolaWidgetSnapshot.load().boards.map {
            CopycolaWidgetBoardEntity(id: $0.id, name: $0.name)
        }
    }
}

struct SelectCopycolaBoardIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Canvas"
    static let description = IntentDescription("Choose which Copycoa canvas the widget shows.")

    @Parameter(title: "Canvas")
    var board: CopycolaWidgetBoardEntity?

    init() {}
}

struct CopycolaWidgetEntry: TimelineEntry {
    let date: Date
    let board: CopycolaWidgetBoardRecord?
    let activeIndex: Int
}

struct CopycolaCanvasProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> CopycolaWidgetEntry {
        CopycolaWidgetEntry(date: .now, board: nil, activeIndex: 0)
    }

    func snapshot(
        for configuration: SelectCopycolaBoardIntent,
        in _: Context
    ) async -> CopycolaWidgetEntry {
        entry(for: configuration, activeIndex: 0)
    }

    func timeline(
        for configuration: SelectCopycolaBoardIntent,
        in _: Context
    ) async -> Timeline<CopycolaWidgetEntry> {
        let snapshot = CopycolaWidgetSnapshot.load()
        let selectedID = configuration.board?.id
        let board = snapshot.boards.first(where: { $0.id == selectedID }) ?? snapshot.boards.first
        let imageCount = board?.images.count ?? 0
        let count = max(imageCount, 1)
        let start = Date.now
        let entries = (0..<count).map { index in
            let date = Calendar.current.date(byAdding: .minute, value: index * 15, to: start)
                ?? start.addingTimeInterval(Double(index) * 900)
            return CopycolaWidgetEntry(date: date, board: board, activeIndex: index)
        }
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: max(count, 1) * 15, to: start)
            ?? start.addingTimeInterval(Double(max(count, 1)) * 900)
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }

    private func entry(
        for configuration: SelectCopycolaBoardIntent,
        activeIndex: Int
    ) -> CopycolaWidgetEntry {
        let snapshot = CopycolaWidgetSnapshot.load()
        let selectedID = configuration.board?.id
        let board = snapshot.boards.first(where: { $0.id == selectedID }) ?? snapshot.boards.first
        return CopycolaWidgetEntry(date: .now, board: board, activeIndex: activeIndex)
    }
}

struct CopycolaCanvasWidgetEntryView: View {
    let entry: CopycolaWidgetEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    /// Clear and accented widgets use a white, opacity-based treatment for
    /// artwork. Keep the source image untouched in full-color contexts.
    private var artworkRenderingMode: WidgetAccentedRenderingMode? {
        if renderingMode == .fullColor {
            return nil
        }
        if renderingMode == .accented {
            return .accentedDesaturated
        }
        return .desaturated
    }

    var body: some View {
        Group {
            if let board = entry.board, !board.images.isEmpty {
                if family == .systemSmall {
                    singleImage(board: board)
                } else {
                    flattenedStrip(board: board)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(widgetURL)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    @ViewBuilder
    private func singleImage(board: CopycolaWidgetBoardRecord) -> some View {
        let image = board.images[entry.activeIndex % board.images.count]
        if let data = CopycolaWidgetSnapshot.imageData(for: image, boardID: board.id),
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.none)
                .antialiased(false)
                .widgetAccentedRenderingMode(artworkRenderingMode)
                .scaledToFit()
        } else {
            imagePlaceholder
        }
    }

    @ViewBuilder
    private func flattenedStrip(board: CopycolaWidgetBoardRecord) -> some View {
        let center = entry.activeIndex % board.images.count
        let positions = [-1, 0, 1]
        ZStack {
            ForEach(positions, id: \.self) { position in
                let index = (center + position + board.images.count) % board.images.count
                let image = board.images[index]
                if let data = CopycolaWidgetSnapshot.imageData(for: image, boardID: board.id),
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.none)
                        .antialiased(false)
                        .widgetAccentedRenderingMode(artworkRenderingMode)
                        .scaledToFit()
                        .frame(
                            maxWidth: position == 0 ? 118 : 86,
                            maxHeight: position == 0 ? 118 : 92
                        )
                        .scaleEffect(position == 0 ? 1 : 0.82)
                        .offset(x: CGFloat(position) * 76)
                        .zIndex(position == 0 ? 2 : 1)
                }
            }
        }
        .clipped()
        .overlay(alignment: .bottomLeading) {
            Text(board.name.isEmpty ? "Untitled canvas" : board.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .padding(.bottom, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.title2)
            Text("Add an image to a canvas in Copycoa")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
        }
    }

    private var imagePlaceholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.secondary)
    }

    private var widgetURL: URL? {
        guard let board = entry.board else { return URL(string: "copycola://new") }
        return URL(string: "copycola://canvas/\(board.id)")
    }
}

struct CopycolaCanvasWidget: Widget {
    let kind = CopycolaWidgetConstants.kind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCopycolaBoardIntent.self,
            provider: CopycolaCanvasProvider()
        ) { entry in
            CopycolaCanvasWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Canvas Showcase")
        .description("Cycle through the images in a Copycoa canvas.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct CopycolaWidgetBundle: WidgetBundle {
    var body: some Widget {
        CopycolaCanvasWidget()
    }
}
