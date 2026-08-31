import Foundation
import SwiftUI

/// The three ways a calendar card can describe a date.
nonisolated enum CalendarDateKind: String, Codable, CaseIterable, Identifiable {
    case dateRange
    case singleDate
    case recurring

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .dateRange: "Date Range"
        case .singleDate: "Single Date"
        case .recurring: "Recurring"
        }
    }

    var systemImage: String {
        switch self {
        case .dateRange: "calendar.badge.clock"
        case .singleDate: "calendar"
        case .recurring: "repeat"
        }
    }
}

/// Keeps legacy emoji entry ordered while limiting the persisted value to three positions.
nonisolated func calendarStickerValues(from input: String) -> [String] {
    input
        .filter { !$0.isWhitespace && !$0.isNewline }
        .map(String.init)
        .prefix(3)
        .map { $0 }
}

/// Calendar artwork is authored at the 1×1 footprint (175 points). Larger cards use the same
/// composition and scale it from the shortest available edge, so a 2×1 card stays as legible
/// as the baseline while a 2×2 card gets the extra breathing room shown in the reference.
private struct CalendarCardMetrics {
    let size: CGSize
    let scale: CGFloat

    init(size: CGSize) {
        self.size = size
        scale = max(0.1, min(size.width / CanvasMetrics.cell, size.height / CanvasMetrics.cell))
    }

    func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var padding: CGFloat { CanvasMetrics.cardContentInset }
    var sectionSpacing: CGFloat { scaled(6) }
    var labelFont: CGFloat { CopycolaTypography.Role.caption.size }
    var dateRangeDayFont: CGFloat { CopycolaTypography.Role.bigDisplay.size }
    var singleDateDayFont: CGFloat { CopycolaTypography.Role.bigDisplay.size }
    var yearFont: CGFloat { CopycolaTypography.Role.caption.size }
    var eventTitleFont: CGFloat { CopycolaTypography.Role.body.size }
    var recurringWeekdayFont: CGFloat { CopycolaTypography.Role.display.size }
    var recurringLabelFont: CGFloat { CopycolaTypography.Role.body.size }
    var timelineFont: CGFloat { CopycolaTypography.Role.micro.size }
    var timelineLabelWidth: CGFloat { scaled(44) }
    var timelineSpacing: CGFloat { scaled(5) }
    var timelineEventHeight: CGFloat { scaled(24) }
    var timelineStroke: CGFloat { max(1, scaled(1.5)) }
    var gridColumns: Int { size.width >= 280 ? 7 : 6 }
    var gridRows: Int { size.height >= 280 ? 5 : 4 }
    var gridCell: CGFloat { scaled(11) }
    var gridSpacing: CGFloat { scaled(3) }
    var gridIdealHeight: CGFloat {
        CGFloat(gridRows) * gridCell * 1.35
            + CGFloat(max(0, gridRows - 1)) * gridSpacing
    }
}

/// A compact event card with a clear date hierarchy and a lightweight time rail.
struct CalendarCardContent: View {
    @Bindable var card: Card
    @Environment(\.locale) private var locale

    var body: some View {
        GeometryReader { proxy in
            let metrics = CalendarCardMetrics(size: proxy.size)

            ZStack(alignment: .topLeading) {
                content(metrics: metrics)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(surface)
        .clipShape(.rect(cornerRadius: card.cardSize.cornerRadius))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func content(metrics: CalendarCardMetrics) -> some View {
        switch card.calendarDateKind {
        case .dateRange:
            dateRange(metrics: metrics)
        case .singleDate:
            singleDate(metrics: metrics)
        case .recurring:
            recurring(metrics: metrics)
        }
    }

    private func dateRange(metrics: CalendarCardMetrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthText(card.calendarStartDateValue))
                    .foregroundStyle(Color.accent)
                Spacer(minLength: metrics.sectionSpacing)
                Text("\(rangeDays)d")
                    .foregroundStyle(.secondary)
                Spacer(minLength: metrics.sectionSpacing)
                Text(monthText(card.calendarEndDateValue))
                    .foregroundStyle(Color.accent)
            }
            .font(CopycolaTypography.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            HStack(alignment: .firstTextBaseline) {
                Text(dayText(card.calendarStartDateValue))
                Spacer(minLength: metrics.sectionSpacing)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
                Spacer(minLength: metrics.sectionSpacing)
                Text(dayText(card.calendarEndDateValue))
            }
            .font(CopycolaTypography.bigDisplay)
            .foregroundStyle(.primary)

            Spacer(minLength: metrics.sectionSpacing)

            CalendarTimeline(
                date: card.calendarStartDateValue,
                eventTitle: card.calendarEventTitleValue,
                eventTitleBelowActiveLine: true,
                metrics: metrics
            )
        }
        .padding(metrics.padding)
    }

    private func singleDate(metrics: CalendarCardMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: metrics.sectionSpacing) {
                Text(monthOnlyText(card.calendarStartDateValue))
                    .foregroundStyle(Color.accent)
                Text(shortWeekdayText(card.calendarStartDateValue))
                    .foregroundStyle(.secondary)
            }
            .font(CopycolaTypography.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: 0) {
                Text(dayText(card.calendarStartDateValue))
                    .font(CopycolaTypography.bigDisplay)
                    .foregroundStyle(.primary)


                HStack {
                    if let year = yearText(card.calendarStartDateValue) {
                        Text(verbatim: year)
                            .font(CopycolaTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: metrics.sectionSpacing)
                    let eventTitle = card.calendarEventTitleValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !eventTitle.isEmpty {
                        Text(verbatim: eventTitle)
                        .font(CopycolaTypography.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.7)
                    }
                }
            }

            GeometryReader { proxy in
                let gridScale = min(
                    1,
                    max(0.1, proxy.size.height / max(1, metrics.gridIdealHeight))
                )

                MonthDotGrid(
                    date: card.calendarStartDateValue,
                    calendar: calendar,
                    metrics: metrics,
                    scale: gridScale
                )
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .topLeading
                )
            }
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .padding(metrics.padding)
    }

