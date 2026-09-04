import SwiftUI

/// Shared geometric caption treatment used by image cards.
struct CardCaptionPill: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(verbatim: text)
            .font(CopycolaTypography.caption)
            .foregroundStyle(.primary)
            .lineLimit(3)
            .padding(.horizontal, 8)
            .padding(.vertical, CopycolaColors.gridUnit * 2)
            .background {
                RoundedRectangle(cornerRadius: CopycolaColors.controlRadius, style: .continuous)
                    .strokeBorder(CopycolaColors.itemRule(for: colorScheme).opacity(0.5), lineWidth: 1)
                RoundedRectangle(cornerRadius: CopycolaColors.controlRadius)
                    .fill(CopycolaColors.itemSurface.opacity(0.92))
                    .padding(1)
            }
    }
}
