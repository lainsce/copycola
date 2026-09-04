import AppKit
import CoreImage
import ImageIO
import Vision

/// Produces a transparent, sticker-like cutout from an imported image.
///
/// Vision supplies the subject pixels and alpha. The white rim is built as a separate,
/// distance-based matte so its thickness follows the detected contour and its outside edge
/// can feather without softening the subject itself.
enum ImageSubjectCropper {
    nonisolated private static let context = CIContext(options: [.useSoftwareRenderer: false])
    nonisolated private static let borderRadius = 16
    nonisolated private static let outerFeather = 4

    nonisolated static func crop(data: Data) -> Data? {
        guard let image = sourceImage(from: data),
              let subjectImage = subjectImage(from: image) else { return nil }
        return stickerPNG(from: subjectImage)
    }

    nonisolated private static func sourceImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    nonisolated private static func subjectImage(from image: CGImage) -> CGImage? {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let maskedBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            let subject = CIImage(cvPixelBuffer: maskedBuffer)
            return context.createCGImage(subject, from: subject.extent.integral)
        } catch {
            return nil
        }
    }

    nonisolated private static func stickerPNG(from image: CGImage) -> Data? {
        guard let rendered = renderedPixels(from: image) else { return nil }
        let width = rendered.width
        let height = rendered.height
        let sourcePixels = rendered.pixels
        let subjectMask = alphaMask(from: sourcePixels, width: width, height: height)
        let outputWidth = width + borderRadius * 2
        let outputHeight = height + borderRadius * 2
        // Pad before measuring distances. Vision crops tightly to the subject, so expanding the
        // unpadded mask would clip the rim anywhere the subject touches an original image edge.
        var paddedMask = [UInt8](repeating: 0, count: outputWidth * outputHeight)
        for y in 0..<height {
            for x in 0..<width {
                paddedMask[(y + borderRadius) * outputWidth + x + borderRadius] = subjectMask[y * width + x]
            }
        }
        let squaredDistances = distanceTransform(paddedMask, width: outputWidth, height: outputHeight)
        let outputPixels = composedPixels(
            source: sourcePixels,
            squaredDistances: squaredDistances,
            width: width,
            height: height,
            outputWidth: outputWidth,
            outputHeight: outputHeight
        )
        return encodePNG(outputPixels, width: outputWidth, height: outputHeight)
    }

    nonisolated private static func renderedPixels(from image: CGImage) -> (width: Int, height: Int, pixels: [UInt8])? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let bitmap = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        bitmap.interpolationQuality = .high
        bitmap.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (width, height, pixels)
    }

    nonisolated private static func composedPixels(
        source: [UInt8],
        squaredDistances: [Int],
        width: Int,
        height: Int,
        outputWidth: Int,
        outputHeight: Int
    ) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)
        for index in 0..<(outputWidth * outputHeight) {
            composePixel(
                at: index,
                source: source,
                squaredDistance: squaredDistances[index],
                width: width,
                height: height,
                outputWidth: outputWidth,
                into: &output
            )
        }
        return output
    }

    nonisolated private static func composePixel(
        at index: Int,
        source: [UInt8],
        squaredDistance: Int,
        width: Int,
        height: Int,
        outputWidth: Int,
        into output: inout [UInt8]
    ) {
        let outputOffset = index * 4
        let rimAlpha = whiteRimAlpha(forSquaredDistance: squaredDistance)

        let outputX = index % outputWidth
        let outputY = index / outputWidth
        let sourceX = outputX - borderRadius
        let sourceY = outputY - borderRadius
        guard sourceX >= 0, sourceX < width, sourceY >= 0, sourceY < height else {
            writeWhiteRimIfNeeded(alpha: rimAlpha, at: outputOffset, into: &output)
            return
        }
        let sourceOffset = (sourceY * width + sourceX) * 4
        let sourceAlpha = source[sourceOffset + 3]
        guard sourceAlpha != 0 else {
            writeWhiteRimIfNeeded(alpha: rimAlpha, at: outputOffset, into: &output)
            return
        }

        writeSourcePixel(
            rimAlpha: rimAlpha,
            source: source,
            sourceOffset: sourceOffset,
            sourceAlpha: sourceAlpha,
            outputOffset: outputOffset,
            into: &output
        )
    }

    nonisolated private static func writeWhiteRimIfNeeded(
        alpha: UInt8,
        at offset: Int,
        into output: inout [UInt8]
    ) {
        guard alpha != 0 else { return }
        writeWhiteRim(alpha: alpha, at: offset, into: &output)
    }

    nonisolated private static func writeSourcePixel(
        rimAlpha: UInt8,
        source: [UInt8],
        sourceOffset: Int,
        sourceAlpha: UInt8,
        outputOffset: Int,
        into output: inout [UInt8]
    ) {
        if rimAlpha != 0 {
            blendPremultipliedPixel(
                source: source,
                sourceOffset: sourceOffset,
                sourceAlpha: sourceAlpha,
                rimAlpha: rimAlpha,
                outputOffset: outputOffset,
                into: &output
            )
        } else {
            copyPixel(
                source: source,
                sourceOffset: sourceOffset,
                sourceAlpha: sourceAlpha,
                outputOffset: outputOffset,
                into: &output
            )
        }
    }

    nonisolated private static func writeWhiteRim(
        alpha: UInt8,
        at offset: Int,
        into output: inout [UInt8]
    ) {
        // The output bitmap is premultiplied-last, so a translucent white pixel stores the
        // white channels multiplied by their alpha rather than leaving an RGB/alpha mismatch.
        output[offset] = alpha
        output[offset + 1] = alpha
        output[offset + 2] = alpha
        output[offset + 3] = alpha
    }

    nonisolated private static func blendPremultipliedPixel(
        source: [UInt8],
        sourceOffset: Int,
        sourceAlpha: UInt8,
        rimAlpha: UInt8,
        outputOffset: Int,
        into output: inout [UInt8]
    ) {
        let sourceOpacity = CGFloat(sourceAlpha) / 255
        let rimOpacity = CGFloat(rimAlpha) / 255
        let compositeOpacity = sourceOpacity + rimOpacity * (1 - sourceOpacity)
        let rimContribution = 255 * rimOpacity * (1 - sourceOpacity)
        output[outputOffset] = clampedByte(CGFloat(source[sourceOffset]) + rimContribution)
        output[outputOffset + 1] = clampedByte(CGFloat(source[sourceOffset + 1]) + rimContribution)
        output[outputOffset + 2] = clampedByte(CGFloat(source[sourceOffset + 2]) + rimContribution)
        output[outputOffset + 3] = clampedByte(compositeOpacity * 255)
    }

    nonisolated private static func clampedByte(_ value: CGFloat) -> UInt8 {
        UInt8(min(255, max(0, value.rounded())))
    }

    nonisolated private static func copyPixel(
        source: [UInt8],
        sourceOffset: Int,
        sourceAlpha: UInt8,
        outputOffset: Int,
        into output: inout [UInt8]
    ) {
        output[outputOffset] = source[sourceOffset]
        output[outputOffset + 1] = source[sourceOffset + 1]
        output[outputOffset + 2] = source[sourceOffset + 2]
        output[outputOffset + 3] = sourceAlpha
    }

    nonisolated private static func encodePNG(_ pixels: [UInt8], width: Int, height: Int) -> Data? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let provider = CGDataProvider(data: Data(pixels) as CFData)
        guard let provider,
              let outputImage = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: width * 4,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) else { return nil }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, outputImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return outputData as Data
    }

    nonisolated private static func alphaMask(from pixels: [UInt8], width: Int, height: Int) -> [UInt8] {
        var mask = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height) where pixels[index * 4 + 3] > 8 {
            mask[index] = 255
        }
        return mask
    }

    /// Returns the exact squared Euclidean distance to the nearest foreground pixel.
    ///
    /// A separable distance transform keeps the rim circular at corners and around narrow
    /// contours without the square bias of a horizontal/vertical dilation kernel.
    nonisolated private static func distanceTransform(
        _ mask: [UInt8],
        width: Int,
        height: Int
    ) -> [Int] {
        guard width > 0, height > 0 else { return [] }
        let infinity = 1_000_000_000
        var horizontal = [Int](repeating: infinity, count: width * height)

        for y in 0..<height {
            var row = [Int](repeating: infinity, count: width)
            for x in 0..<width where mask[y * width + x] != 0 {
                row[x] = 0
            }
            let transformed = squaredDistanceTransform1D(row)
            horizontal.replaceSubrange((y * width)..<((y + 1) * width), with: transformed)
        }

        var distances = [Int](repeating: infinity, count: width * height)
        for x in 0..<width {
            var column = [Int](repeating: infinity, count: height)
            for y in 0..<height {
                column[y] = horizontal[y * width + x]
            }
            let transformed = squaredDistanceTransform1D(column)
            for y in 0..<height {
                distances[y * width + x] = transformed[y]
            }
        }
        return distances
    }

    nonisolated private static func squaredDistanceTransform1D(_ values: [Int]) -> [Int] {
        guard !values.isEmpty else { return [] }

        var envelope = [Int](repeating: 0, count: values.count)
        var intersections = [Double](repeating: 0, count: values.count + 1)
        var distances = [Int](repeating: 0, count: values.count)
        var envelopeCount = 0
        envelope[0] = 0
        intersections[0] = -.infinity
        intersections[1] = .infinity

        for index in 1..<values.count {
            var intersection = parabolaIntersection(
                values,
                left: envelope[envelopeCount],
                right: index
            )
            while intersection <= intersections[envelopeCount] {
                envelopeCount -= 1
                intersection = parabolaIntersection(
                    values,
                    left: envelope[envelopeCount],
                    right: index
                )
            }
            envelopeCount += 1
            envelope[envelopeCount] = index
            intersections[envelopeCount] = intersection
            intersections[envelopeCount + 1] = .infinity
        }

        envelopeCount = 0
        for index in 0..<values.count {
            while intersections[envelopeCount + 1] < Double(index) {
                envelopeCount += 1
            }
            let distance = index - envelope[envelopeCount]
            distances[index] = distance * distance + values[envelope[envelopeCount]]
        }
        return distances
    }

    nonisolated private static func parabolaIntersection(
        _ values: [Int],
        left: Int,
        right: Int
    ) -> Double {
        let leftValue = Double(values[left] + left * left)
        let rightValue = Double(values[right] + right * right)
        return (rightValue - leftValue) / Double(2 * (right - left))
    }

    nonisolated private static func whiteRimAlpha(forSquaredDistance squaredDistance: Int) -> UInt8 {
        let distance = sqrt(CGFloat(squaredDistance))
        let outerRadius = CGFloat(borderRadius)
        guard distance < outerRadius else { return 0 }

        let solidRadius = outerRadius - CGFloat(outerFeather)
        guard distance > solidRadius else { return 255 }

        let progress = (outerRadius - distance) / CGFloat(outerFeather)
        let easedProgress = progress * progress * (3 - 2 * progress)
        return clampedByte(easedProgress * 255)
    }
}
