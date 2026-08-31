import SwiftUI

/// Displays a weather snapshot using the supplied 1×1 composition as its base design.
struct WeatherCardContent: View {
    let card: Card

    var body: some View {
        GeometryReader { proxy in
            let scale = min(max(min(proxy.size.width, proxy.size.height) / CanvasMetrics.cell, 1), 2)
            let inset = 16 * scale

            ZStack {
                CopycolaColors.itemSurface

                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: card.weatherSummaryValue)
                        .font(.custom("Geist-Regular", size: 12 * scale))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(
                            maxWidth: messageWidth(in: proxy.size, inset: inset),
                            alignment: .leading
                        )
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                    Spacer(minLength: 4 * scale)

                    HStack(alignment: .bottom, spacing: 12 * scale) {
                        VStack(alignment: .trailing, spacing: -10 * scale) {
                            temperature(card.weatherHighTemperatureValue, scale: scale)
                            temperature(card.weatherLowTemperatureValue, scale: scale)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: card.weatherSymbolNameValue)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Color.accent)
                            .font(.system(size: 24 * scale, weight: .medium))
                            .accessibilityHidden(true)
                    }
                }
                .padding(inset)
            }
            .clipShape(.rect(cornerRadius: card.cardSize.cornerRadius))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Weather"))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    private func temperature(_ value: Int, scale: CGFloat) -> some View {
        Text(verbatim: "\(value)°")
            .font(.custom("Geist-Regular", size: 36 * scale))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .lineLimit(1)
    }

    private func messageWidth(in size: CGSize, inset: CGFloat) -> CGFloat {
        let available = max(0, size.width - 2 * inset)
        guard card.cardSize != .oneByOne else { return available }
        return min(available, size.width * 0.5)
    }

    private var accessibilityValue: String {
        let location = card.weatherLocationValue.isEmpty ? "" : "\(card.weatherLocationValue), "
        let condition = String(localized: card.weatherCondition.displayName)
        return "\(location)\(condition), \(card.weatherSummaryValue), high \(card.weatherHighTemperatureValue)\(card.weatherTemperatureUnitLabel), low \(card.weatherLowTemperatureValue)\(card.weatherTemperatureUnitLabel)"
    }
}
