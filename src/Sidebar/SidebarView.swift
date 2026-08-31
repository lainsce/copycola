import SwiftUI
import SwiftData

/// The left sidebar listing all boards, with controls to add and select them.
struct SidebarView: View {
    @Query(sort: \Board.createdAt) private var boards: [Board]
    @Environment(\.modelContext) private var context
    @Binding var selection: UUID?
    @State private var boardToDeleteID: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var editingBoardID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: CopycoaColors.controlGap) {
            Text("Canvases").font(CopycoaTypography.viewTitle)

            ForEach(boards) { board in
                SidebarBoardButton(
                    board: board,
                    isSelected: selection == board.id,
                    isEditing: editingBoardID == board.id,
                    select: { selection = board.id },
                    beginEditing: {
                        selection = board.id
                        editingBoardID = board.id
                    },
                    finishEditing: {
                        if editingBoardID == board.id { editingBoardID = nil }
                    },
                    delete: { requestDelete(board) }
                )
            }
        }
        .padding(8)
        .padding(.top, max(0, CanvasMetrics.headerTopInset - 8))
        .frame(width: 300)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(NULSidebarSurface())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Canvas", systemImage: "rectangle.badge.plus", action: addBoard)
                    .labelStyle(.iconOnly)
                    .help(Text("New Canvas"))
                    .buttonStyle(NULToolbarButtonStyle(accented: false))
                    .padding(.leading, 158)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .confirmationDialog(
            "Delete Canvas?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Canvas", role: .destructive, action: deletePendingBoard)
            Button("Cancel", role: .cancel) { boardToDeleteID = nil }
        } message: {
            Text("This also deletes every card in the canvas.")
        }
        .onChange(of: showingDeleteConfirmation) { _, isPresented in
            if !isPresented { boardToDeleteID = nil }
        }
        .focusedSceneValue(\.deleteCanvasAction, deleteCanvasAction)
        .focusedSceneValue(\.renameCanvasAction, renameCanvasAction)
    }

    private func addBoard() {
        let board = Board(
            name: String(
                localized: "Canvas #\(boards.count + 1)",
                comment: "Default canvas name. The variable is the canvas number."
            )
        )
        context.insert(board)
        selection = board.id
    }

    private func requestDelete(_ board: Board) {
        boardToDeleteID = board.id
        showingDeleteConfirmation = true
    }

    private var deleteCanvasAction: (() -> Void)? {
        guard selection != nil else { return nil }
        return deleteSelectedBoard
    }

    private var renameCanvasAction: (() -> Void)? {
        guard let selection else { return nil }
        return { editingBoardID = selection }
    }

    private func deleteSelectedBoard() {
        guard let selection,
              let board = boards.first(where: { $0.id == selection }) else { return }
        requestDelete(board)
    }

    private func deletePendingBoard() {
        guard let boardToDeleteID,
              let board = boards.first(where: { $0.id == boardToDeleteID }) else { return }
        if selection == board.id { selection = nil }
        context.delete(board)
        self.boardToDeleteID = nil
    }
}
