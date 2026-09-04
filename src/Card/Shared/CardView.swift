import SwiftUI

/// Renders a single card according to its kind, with selection chrome and inline editing.
struct CardView: View {
    @Bindable var card: Card
    var isSelected: Bool
    var isEditing: Bool
    var isDragging: Bool
    var dragTranslation: CGSize
    var onDelete: () -> Void
    var onEditLink: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if card.kind == .header {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay {
            if isSelected && card.kind != .header {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(CopycolaColors.accent.opacity(0.82), lineWidth: 1)
            }
        }
        .overlay(alignment: .topLeading) {
            if showsSelectionControls {
                deleteButton
                    .offset(x: -8, y: -8)
            }
        }
        .overlay(alignment: .bottom) {
            // Headers are locked to 4×1, so they have no size options and no bottom bar.
            if showsSelectionControls && card.kind != .header {
                controlBar
                    .fixedSize()
                    .offset(y: 26)
            }
        }
        .rotationEffect(.degrees(dragTiltDegrees))
        .animation(
            reduceMotion ? nil : CopycolaColors.controlMotion,
            value: dragTiltDegrees
        )
    }

    private var dragTiltDegrees: Double {
        guard !reduceMotion else { return 0 }
        return CanvasMetrics.cardDragTiltDegrees(for: dragTranslation.width)
    }

    private var cornerRadius: CGFloat {
        card.cardSize.cornerRadius
    }

    private var showsSelectionControls: Bool {
        isSelected && !isDragging
    }

    // MARK: - Per-kind content

    @ViewBuilder
    private var content: some View {
        switch card.kind {
        case .header:
            HeaderCardContent(card: card, isEditing: isEditing)
        case .image:
            ImageCardSurface(card: card, isEditing: isEditing, cornerRadius: cornerRadius)
        }
    }

    // MARK: Selection chrome

    /// Circular delete button, top-left of a selected card.
    private var deleteButton: some View {
        Button("Delete Card", systemImage: "trash", action: onDelete)
            .labelStyle(.iconOnly)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(CopycolaColors.itemText(for: colorScheme).opacity(0.8))
            .frame(width: 30, height: 30)
            .background(Circle().fill(CopycolaColors.itemSurface))
            .buttonStyle(.plain)
            .contentShape(.circle)
            .help(Text("Delete Card"))
    }

    /// Dark bar under a selected image card for its image-specific actions.
    /// Editing is intentionally omitted here because double-click and the Canvas menu already
    /// provide the same route for every card kind.
    private var controlBar: some View {
        HStack(spacing: CopycolaColors.gridUnit) {
            if card.kind == .image {
                actionButtons
            }
        }
        .padding(CopycolaColors.gridUnit)
        .background {
            RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius)
                .fill(.black.opacity(0.82))
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch card.kind {
        case .image:
            barButton("Edit Link", symbol: "link", action: onEditLink)
        default:
            EmptyView()
        }
    }

    private func barButton(
        _ title: LocalizedStringResource,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: symbol, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .buttonStyle(.plain)
            .contentShape(.rect(cornerRadius: CopycolaColors.controlRadius))
            .help(Text(title))
    }
}
