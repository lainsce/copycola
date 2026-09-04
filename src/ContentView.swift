import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Board.createdAt) private var boards: [Board]
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: UUID?
    @AppStorage("copycola.has-completed-first-run") private var hasCompletedFirstRun = false

    private let sidebarWidth: CGFloat = 300

    var body: some View {
        ZStack {
            CopycolaColors.workspaceBackground(for: colorScheme)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(selection: $selection)
                    .frame(maxWidth: sidebarWidth, maxHeight: .infinity)
                    .ignoresSafeArea(.all, edges: .top)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(CopycolaColors.sidebarDivider(for: colorScheme))
                            .frame(width: 1)
                            .allowsHitTesting(false)
                    }

                detail
                    .ignoresSafeArea(.container, edges: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(.all, edges: .top)
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: ensureSelection)
        .task {
            CopycolaWidgetDataStore.save(boards: boards)
        }
        .onChange(of: boards.count) { _, _ in
            ensureSelection()
        }
        .onChange(of: widgetRevision) { _, _ in
            CopycolaWidgetDataStore.save(boards: boards)
        }
        .focusedSceneValue(\.newCanvasAction) {
            addBoard()
        }
        .sheet(isPresented: firstRunBinding) {
            CopycolaFirstRunView(onContinue: finishFirstRun)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let id = selection, let board = boards.first(where: { $0.id == id }) {
            CanvasView(board: board)
                .id(board.id)
        } else {
            ContentUnavailableView(
                "Select or create a canvas",
                systemImage: "rectangle.dashed"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func ensureSelection() {
        if boards.isEmpty {
            let board = Board(name: defaultBoardName(number: 1))
            context.insert(board)
            selection = board.id
        } else if selection == nil || !boards.contains(where: { $0.id == selection }) {
            selection = boards.first?.id
        }
    }

    private func addBoard() {
        let board = Board(name: defaultBoardName(number: boards.count + 1))
        context.insert(board)
        selection = board.id
    }

    private func defaultBoardName(number: Int) -> String {
        String(
            localized: "Canvas #\(number)",
            comment: "Default canvas name. The variable is the canvas number."
        )
    }

    private var firstRunBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedFirstRun },
            set: { isPresented in
                if !isPresented {
                    finishFirstRun()
                }
            }
        )
    }

    private func finishFirstRun() {
        hasCompletedFirstRun = true
    }

    /// Reads the persisted fields that affect the widget so card inserts, deletes, and image
    /// replacements refresh the shared snapshot even though the top-level board query itself
    /// does not change count.
    private var widgetRevision: String {
        boards.map { board in
            let cardRevision = board.cards.map { card in
                "\(card.id.uuidString):\(card.kind.rawValue):\(card.zIndex):\(card.imageRevision?.uuidString ?? "none")"
            }.joined(separator: ",")
            return "\(board.id.uuidString):\(board.name):\(cardRevision)"
        }.joined(separator: "|")
    }
}
