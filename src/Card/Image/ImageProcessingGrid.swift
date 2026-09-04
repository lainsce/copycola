import AppKit
import SwiftUI

/// A quiet negative-space cue for the cutout review surface. Dots and plus marks only remain
/// visible where the isolated subject is transparent, making the removed background legible.
struct ImageProcessingGrid: View {
    let exclusionImage: NSImage?
    let isMoving: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motionPhase = false
    private let haloClearanceScale: CGFloat = 1.04

    init(exclusionImage: NSImage? = nil, isMoving: Bool = false) {
        self.exclusionImage = exclusionImage
        self.isMoving = isMoving
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let spacing: CGFloat = 42
                let inset: CGFloat = 21
                let dotDiameter: CGFloat = 2
                let plusArm: CGFloat = 3.5
                let dotColor = CopycolaColors.itemRule(for: colorScheme).opacity(0.72)
                let plusColor = CopycolaColors.itemRule(for: colorScheme).opacity(0.95)

                var dots = Path()
                var pluses = Path()
                var row = 0
                var y = inset

                while y <= size.height - inset {
                    var column = 0
                    var x = inset
                    while x <= size.width - inset {
                        if (row + column) % 3 == 0 {
                            pluses.move(to: CGPoint(x: x - plusArm, y: y))
                            pluses.addLine(to: CGPoint(x: x + plusArm, y: y))
                            pluses.move(to: CGPoint(x: x, y: y - plusArm))
                            pluses.addLine(to: CGPoint(x: x, y: y + plusArm))
                        } else {
                            dots.addEllipse(
                                in: CGRect(
                                    x: x - dotDiameter / 2,
                                    y: y - dotDiameter / 2,
                                    width: dotDiameter,
                                    height: dotDiameter
                                )
                            )
                        }
                        column += 1
                        x += spacing
                    }
                    row += 1
                    y += spacing
                }

                context.fill(dots, with: .color(dotColor))
                context.stroke(pluses, with: .color(plusColor), lineWidth: 1)
            }
            .offset(gridOffset)
            .rotationEffect(gridRotation)
            .animation(gridMotionAnimation, value: motionPhase)

            if let exclusionImage {
                Image(nsImage: exclusionImage)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(CopycolaColors.gridUnit)
                    // The glow is blurred beyond the cutout matte. Expand the exclusion just
                    // enough to keep a dot or plus from leaking underneath that halo.
                    .scaleEffect(haloClearanceScale)
                    .foregroundStyle(.black)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            motionPhase = isMoving && !reduceMotion
        }
        .onChange(of: isMoving) { _, moving in
            motionPhase = moving && !reduceMotion
        }
        .onChange(of: reduceMotion) { _, reduced in
            motionPhase = isMoving && !reduced
        }
    }

    private var gridOffset: CGSize {
        guard isMoving, !reduceMotion else { return .zero }
        return motionPhase
            ? CGSize(width: 7, height: -5)
            : CGSize(width: -5, height: 4)
    }

    private var gridRotation: Angle {
        guard isMoving, !reduceMotion else { return .zero }
        return .degrees(motionPhase ? 0.35 : -0.35)
    }

    private var gridMotionAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return isMoving
            ? CopycolaColors.imageProcessingGridMotion
            : CopycolaColors.imageProcessingGridSettle
    }
}
