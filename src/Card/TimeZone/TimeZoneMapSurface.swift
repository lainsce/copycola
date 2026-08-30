import AppKit
import SwiftUI

/// Loads high-resolution crops generated directly from `WorldTimeZonesMap.svg`.
/// The source uses classed paths for each zone and separate `c`/`n` coastline overlays;
/// the crops preserve those paths while making the card deterministic at runtime because
/// AppKit's SVG importer is not reliable for this map's large, CSS-heavy path set.
@MainActor
private enum TimeZoneMapRenderer {
    private static var cache: [String: NSImage] = [:]

    static func image(for preset: TimeZoneCardPreset) -> NSImage? {
        let assetName = preset.mapAssetName
        if let cached = cache[assetName] {
            return cached
        }

        let url = Bundle.main.url(
            forResource: assetName,
            withExtension: "png",
            subdirectory: "TimeZoneMaps"
        ) ?? Bundle.main.url(forResource: assetName, withExtension: "png")

        guard let url, let image = NSImage(contentsOf: url) else {
            return nil
        }

        cache[assetName] = image
        return image
    }
}

private enum TimeZoneMapLayout {
    /// Each focused crop is rendered to a 1200 × 1200 image by the asset generator.
    private static let sourceSide: CGFloat = 1200
    private static let imageZoom: CGFloat = 1.04

    /// Maps a source-image unit point through the same aspect-fill and zoom transforms
    /// applied to the map image, keeping the city marker on the highlighted city.
    static func markerPosition(for unitPoint: CGPoint, in size: CGSize) -> CGPoint {
        let imageScale = max(size.width / sourceSide, size.height / sourceSide)
        let imageSide = sourceSide * imageScale
        let imageOrigin = CGPoint(
            x: (size.width - imageSide) / 2,
            y: (size.height - imageSide) / 2
        )
        let imagePoint = CGPoint(
            x: imageOrigin.x + unitPoint.x * imageSide,
            y: imageOrigin.y + unitPoint.y * imageSide
        )
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        return CGPoint(
            x: center.x + (imagePoint.x - center.x) * imageZoom,
            y: center.y + (imagePoint.y - center.y) * imageZoom
        )
    }
}

struct TimeZoneMapSurface: View {
    let preset: TimeZoneCardPreset

    var body: some View {
        GeometryReader { proxy in
            let markerPosition = TimeZoneMapLayout.markerPosition(
                for: preset.mapMarkerUnitPoint,
                in: proxy.size
            )

            ZStack {
                CopycoaColors.itemSurface

                if let image = TimeZoneMapRenderer.image(for: preset) {
                    Image(nsImage: image)
                        .interpolation(.high)
                        .resizable()
                        .scaledToFill()
                        .saturation(0)
                        .opacity(0.12)
                        .scaleEffect(1.04)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }

                // The marker follows the crop's source coordinate rather than the card
                // center, so it stays on the selected city at every card aspect ratio.
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.16))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Circle()
                                .stroke(Color.accent.opacity(0.28), lineWidth: 1)
                        }
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 7, height: 7)
                    Circle()
                        .fill(CopycoaColors.itemSurface)
                        .frame(width: 5, height: 5)
                }
                .position(markerPosition)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
