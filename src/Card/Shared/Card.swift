import Foundation
import SwiftData

/// A single card on a board. One model holds every card kind's data; unused fields stay nil.
@Model
final class Card {
    var id: UUID
    private var kindRaw: String
    /// Default value lets SwiftData lightweight-migrate stores created before this attribute existed.
    private var sizeRaw: String = CardSize.twoByTwo.rawValue

    /// Top-left position in canvas (content) space, in points.
    var x: Double
    var y: Double
    /// Derived from `cardSize`; stored so snapping math can read it directly.
    var width: Double
    var height: Double
    /// Stacking order; higher draws on top.
    var zIndex: Int

    // Shared / per-kind content.
    var text: String
    var colorHex: String?
    @Attribute(.externalStorage) var imageData: Data?
    /// Changes whenever `imageData` is replaced so views can refresh decoded-image caches cheaply.
    var imageRevision: UUID?
    var urlString: String?
    var title: String?
    /// Optional description/summary shown on link cards. Optional, so it migrates cleanly.
    var detail: String?
    /// Normalized six-digit CSS theme color from the page's `theme-color` meta tag.
    var themeColorHex: String?
    @Attribute(.externalStorage) var faviconData: Data?
    /// Changes whenever `faviconData` is replaced so views can refresh decoded-image caches cheaply.
    var faviconRevision: UUID?
    var latitude: Double?
    var longitude: Double?

    // Calendar cards keep their event details in optional fields so existing SwiftData stores
    // can lightweight-migrate without requiring a destructive schema change.
    var calendarDateKindRaw: String?
    var calendarStartDate: Date?
    var calendarEndDate: Date?
    var calendarEventTitle: String?
    var calendarEmoji: String?
    var calendarRecurrenceLabel: String?
    /// IANA time-zone identifier used by Time Zone cards, such as `Asia/Tokyo`.
    var timeZoneIdentifier: String?

    // Weather values remain optional so existing stores can lightweight-migrate and cached
    // cards can continue rendering while the network is unavailable.
    var weatherLocation: String?
    var weatherSummary: String?
    var weatherHighTemperature: Int?
    var weatherLowTemperature: Int?
    var weatherConditionRaw: String?
    var weatherSymbolName: String?
    var weatherTemperatureUnitRaw: String?
    var weatherUsesAutomaticSummary: Bool?
    var weatherLastUpdated: Date?
    var weatherDataExpirationDate: Date?
    /// MET Norway validator used to revalidate an expired cached forecast without redownloading it.
    var weatherLastModified: String?

    // Progress cards store a date range and a pair of user-customizable colors.
    var progressStartDate: Date?
    var progressGoalDate: Date?
    var progressDotColorHex: String?
    var progressBackgroundColorHex: String?
    var progressTitle: String?

    // Checklist cards deliberately use three persisted slots so the card stays lightweight
    // and its editor can enforce the three-check limit without a nested transformable array.
    var checklistTitle: String?
    var checklistItemOne: String?
    var checklistItemTwo: String?
    var checklistItemThree: String?
    var checklistCompletedMask: Int?

    // Quote cards keep the quote and attribution separate so the visual hierarchy can remain
    // intentional when the quote text is edited.
    var quoteText: String?
    var quoteAttribution: String?

    // Palette cards persist up to five legacy chip colors as a small JSON string.
    var paletteTitle: String?
    var paletteColorsJSON: String?

    var board: Board?

    init(kind: CardKind, size: CardSize, x: Double, y: Double, zIndex: Int) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.sizeRaw = size.rawValue
        self.x = x
        self.y = y
        self.width = size.pointSize.width
        self.height = size.pointSize.height
        self.zIndex = zIndex
        self.text = ""
        self.colorHex = kind == .stickyNote ? StickyPalette.yellow : nil
        self.themeColorHex = nil

        self.progressStartDate = nil
        self.progressGoalDate = nil
        self.progressDotColorHex = nil
        self.progressBackgroundColorHex = nil
        self.progressTitle = nil
        self.checklistTitle = nil
        self.checklistItemOne = nil
        self.checklistItemTwo = nil
        self.checklistItemThree = nil
        self.checklistCompletedMask = nil
        self.quoteText = nil
        self.quoteAttribution = nil
        self.paletteTitle = nil
        self.paletteColorsJSON = nil

