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
                    CopycoaSidebarRowPressSurface {
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
            reduceMotion ? nil : CopycoaColors.controlMotion,
            value: isHovered
        )
        .animation(
            reduceMotion ? nil : CopycoaColors.navigationMotion,
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
        .accessibilityValue(Text("\(board.cards.count) cards"))
        .contextMenu {
            Button("Rename Canvas", systemImage: "pencil", action: beginEditing)
            Button("Delete Canvas", systemImage: "trash", role: .destructive, action: delete)
        }
    }

    private var rowLabel: some View {
        HStack(spacing: CopycoaColors.controlGap) {
            SidebarCanvasThumbnail(
                cards: board.cards,
                isSelected: isSelected
            )

            VStack(alignment: .leading, spacing: CopycoaColors.gridUnit) {
                Text(verbatim: board.name)
                    .font(CopycoaTypography.contentBlockTitle)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let headerLabel = firstHeaderLabel {
                    Text(verbatim: headerLabel)
                        .font(CopycoaTypography.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, CopycoaColors.gridUnit * 2)
        .padding(.vertical, CopycoaColors.controlGap)
        .background(rowBackground)
        .contentShape(.rect)
    }

    private var firstHeaderLabel: String? {
        guard let header = board.cards.first(where: { $0.kind == .header }) else {
            return nil
        }

        let text = header.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private var nameEditor: some View {
        HStack(spacing: CopycoaColors.controlGap) {
            SidebarCanvasThumbnail(
                cards: board.cards,
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
        .font(CopycoaTypography.contentBlockTitle)
        .padding(.horizontal, CopycoaColors.gridUnit * 2)
        .padding(.vertical, CopycoaColors.controlGap)
        .background(rowBackground)
        .contentShape(.rect)
        .accessibilityLabel(Text("Canvas name"))
    }

    private var rowBackground: some View {
            RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
            .fill(
                isSelected
                    ? Color.accent.opacity(CopycoaColors.sidebarSelectedFillOpacity)
                    : (isHovered
                        ? Color.primary.opacity(CopycoaColors.sidebarHoverFillOpacity)
                        : .clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                    .strokeBorder(
                        Color.accent.opacity(
                            isSelected && isHovered
                                ? CopycoaColors.sidebarSelectedBorderOpacity
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
