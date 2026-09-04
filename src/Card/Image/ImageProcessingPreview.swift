import AppKit
import SwiftUI

enum ImageProcessingPhase: Equatable {
    case processing
    case settling
    case ready
    case unavailable
}

/// Reviews the Vision cutout before it becomes a permanent image card.
struct ImageProcessingPreview: View {
    @Binding var sourceData: Data?
    @Binding var cutoutData: Data?
    @Binding var phase: ImageProcessingPhase

    let approve: () -> Void
    let cancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sourceImage: NSImage?
    @State private var cutoutImage: NSImage?

    private let mediaColorScheme: ColorScheme = .dark

    var body: some View {
        VStack(alignment: .leading, spacing: CopycolaColors.formRowSpacing) {
            header
            previewSurface
            status
            actionArea
        }
        .padding(CopycolaColors.gridUnit * 3)
        .frame(minWidth: 520, minHeight: 560)
        .background(CopycolaColors.workspaceBackground(for: mediaColorScheme))
        .task(id: sourceData) {
            sourceImage = await decodeImage(from: sourceData)
        }
        .task(id: cutoutData) {
            cutoutImage = await decodeImage(from: cutoutData)
        }
        .environment(\.colorScheme, mediaColorScheme)
        .preferredColorScheme(mediaColorScheme)
        .tint(CopycolaColors.accent)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Image Cutout")
                .font(CopycolaTypography.viewTitle)

            Spacer(minLength: 0)
        }
    }

    private var previewSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous)
                .fill(CopycolaColors.itemSurface(for: mediaColorScheme))

            switch phase {
            case .processing:
                ImageProcessingGrid(exclusionImage: cutoutImage, isMoving: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let sourceImage {
                    processingArtwork(sourceImage, isPulsing: true)
                } else {
                    ProgressView()
                }
            case .settling:
                ImageProcessingGrid(exclusionImage: cutoutImage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let sourceImage {
                    processingArtwork(sourceImage, isPulsing: false)
                } else {
                    ProgressView()
                }
            case .ready:
                if let cutoutImage {
                    cutoutArtwork(cutoutImage)
                } else {
                    ProgressView()
                }
            case .unavailable:
                ImageProcessingGrid()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let sourceImage {
                    sourceArtwork(sourceImage)
                        .opacity(0.56)
                } else {
                    ProgressView()
                }
            }

            previewBadge
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .clipShape(RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CopycolaColors.largeSurfaceRadius, style: .continuous)
                .strokeBorder(CopycolaColors.itemRule(for: mediaColorScheme), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var previewBadge: some View {
        if let previewBadgeText {
            VStack {
                HStack {
                    Text(previewBadgeText)
                        .font(CopycolaTypography.technicalFont(.micro))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, CopycolaColors.controlGap)
                        .padding(.vertical, CopycolaColors.gridUnit)
                        .background(.thinMaterial, in: Capsule())
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .padding(CopycolaColors.controlGap)
        }
    }

    private var previewBadgeText: String? {
        switch phase {
        case .processing:
            return "Finding outline"
        case .settling:
            return "Outline found"
        case .ready:
            return nil
        case .unavailable:
            return "Original"
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: CopycolaColors.gridUnit) {
            switch phase {
            case .processing:
                Label("Finding outline…", systemImage: "sparkles")
                    .foregroundStyle(.secondary)
            case .settling:
                Label("Outline found", systemImage: "checkmark")
                    .foregroundStyle(.secondary)
            case .ready:
                Label("Foreground isolated", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(CopycolaColors.accent)
            case .unavailable:
                Label("No clear foreground was detected.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(CopycolaTypography.body)
    }

    @ViewBuilder
    private var actionArea: some View {
        HStack(spacing: CopycolaColors.controlGap) {
            Spacer(minLength: 0)

            Button("Cancel", action: cancel)
                .buttonStyle(NULButtonStyle(kind: .quiet))

            if phase == .ready, cutoutData != nil {
                Button("Approve Cutout", systemImage: "checkmark") {
                    approve()
                }
                .buttonStyle(NULButtonStyle(kind: .primary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func sourceArtwork(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .padding(CopycolaColors.gridUnit * 3)
    }

    private func processingArtwork(_ image: NSImage, isPulsing: Bool) -> some View {
        ZStack {
            sourceArtwork(image)
                .opacity(0.54)

            // If Vision has already delivered its mask while the review state is still
            // settling, show the subject-following contour immediately.
            if let cutoutImage {
                ImageProcessingGlow(
                    image: cutoutImage,
                    color: CopycolaColors.accent,
                    isPulsing: isPulsing,
                    reduceMotion: reduceMotion
                )
            }
        }
    }

    private func cutoutArtwork(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .padding(CopycolaColors.gridUnit * 3)
    }
}
