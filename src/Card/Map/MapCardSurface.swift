import SwiftUI

/// Composes the map payload and its optional location caption.
struct MapCardSurface: View {
    let card: Card
    let cornerRadius: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let lat = card.latitude, let lon = card.longitude {
                MapCardContent(coordinate: MapCoordinate(latitude: lat, longitude: lon))
            } else {
                CopycolaColors.itemSurface
            }

            if let title = card.title, !title.isEmpty {
                CardCaptionPill(text: title)
                    .padding(CanvasMetrics.cardContentInset)
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
