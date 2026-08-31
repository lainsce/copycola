import MapKit
import SwiftUI

/// A noninteractive map whose controlled camera follows location edits.
struct MapCardContent: View {
    let coordinate: MapCoordinate
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: MapCameraPosition
    @State private var pulse = false

    init(coordinate: MapCoordinate) {
        self.coordinate = coordinate
        _position = State(initialValue: Self.position(for: coordinate))
    }

    var body: some View {
        Map(position: $position, interactionModes: []) {
            // Keep the map annotation visual-only; the containing map remains accessible.
            Annotation("", coordinate: coordinate.coordinate) {
                locationDot
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .saturation(0)
        .onChange(of: coordinate) { _, newCoordinate in
            position = Self.position(for: newCoordinate)
        }
        .accessibilityLabel("Map")
    }

    private var locationDot: some View {
        ZStack {
            Circle()
                .fill(Color.accent.opacity(0.20))
                .frame(width: 48, height: 48)
                .scaleEffect(pulse ? 1 : 0.45)
                .opacity(pulse ? 0 : 0.65)

            Circle()
                .fill(Color.accent)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle().stroke(CopycolaColors.itemSurface, lineWidth: 3)
                }
        }
        .accessibilityHidden(true)
        .onAppear {
            pulse = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            pulse = !shouldReduceMotion
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 1.25).repeatForever(autoreverses: false),
            value: pulse
        )
    }

    private nonisolated static func position(for coordinate: MapCoordinate) -> MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: coordinate.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}