        if kind == .calendar {
            let now = Date()
            self.calendarDateKindRaw = CalendarDateKind.singleDate.rawValue
            self.calendarStartDate = now
            self.calendarEndDate = now.addingTimeInterval(24 * 60 * 60)
            self.calendarEventTitle = "Event"
            self.calendarEmoji = "📅"
            self.calendarRecurrenceLabel = "Weekly"
        } else {
            self.calendarDateKindRaw = nil
            self.calendarStartDate = nil
            self.calendarEndDate = nil
            self.calendarEventTitle = nil
            self.calendarEmoji = nil
            self.calendarRecurrenceLabel = nil
        }

        self.timeZoneIdentifier = kind == .timeZone
            ? TimeZoneCardPreset.defaultPreset.identifier
            : nil

        if kind == .weather {
            self.weatherLocation = ""
            self.weatherSummary = WeatherSummaryGenerator.referenceSummary
            self.weatherHighTemperature = 1
            self.weatherLowTemperature = 1
            self.weatherConditionRaw = WeatherCondition.partlyCloudy.rawValue
            self.weatherSymbolName = WeatherCondition.partlyCloudy.systemImage
            self.weatherTemperatureUnitRaw = "celsius"
            self.weatherUsesAutomaticSummary = true
        }

        if kind == .progress {
            let start = Calendar.current.startOfDay(for: .now)
            self.progressStartDate = start
            self.progressGoalDate = Calendar.current.date(byAdding: .day, value: 30, to: start)
            self.progressDotColorHex = ProgressCardDefaults.dotColorHex
            self.progressBackgroundColorHex = ProgressCardDefaults.backgroundColorHex
            self.progressTitle = "Progress"
        }

        if kind == .checklist {
            self.checklistTitle = "Checklist"
            self.checklistItemOne = "First step"
            self.checklistItemTwo = "Second step"
            self.checklistItemThree = "Third step"
            self.checklistCompletedMask = 0
        }

        if kind == .quote {
            self.quoteText = "Stay hungry. Stay foolish."
            self.quoteAttribution = "Steve Jobs"
        }

