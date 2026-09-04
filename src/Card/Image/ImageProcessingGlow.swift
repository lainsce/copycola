import AppKit
import SwiftUI

/// Draws the Vision result as a contour-only glow during cutout processing.
///
/// The expanded template supplies the soft halo, while the original alpha is removed from the
/// compositing group. This keeps the interior free of accent graphics and leaves the source
/// artwork readable underneath.
struct ImageProcessingGlow: View {
    let image: NSImage
    let color: Color
    let isPulsing: Bool
    let reduceMotion: Bool

    @State private var pulsePhase = false

    private let contourPadding = CopycolaColors.gridUnit

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(contourPadding)
                .foregroundStyle(color)
                .blur(radius: reduceMotion ? 0.6 : 0.9)
                .shadow(
                    color: color.opacity(reduceMotion ? 0.28 : (isPulsing ? 0.56 : 0.34)),
                    radius: reduceMotion ? 3 : (isPulsing ? 5 : 3)
                )

            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(contourPadding)
                .foregroundStyle(.black)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .opacity(glowOpacity)
        .scaleEffect(glowScale)
        .animation(
            glowAnimation,
            value: pulsePhase
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            pulsePhase = isPulsing && !reduceMotion
        }
        .onChange(of: isPulsing) { _, pulsing in
            pulsePhase = pulsing && !reduceMotion
        }
        .onChange(of: reduceMotion) { _, reduced in
            pulsePhase = isPulsing && !reduced
        }
    }

    private var glowOpacity: Double {
        if reduceMotion { return 0.66 }
        guard isPulsing else { return 0.66 }
        return pulsePhase ? 0.90 : 0.62
    }

    private var glowScale: CGFloat {
        guard isPulsing, !reduceMotion else { return 1 }
        return pulsePhase ? 1.008 : 0.992
    }

    private var glowAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return isPulsing
            ? CopycolaColors.imageProcessingGlowMotion
            : CopycolaColors.imageProcessingGridSettle
    }
}
