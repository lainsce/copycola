import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Board.createdAt) private var boards: [Board]
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: UUID?

    private let sidebarWidth: CGFloat = 300

    var body: some View {
        ZStack {
            CopycoaColors.workspaceBackground(for: colorScheme)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(selection: $selection)
                    .frame(maxWidth: sidebarWidth, maxHeight: .infinity)
                    .ignoresSafeArea(.all, edges: .top)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(CopycoaColors.sidebarDivider(for: colorScheme))
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
        .onChange(of: boards.count) { _, _ in
            ensureSelection()
        }
        .focusedSceneValue(\.newCanvasAction) {
            addBoard()
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
}
