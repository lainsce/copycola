import SwiftUI

/// Keeps a canvas row visually stable while still exposing a restrained pressed state.
/// A keyboard- and accessibility-native board selector with a contextual delete action.
struct SidebarBoardButton: View {
    @Bindable var board: Board
    let isSelected: Bool
    let isEditing: Bool
    let select: () -> Void
    let beginEditing: () -> Void
    let finishEditing: () -> Void
    let delete: () -> Void

    @State private var draftName = ""
    @FocusState private var nameFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Group {
            if isEditing {
                nameEditor
            } else {
                Button(action: select) {
                    CopycolaSidebarRowPressSurface {
                        rowLabel
                    }
                }
                .buttonStyle(NULSidebarButtonStyle())
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        beginEditing()
                    }
                )
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(
            reduceMotion ? nil : CopycolaColors.controlMotion,
            value: isHovered
        )
        .animation(
            reduceMotion ? nil : CopycolaColors.navigationMotion,
            value: isSelected
        )
        .onChange(of: isEditing) { _, editing in
            if editing {
                draftName = board.name
                Task { @MainActor in nameFieldFocused = true }
            } else {
                nameFieldFocused = false
            }
        }
        .onChange(of: nameFieldFocused) { _, focused in
            if !focused && isEditing {
                commitName()
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(Text("\(visibleCards.count) cards"))
        .contextMenu {
            Button("Rename Canvas", systemImage: "pencil", action: beginEditing)
            Button("Delete Canvas", systemImage: "trash", role: .destructive, action: delete)
        }
    }

    private var rowLabel: some View {
        HStack(spacing: CopycolaColors.controlGap) {
            SidebarCanvasThumbnail(
                cards: visibleCards,
                isSelected: isSelected
            )

            VStack(alignment: .leading, spacing: CopycolaColors.gridUnit) {
                Text(verbatim: canvasTitle)
                    .font(CopycolaTypography.contentBlockTitle)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, CopycolaColors.gridUnit * 2)
        .padding(.vertical, CopycolaColors.controlGap)
        .background(rowBackground)
        .contentShape(.rect)
    }

    private var visibleCards: [Card] {
        board.cards.filter { $0.kind != .header }
    }

    private var canvasTitle: String {
        let headerText = board.cards
            .first(where: { $0.kind == .header })?.text
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return headerText.isEmpty ? board.name : headerText
    }

    private var nameEditor: some View {
        HStack(spacing: CopycolaColors.controlGap) {
            SidebarCanvasThumbnail(
                cards: visibleCards,
                isSelected: true
            )

            TextField("Canvas name", text: $draftName)
                .textFieldStyle(.plain)
                .textFieldStyle(NULTextFieldStyle())
                .lineLimit(1)
                .focused($nameFieldFocused)
                .onSubmit(commitName)
                .onExitCommand(perform: cancelName)
        }
        .font(CopycolaTypography.contentBlockTitle)
        .padding(.horizontal, CopycolaColors.gridUnit * 2)
        .padding(.vertical, CopycolaColors.controlGap)
        .background(rowBackground)
        .contentShape(.rect)
        .accessibilityLabel(Text("Canvas name"))
    }

    private var rowBackground: some View {
            RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
            .fill(
                isSelected
                    ? Color.accent.opacity(CopycolaColors.sidebarSelectedFillOpacity)
                    : (isHovered
                        ? Color.primary.opacity(CopycolaColors.sidebarHoverFillOpacity)
                        : .clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                    .strokeBorder(
                        Color.accent.opacity(
                            isSelected && isHovered
                                ? CopycolaColors.sidebarSelectedBorderOpacity
                                : 0
                        ),
                        lineWidth: 1
                    )
            }
    }

    private func commitName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            board.name = trimmed
        }
        finishEditing()
    }

    private func cancelName() {
        draftName = board.name
        finishEditing()
    }
}
