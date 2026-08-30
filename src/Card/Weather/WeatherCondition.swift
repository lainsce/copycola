import Foundation

/// The compact visual groups used to translate forecast symbols into card art.
nonisolated enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case storm
    case snow
    case fog

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .storm: "Storm"
        case .snow: "Snow"
        case .fog: "Fog"
        }
    }

    var systemImage: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "snowflake"
        case .fog: "cloud.fog.fill"
        }
    }

    /// Legacy payload metadata retained for persisted/weather compatibility; rendering is Item-based.
    var gradientHexes: (top: String, bottom: String) {
        switch self {
        case .clear: ("568CCA", "A1C8EA")
        case .partlyCloudy: ("668FC5", "9BB9DB")
        case .cloudy: ("66788E", "A5B0BD")
        case .rain: ("435E7D", "7E9AB6")
        case .storm: ("303A50", "69758B")
        case .snow: ("829DBB", "C5D5E5")
        case .fog: ("7F8992", "BAC0C5")
        }
    }

    /// Legacy payload metadata retained for persisted/weather compatibility; rendering uses the accent.
    var secondaryIconColorHex: String {
        switch self {
        case .clear, .partlyCloudy: "FFD52A"
        case .rain, .storm: "9AD8FF"
        case .cloudy, .snow, .fog: "FFFFFF"
        }
    }
}
