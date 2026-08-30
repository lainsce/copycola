import SwiftUI

/// Renders a single card according to its kind, with selection chrome and inline editing.
struct CardView: View {
    @Bindable var card: Card
    var isSelected: Bool
    var isEditing: Bool
    var isDragging: Bool
    var dragTranslation: CGSize
    var onDelete: () -> Void
    var onSetSize: (CardSize) -> Void
    var onBeginEdit: () -> Void
    var onChooseImage: () -> Void
    var onEditLink: () -> Void
    var onEditLocation: () -> Void
    var onEditCalendar: () -> Void
    var onEditTimeZone: () -> Void
    var onEditWeather: () -> Void
    var onRefreshWeather: () -> Void
    var onEditDetails: () -> Void

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
                    .strokeBorder(Color.accent.opacity(0.82), lineWidth: 1)
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
            reduceMotion ? nil : CopycoaColors.controlMotion,
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
        case .stickyNote:
            StickyNoteCardContent(card: card, isEditing: isEditing, cornerRadius: cornerRadius)
        case .image:
            ImageCardSurface(card: card, isEditing: isEditing, cornerRadius: cornerRadius)
        case .link:
            LinkCardSurface(card: card, cornerRadius: cornerRadius)
        case .map:
            MapCardSurface(card: card, cornerRadius: cornerRadius)
        case .calendar:
            CalendarCardContent(card: card)
        case .timeZone:
            TimeZoneCardContent(card: card)
        case .weather:
            WeatherCardContent(card: card)
        case .progress:
            ProgressCardContent(card: card)
        case .checklist:
            ChecklistCardContent(card: card)
        case .quote:
            QuoteCardContent(card: card)
        case .palette:
            PaletteCardContent(card: card)
        }
    }

    // MARK: Selection chrome

    /// Circular delete button, top-left of a selected card.
    private var deleteButton: some View {
        Button("Delete Card", systemImage: "trash", action: onDelete)
            .labelStyle(.iconOnly)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(CopycoaColors.itemText(for: colorScheme).opacity(0.8))
            .frame(width: 30, height: 30)
            .background(Circle().fill(CopycoaColors.itemSurface))
            .buttonStyle(.plain)
            .help(Text("Delete Card"))
    }

    /// Dark bar under a selected card: size options, then the card's kind-specific actions
    /// (edit text, change image, edit link/location/calendar) after a divider.
    private var controlBar: some View {
        HStack(spacing: CopycoaColors.gridUnit) {
            ForEach(CardSize.selectable) { sizeButton($0) }

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(width: 1, height: 20)
                .padding(.horizontal, CopycoaColors.gridUnit)
            actionButtons
        }
        .padding(CopycoaColors.gridUnit)
        .background {
            RoundedRectangle(cornerRadius: CopycoaColors.largeSurfaceRadius)
                .fill(.black.opacity(0.82))
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch card.kind {
        case .stickyNote:
            barButton("Edit Note", symbol: "pencil", action: onBeginEdit)
        case .image:
            barButton("Change Image", symbol: "photo", action: onChooseImage)
            barButton("Edit Caption", symbol: "text.bubble", action: onBeginEdit)
            barButton("Edit Link", symbol: "link", action: onEditLink)
        case .link:
            barButton("Edit Link", symbol: "pencil", action: onEditLink)
        case .map:
            barButton("Edit Location", symbol: "mappin.and.ellipse", action: onEditLocation)
        case .calendar:
            barButton("Edit Calendar", symbol: "calendar.badge.clock", action: onEditCalendar)
        case .timeZone:
            barButton("Edit Time Zone", symbol: "globe", action: onEditTimeZone)
        case .weather:
            barButton("Refresh Weather", symbol: "arrow.clockwise", action: onRefreshWeather)
            barButton("Edit Weather", symbol: "cloud.sun.fill", action: onEditWeather)
        case .progress:
            barButton("Edit Progress", symbol: "chart.bar.xaxis", action: onEditDetails)
        case .checklist:
            barButton("Edit Checklist", symbol: "checklist", action: onEditDetails)
        case .quote:
            barButton("Edit Quote", symbol: "quote.bubble", action: onEditDetails)
        case .palette:
            barButton("Edit Palette", symbol: "paintpalette", action: onEditDetails)
        case .header:
            EmptyView()
        }
    }

    private func sizeButton(_ size: CardSize) -> some View {
        let selected = card.cardSize == size
        // Proportional glyph representing the footprint's cols × rows.
        let unit: CGFloat = 7
        return Button {
            onSetSize(size)
        } label: {
            Label {
                Text(size.accessibilityLabel)
            } icon: {
                ZStack {
                    RoundedRectangle(cornerRadius: CopycoaColors.controlRadius)
                        .fill(selected ? Color.white : .clear)
                        .frame(width: 28, height: 28)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(selected ? .black.opacity(0.85) : .white.opacity(0.6))
                        .frame(width: unit * CGFloat(size.cols), height: unit * CGFloat(size.rows))
                }
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help(Text(size.accessibilityLabel))
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
            .help(Text(title))
    }
}
