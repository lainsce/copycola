import CoreLocation
import SwiftUI

/// A curated set of time zones with a representative coordinate for the map treatment.
/// Keeping the coordinate with the IANA identifier makes the card deterministic and avoids
/// trying to infer geography from a time-zone name at render time.
nonisolated struct TimeZoneCardPreset: Identifiable, Sendable {
    let identifier: String
    let city: String
    let latitude: Double
    let longitude: Double

    var id: String { identifier }

    var timeZone: Foundation.TimeZone {
        Foundation.TimeZone(identifier: identifier) ?? .gmt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// A pre-rendered, city-focused crop of the supplied world time-zone map.
    /// Keeping one asset per city avoids relying on AppKit's incomplete SVG renderer.
    var mapAssetName: String {
        switch identifier {
        case "America/Los_Angeles": "LosAngeles"
        case "America/New_York": "NewYork"
        case "America/Sao_Paulo": "SaoPaulo"
        case "Europe/London": "London"
        case "Europe/Rome": "Rome"
        case "Europe/Berlin": "Berlin"
        case "Africa/Cairo": "Cairo"
        case "Asia/Kolkata": "Mumbai"
        case "Asia/Tokyo": "Tokyo"
        case "Australia/Sydney": "Sydney"
        default: "Tokyo"
        }
    }

    /// Normalized position of the representative city in its pre-rendered map crop.
    ///
    /// The supplied SVG contains stylized zone artwork rather than a projection that can
    /// be reliably queried at runtime. These anchors are therefore kept with the preset so
    /// the marker follows the same crop as the highlighted zone, including the few cities
    /// whose visual coastline is intentionally simplified in the source artwork.
    var mapMarkerUnitPoint: CGPoint {
        switch identifier {
        case "America/Los_Angeles": CGPoint(x: 0.4462, y: 0.4658)
        case "America/New_York": CGPoint(x: 0.4858, y: 0.5634)
        case "America/Sao_Paulo": CGPoint(x: 0.3201, y: 0.6547)
        case "Europe/London": CGPoint(x: 0.4650, y: 0.5152)
        case "Europe/Rome": CGPoint(x: 0.4820, y: 0.4449)
        case "Europe/Berlin": CGPoint(x: 0.4601, y: 0.4802)
        case "Africa/Cairo": CGPoint(x: 0.4981, y: 0.4720)
        case "Asia/Kolkata": CGPoint(x: 0.3130, y: 0.3725)
        case "Asia/Tokyo": CGPoint(x: 0.4808, y: 0.5194)
        case "Australia/Sydney": CGPoint(x: 0.5167, y: 0.6461)
        default: CGPoint(x: 0.5, y: 0.5)
        }
    }

    static let all: [Self] = [
        Self(identifier: "America/Los_Angeles", city: "Los Angeles", latitude: 34.0522, longitude: -118.2437),
        Self(identifier: "America/New_York", city: "New York", latitude: 40.7128, longitude: -74.0060),
        Self(identifier: "America/Sao_Paulo", city: "São Paulo", latitude: -23.5505, longitude: -46.6333),
        Self(identifier: "Europe/London", city: "London", latitude: 51.5072, longitude: -0.1276),
        Self(identifier: "Europe/Rome", city: "Rome", latitude: 41.9028, longitude: 12.4964),
        Self(identifier: "Europe/Berlin", city: "Berlin", latitude: 52.5200, longitude: 13.4050),
        Self(identifier: "Africa/Cairo", city: "Cairo", latitude: 30.0444, longitude: 31.2357),
        Self(identifier: "Asia/Kolkata", city: "Mumbai", latitude: 19.0760, longitude: 72.8777),
        Self(identifier: "Asia/Tokyo", city: "Tokyo", latitude: 35.6762, longitude: 139.6503),
        Self(identifier: "Australia/Sydney", city: "Sydney", latitude: -33.8688, longitude: 151.2093),
    ]

    static let defaultPreset = all.first(where: { $0.identifier == "Asia/Tokyo" })!

    static func preset(for identifier: String?) -> Self {
        guard let identifier,
              let preset = all.first(where: { $0.identifier == identifier }) else {
            return defaultPreset
        }
        return preset
    }

}

/// Pure time-zone display calculations kept separate from the SwiftUI rendering layer.
nonisolated enum TimeZoneCardLogic {
    static func isDaytime(at date: Date, in timeZone: Foundation.TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return (6..<18).contains(hour)
    }

    static func offsetText(at date: Date, in timeZone: Foundation.TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds < 0 ? "−" : "+"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3_600
        let minutes = (absoluteSeconds % 3_600) / 60
        let minuteText = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        return "\(sign)\(hours):\(minuteText)"
    }
}

private struct TimeZoneCardMetrics {
    let scale: CGFloat

    init(size: CGSize) {
        scale = max(0.1, min(size.width / 704, size.height / 704))
    }

    func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var padding: CGFloat { max(16, scaled(80)) }
    var titleFont: CGFloat { CopycolaTypography.Role.contentBlockTitle.size }
    var zoneFont: CGFloat { CopycolaTypography.Role.display.size }
    var offsetFont: CGFloat { CopycolaTypography.Role.bigDisplay.size }
    var zoneSpacing: CGFloat { -max(1, scaled(4)) }
}

/// A compact, map-backed time-zone card whose palette follows local daylight at the selected
/// region. The reference composition is authored at the 1×1 footprint and scales from there.
struct TimeZoneCardContent: View {
    @Bindable var card: Card

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let preset = TimeZoneCardPreset.preset(for: card.timeZoneIdentifier)
            let offset = TimeZoneCardLogic.offsetText(at: context.date, in: preset.timeZone)

            GeometryReader { proxy in
                let metrics = TimeZoneCardMetrics(size: proxy.size)

                ZStack(alignment: .topLeading) {
                    TimeZoneMapSurface(preset: preset)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Time Zone")
                            .font(CopycolaTypography.contentBlockTitle)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: metrics.zoneSpacing) {
                            Text("GMT")
                                .font(CopycolaTypography.display)
                                .foregroundStyle(.secondary)
                            Text(offset)
                                .font(CopycolaTypography.bigDisplay)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, metrics.padding)
                    .padding(.vertical, metrics.padding)
                }
                .clipShape(.rect(cornerRadius: card.cardSize.cornerRadius))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Time Zone"))
            .accessibilityValue(Text(verbatim: "\(preset.city), GMT \(offset)"))
        }
    }

}
