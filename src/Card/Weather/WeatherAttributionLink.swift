import SwiftUI

/// Keeps the forecast provider's required attribution visible whenever weather data is shown.
struct WeatherAttributionLink: View {
    private let licenseURL = URL(string: "https://api.met.no/doc/License.html")

    var body: some View {
        if let licenseURL {
            Link(destination: licenseURL) {
                Label("Weather data from MET Norway", systemImage: "cloud.sun")
                    .font(CopycoaTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Based on data from MET Norway; adapted by Copycoa (CC BY 4.0)")
            .accessibilityLabel("Weather data from MET Norway")
        }
    }
}
