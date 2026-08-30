import SwiftUI

/// Shared geometric caption treatment used by image and map cards.
struct CardCaptionPill: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(verbatim: text)
            .font(CopycoaTypography.caption)
            .foregroundStyle(.primary)
            .lineLimit(3)
            .padding(.horizontal, 8)
            .padding(.vertical, CopycoaColors.gridUnit * 2)
            .background {
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius, style: .continuous)
                    .strokeBorder(CopycoaColors.itemRule(for: colorScheme).opacity(0.5), lineWidth: 1)
                RoundedRectangle(cornerRadius: CopycoaColors.controlRadius)
                    .fill(CopycoaColors.itemSurface.opacity(0.92))
                    .padding(1)
            }
    }
}
