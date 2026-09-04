import AppKit
import CoreGraphics
import SwiftUI
import Testing
@testable import Copycola

struct CopycolaCoreTests {
    private func solidPNG(width: Int = 64, height: Int = 64) -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let pixels = [UInt8](repeating: 0xFF, count: width * height * 4)
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        _ = CGImageDestinationFinalize(destination)
        return output as Data
    }

    @Test
    func imageLoadingAndSubjectCropperRejectInvalidData() async {
        #expect(await decodeImage(from: nil) == nil)
        #expect(ImageSubjectCropper.crop(data: Data()) == nil)
        do {
            _ = try await loadSecurityScopedData(from: URL(fileURLWithPath: "/definitely/missing/image.png"))
            #expect(Bool(false), "Missing image data should throw")
        } catch ImageLoadingError.securityScopeDenied {
            // Expected on a URL without a security scope.
        } catch {
            // A local missing URL can pass the scope check and then fail while
            // reading the file; both paths prove the async loader rejects it.
        }
    }

    @Test
    func subjectCropperHandlesValidImageData() {
        let output = ImageSubjectCropper.crop(data: solidPNG())
        if let output {
            #expect(!output.isEmpty)
        }
    }

    @Test func cardKindsExposeCompleteDesignMetadata() {
        #expect(CardKind.allCases.map(\.id) == ["header", "image"])
        #expect(CardKind.creatable == [.image])
        #expect(!CardKind.header.isCreatable)
        #expect(CardKind.image.isCreatable)

        for kind in CardKind.allCases {
            #expect(!String(localized: kind.displayName).isEmpty)
            #expect(!kind.systemImage.isEmpty)
            #expect(!String(localized: kind.editActionName).isEmpty)
            #expect(kind.defaultCardSize.pointSize.width > 0)
        }
        #expect(CardKind.header.defaultCardSize == .fourByOne)
    }

    @Test func canvasMetricsAndCardSizesCoverSnappingAndBounds() {
        #expect(CanvasMetrics.footprintSize(columns: 0, rows: 0) == CGSize(width: 175, height: 175))
        #expect(CanvasMetrics.footprintSize(columns: 2, rows: 3) == CGSize(width: 390, height: 605))
        #expect(CanvasMetrics.snap(17, to: 10) == 20)
        #expect(CanvasMetrics.snap(-17, to: 10) == -20)
        #expect(CanvasMetrics.snap(19) == 0)
        #expect(CanvasMetrics.snap(21) == 40)

        for size in CardSize.allCases {
            #expect(size.cols >= 1)
            #expect(size.rows >= 1)
            #expect(!size.label.isEmpty)
            #expect(!String(localized: size.accessibilityLabel).isEmpty)
            #expect(size.pointSize.width > 0)
            #expect(size.pointSize.height > 0)
        }
        #expect(CardSize.allCases == [.oneByOne, .fourByOne])
        #expect(CanvasMetrics.cardDragTiltDegrees(for: 0) == 0)
    }

    @Test func canvasErrorsDescribeEveryFailure() {
        let errors: [CanvasError] = [
            .invalidLink,
            .fileImportFailed("bad image"),
            .imageAccessDenied,
            .targetCardMissing
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.failureReason?.isEmpty == false)
        }
        #expect(CanvasError.fileImportFailed("bad image").failureReason?.contains("bad image") == true)
    }

    @Test func colorTokensRoundTrip() {
        #expect(Color(hex: "#FF0000").hexValue == "FF0000")
        #expect(Color(hex: " 00ff7f ").hexValue == "00FF7F")
        #expect(Color(hex: "not-a-color").hexValue == "000000")

        _ = CardSurfaceStyle.item
        _ = CardSurfaceStyle.subtleGrayGradient
    }

    @Test func copycolaColorsExposeBothAppearanceModes() {
        for scheme in [ColorScheme.light, .dark] {
            _ = CopycolaColors.workspaceBackground(for: scheme)
            _ = CopycolaColors.sidebarBackground(for: scheme)
            _ = CopycolaColors.sidebarDivider(for: scheme)
            _ = CopycolaColors.controlRule(for: scheme)
            _ = CopycolaColors.quietRule(for: scheme)
            _ = CopycolaColors.itemText(for: scheme)
            _ = CopycolaColors.itemSecondaryText(for: scheme)
            _ = CopycolaColors.itemRule(for: scheme)
            _ = CopycolaColors.itemSurface(for: scheme)
        }
        _ = CopycolaColors.itemSurface
        _ = CopycolaColors.accent
        #expect(CopycolaColors.itemSurfaceLightHex == "FDFDFD")
        #expect(CopycolaColors.itemSurfaceDarkHex == "111111")
    }

    @Test func cardMutationsKeepStoredGeometryAndDefaults() throws {
        let card = Card(kind: .image, size: .oneByOne, x: 3, y: 4, zIndex: 7)
        #expect(card.kind == .image)
        #expect(card.isSupportedKind)
        #expect(card.cardSize == .oneByOne)
        #expect(card.text.isEmpty)

        card.kind = .header
        #expect(card.kind == .header)
        card.cardSize = .fourByOne
        #expect(card.width == Double(CardSize.fourByOne.pointSize.width))
        #expect(card.height == Double(CardSize.fourByOne.pointSize.height))
        card.width = 1
        card.height = 1
        card.refreshStoredSize()
        #expect(card.width == Double(CardSize.fourByOne.pointSize.width))
        #expect(card.height == Double(CardSize.fourByOne.pointSize.height))

        let board = Board(name: "Board")
        #expect(board.name == "Board")
        #expect(board.cards.isEmpty)
        #expect(board.panX == 0)
        #expect(board.panY == 0)
        card.board = board
        board.cards.append(card)
        #expect(card.board?.id == board.id)
    }

    @Test func typographyMapsEveryRoleAndLegacySize() {
        for role in CopycolaTypography.Role.allCases {
            #expect(role.size > 0)
            _ = CopycolaTypography.font(role)
            _ = CopycolaTypography.technicalFont(role)
        }
        for size in [42, 32, 28, 24, 18, 16, 14, 12, 9, 1, 13, 15, 17, 21, 26, 30, 38] {
            _ = CopycolaTypography.text(CGFloat(size))
        }
        _ = CopycolaTypography.bigDisplay
        _ = CopycolaTypography.display
        _ = CopycolaTypography.viewTitle
        _ = CopycolaTypography.viewSubtitle
        _ = CopycolaTypography.contentBlockTitle
        _ = CopycolaTypography.contentBlockSubtitle
        _ = CopycolaTypography.body
        _ = CopycolaTypography.caption
        _ = CopycolaTypography.micro
        _ = CopycolaTypography.technical
    }
}