    private func recurring(metrics: CalendarCardMetrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Every")
                .font(CopycolaTypography.caption)
                .foregroundStyle(Color.accent)

            Text(weekdayText(card.calendarStartDateValue))
                .font(CopycolaTypography.display)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(card.calendarRecurrenceLabelValue)
                .font(CopycolaTypography.body)
                .foregroundStyle(.secondary)

            Spacer(minLength: metrics.sectionSpacing)

            CalendarTimeline(
                date: card.calendarStartDateValue,
                eventTitle: card.calendarEventTitleValue,
                metrics: metrics
            )
        }
        .padding(metrics.padding)
    }

    private var surface: some ShapeStyle {
        CopycolaColors.itemSurface
    }

    private var calendar: Foundation.Calendar {
        var value = Foundation.Calendar(identifier: .gregorian)
        value.locale = locale
        value.timeZone = .current
        return value
    }

    private var rangeDays: Int {
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: card.calendarStartDateValue),
            to: calendar.startOfDay(for: card.calendarEndDateValue)
        )
        return max(1, abs(components.day ?? 1))
    }

    private func monthText(_ date: Date) -> String {
        let month = date.formatted(.dateTime.month(.abbreviated))
        guard !calendar.isDate(date, equalTo: .now, toGranularity: .year) else {
            return month
        }

        return date.formatted(.dateTime.month(.abbreviated).year())
    }

    private func monthOnlyText(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated))
    }

    private func yearText(_ date: Date) -> String? {
        guard !calendar.isDate(date, equalTo: .now, toGranularity: .year) else {
            return nil
        }

        return date.formatted(.dateTime.year())
    }

    private func dayText(_ date: Date) -> String {
        date.formatted(.dateTime.day())
    }

    private func weekdayText(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide))
    }

    private func shortWeekdayText(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
}

private struct MonthDotGrid: View {
    let date: Date
    let calendar: Foundation.Calendar
    let metrics: CalendarCardMetrics
    let scale: CGFloat

    private var cellSize: CGFloat { metrics.gridCell * scale }
    private var rowHeight: CGFloat { cellSize * 1.35 }
    private var spacing: CGFloat { metrics.gridSpacing * scale }

    private var days: [Int?] {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let leading = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let values = Array(repeating: Optional<Int>.none, count: leading)
            + range.map(Optional.some)
        let capacity = metrics.gridColumns * metrics.gridRows
        var compactValues = Array(values.prefix(capacity))
        let selectedDay = calendar.component(.day, from: date)
        if !compactValues.contains(selectedDay), !compactValues.isEmpty {
            compactValues[compactValues.count - 1] = selectedDay
        }
        return compactValues
    }

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: metrics.gridColumns
            ),
            spacing: spacing
        ) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                dayCell(day)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int?) -> some View {
        if let day {
            if day == calendar.component(.day, from: date) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.accent, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Text(verbatim: "\(day)")
                        .font(CopycolaTypography.body)
                        .foregroundStyle(.primary)
                        .fixedSize()
                }
                .frame(width: rowHeight, height: rowHeight)
            } else {
                Circle()
                    .fill(.secondary.opacity(0.14))
                    .frame(width: cellSize, height: cellSize)
                    .frame(width: rowHeight, height: rowHeight)
            }
        } else {
            Color.clear
                .frame(width: rowHeight, height: rowHeight)
        }
    }
}

private struct CalendarTimeline: View {
    let date: Date
    var eventTitle: String?
    var eventTitleBelowActiveLine = false
    let metrics: CalendarCardMetrics

    var body: some View {
        VStack(spacing: metrics.timelineSpacing) {
            timelineRow(date: date.addingTimeInterval(-60 * 60), isActive: false)
            timelineRow(date: date, isActive: true)
            timelineRow(date: date.addingTimeInterval(60 * 60), isActive: false)
        }
    }

    @ViewBuilder
    private func timelineRow(date: Date, isActive: Bool) -> some View {
        HStack(alignment: .center, spacing: metrics.sectionSpacing) {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(CopycolaTypography.micro)
                .foregroundStyle(isActive ? Color.primary : Color.secondary.opacity(0.45))
                .frame(width: metrics.timelineLabelWidth, alignment: .leading)

            if let eventTitle, isActive, eventTitleBelowActiveLine {
                VStack(alignment: .leading, spacing: metrics.scaled(2)) {
                    timelineLine(isActive: true)

                    Text(verbatim: eventTitle)
                        .font(CopycolaTypography.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let eventTitle, isActive {
                RoundedRectangle(cornerRadius: metrics.scaled(6), style: .continuous)
                    .stroke(.secondary.opacity(0.3), lineWidth: metrics.timelineStroke)
                    .frame(height: metrics.timelineEventHeight)
                    .overlay {
                            Text(verbatim: eventTitle)
                            .font(CopycolaTypography.body)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, metrics.sectionSpacing)
                    }
            } else {
                timelineLine(isActive: isActive)
            }
        }
    }

    private func timelineLine(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? Color.accent : .secondary.opacity(0.22))
            .frame(height: isActive ? metrics.timelineStroke : max(1, metrics.scaled(1)))
    }
}
