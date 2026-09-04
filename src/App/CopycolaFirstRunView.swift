import SwiftUI

/// Explains Copycola's canvas/card workflow once, while leaving the first
/// canvas selected by the main content view.
struct CopycolaFirstRunView: View {
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: CopycolaColors.gridUnit * 2) {
                Text("Copycola")
                    .font(CopycolaTypography.viewTitle)

                Text("Collect visual references on canvases.")
                    .font(CopycolaTypography.viewSubtitle)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, CopycolaColors.gridUnit * 6)

            Text("Your first canvas is ready. Add images as cards, then arrange them on the grid.")
                .font(CopycolaTypography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, CopycolaColors.gridUnit * 6)

            VStack(alignment: .leading, spacing: CopycolaColors.gridUnit * 5) {
                instruction(
                    systemImage: "plus",
                    title: "Add an image",
                    detail: "Use the Add Image button or drag an image file onto the canvas."
                )
                instruction(
                    systemImage: "arrow.up.and.down.and.arrow.left.and.right",
                    title: "Arrange cards",
                    detail: "Drag a card to place it on the grid. Select it for its actions."
                )
                instruction(
                    systemImage: "pencil",
                    title: "Edit a card",
                    detail: "Double-click a card to edit its caption; use Edit Link for an image link."
                )
            }

            Spacer(minLength: CopycolaColors.gridUnit * 6)

            HStack {
                Spacer(minLength: 0)
                Button("Start arranging", action: onContinue)
                    .buttonStyle(NULButtonStyle(kind: .primary))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(CopycolaColors.gridUnit * 6)
        .background(
            CopycolaColors.itemSurface(for: colorScheme),
            in: RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous)
        )
        .frame(minWidth: 460, idealWidth: 500, minHeight: 400)
        .background(CopycolaColors.workspaceBackground(for: colorScheme))
    }

    private func instruction(
        systemImage: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: CopycolaColors.gridUnit * 4) {
            Image(systemName: systemImage)
                .font(.system(size: CopycolaColors.toolbarIconSize, weight: .regular))
                .frame(width: CopycolaColors.controlHeight, height: CopycolaColors.controlHeight)
                .background(
                    CopycolaColors.workspaceBackground(for: colorScheme),
                    in: RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CopycolaColors.gridUnit) {
                Text(title)
                    .font(CopycolaTypography.contentBlockTitle)

                Text(detail)
                    .font(CopycolaTypography.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