        if kind == .palette {
            self.paletteTitle = "Palette"
            self.paletteColorsJSON = PaletteCardDefaults.defaultColorsJSON
        }
    }

    var kind: CardKind {
        get { CardKind(rawValue: kindRaw) ?? .stickyNote }
        set { kindRaw = newValue.rawValue }
    }

    /// The card's footprint. Setting it keeps the top-left anchor and resizes width/height.
    var cardSize: CardSize {
        get { CardSize(rawValue: sizeRaw) ?? .twoByTwo }
        set {
            sizeRaw = newValue.rawValue
            width = newValue.pointSize.width
            height = newValue.pointSize.height
        }
    }

    /// Recomputes stored dimensions after the shared canvas metrics change.
    func refreshStoredSize() {
        let size = cardSize.pointSize
        width = Double(size.width)
        height = Double(size.height)
    }

    var calendarDateKind: CalendarDateKind {
        get { CalendarDateKind(rawValue: calendarDateKindRaw ?? "") ?? .singleDate }
        set { calendarDateKindRaw = newValue.rawValue }
    }

    var calendarStartDateValue: Date {
        get { calendarStartDate ?? Date() }
        set { calendarStartDate = newValue }
    }

    var calendarEndDateValue: Date {
        get { calendarEndDate ?? calendarStartDateValue.addingTimeInterval(24 * 60 * 60) }
        set { calendarEndDate = newValue }
    }

    var calendarEventTitleValue: String {
        get { calendarEventTitle ?? "Event" }
        set { calendarEventTitle = newValue }
    }

    var calendarEmojiValue: String {
        get { calendarEmoji ?? "" }
        set { calendarEmoji = newValue }
    }

    var calendarRecurrenceLabelValue: String {
        get { calendarRecurrenceLabel ?? "Weekly" }
        set { calendarRecurrenceLabel = newValue }
    }

    var timeZoneIdentifierValue: String {
        get { timeZoneIdentifier ?? TimeZoneCardPreset.defaultPreset.identifier }
        set { timeZoneIdentifier = newValue }
    }

    var weatherLocationValue: String {
        get { weatherLocation ?? "" }
        set { weatherLocation = newValue }
    }

    var weatherSummaryValue: String {
        get { weatherSummary ?? WeatherSummaryGenerator.referenceSummary }
        set { weatherSummary = newValue }
    }

    var weatherHighTemperatureValue: Int {
        get { weatherHighTemperature ?? 1 }
        set { weatherHighTemperature = newValue }
    }

    var weatherLowTemperatureValue: Int {
        get { weatherLowTemperature ?? 1 }
        set { weatherLowTemperature = newValue }
    }

    var weatherCondition: WeatherCondition {
        get { WeatherCondition(rawValue: weatherConditionRaw ?? "") ?? .partlyCloudy }
        set { weatherConditionRaw = newValue.rawValue }
    }

    var weatherSymbolNameValue: String {
        get { weatherSymbolName ?? weatherCondition.systemImage }
        set { weatherSymbolName = newValue }
    }

    var weatherTemperatureUnitValue: String {
        get { weatherTemperatureUnitRaw ?? "celsius" }
        set { weatherTemperatureUnitRaw = newValue }
    }

    var weatherTemperatureUnitLabel: String {
        weatherTemperatureUnitValue == "fahrenheit" ? "°F" : "°C"
    }

    var weatherUsesAutomaticSummaryValue: Bool {
        get { weatherUsesAutomaticSummary ?? true }
        set { weatherUsesAutomaticSummary = newValue }
    }

    var progressStartDateValue: Date {
        get { progressStartDate ?? Calendar.current.startOfDay(for: .now) }
        set { progressStartDate = newValue }
    }

    var progressGoalDateValue: Date {
        get {
            progressGoalDate
                ?? Calendar.current.date(byAdding: .day, value: 30, to: progressStartDateValue)
                ?? progressStartDateValue
        }
        set { progressGoalDate = newValue }
    }

    var progressDotColorHexValue: String {
        get { progressDotColorHex ?? ProgressCardDefaults.dotColorHex }
        set { progressDotColorHex = newValue }
    }

    var progressBackgroundColorHexValue: String {
        get { progressBackgroundColorHex ?? ProgressCardDefaults.backgroundColorHex }
        set { progressBackgroundColorHex = newValue }
    }

    var progressTitleValue: String {
        get { progressTitle ?? "Progress" }
        set { progressTitle = newValue }
    }

    var checklistTitleValue: String {
        get { checklistTitle ?? "Checklist" }
        set { checklistTitle = newValue }
    }

    var checklistItemValueOne: String {
        get { checklistItemOne ?? "" }
        set { checklistItemOne = newValue }
    }

    var checklistItemValueTwo: String {
        get { checklistItemTwo ?? "" }
        set { checklistItemTwo = newValue }
    }

    var checklistItemValueThree: String {
        get { checklistItemThree ?? "" }
        set { checklistItemThree = newValue }
    }

    var checklistCompletedMaskValue: Int {
        get { checklistCompletedMask ?? 0 }
        set { checklistCompletedMask = newValue & 0b111 }
    }

    var quoteTextValue: String {
        get { quoteText ?? "Quote" }
        set { quoteText = newValue }
    }

    var quoteAttributionValue: String {
        get { quoteAttribution ?? "" }
        set { quoteAttribution = newValue }
    }

    var paletteTitleValue: String {
        get { paletteTitle ?? "Palette" }
        set { paletteTitle = newValue }
    }

    var paletteColorHexValues: [String] {
        get {
            guard let paletteColorsJSON,
                  let data = paletteColorsJSON.data(using: .utf8),
                  let values = try? JSONDecoder().decode([String].self, from: data),
                  !values.isEmpty else {
                return PaletteCardDefaults.defaultColors
            }
            return Array(values.prefix(PaletteCardDefaults.maximumColors))
        }
        set {
            let values = Array(newValue.prefix(PaletteCardDefaults.maximumColors))
            guard let data = try? JSONEncoder().encode(values) else { return }
            paletteColorsJSON = String(data: data, encoding: .utf8)
        }
    }

    struct ChecklistSlot: Identifiable {
        let id: Int
        let text: String
        let isCompleted: Bool
    }

    var checklistSlots: [ChecklistSlot] {
        let values = [checklistItemValueOne, checklistItemValueTwo, checklistItemValueThree]
        return values.enumerated().compactMap { index, value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return ChecklistSlot(
                id: index,
                text: trimmed,
                isCompleted: checklistCompletedMaskValue & (1 << index) != 0
            )
        }
    }

    func setChecklistCompleted(_ completed: Bool, at index: Int) {
        guard (0..<3).contains(index) else { return }
        let bit = 1 << index
        checklistCompletedMaskValue = completed
            ? checklistCompletedMaskValue | bit
            : checklistCompletedMaskValue & ~bit
    }
}
