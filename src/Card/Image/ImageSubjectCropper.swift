import AppKit
import CoreImage
import ImageIO
import Vision

/// Produces a transparent, sticker-like cutout from an imported image.
///
/// Vision supplies the subject pixels and alpha. The white rim is written into a separate
/// bitmap as opaque pixels, rather than being passed through another alpha blend.
enum ImageSubjectCropper {
    nonisolated private static let context = CIContext(options: [.useSoftwareRenderer: false])
    nonisolated private static let borderRadius = 16

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
        // Pad before dilation. Vision crops tightly to the subject, so dilating the unpadded
        // mask would clip the rim anywhere the subject touches an original image edge.
        var paddedMask = [UInt8](repeating: 0, count: outputWidth * outputHeight)
        for y in 0..<height {
            for x in 0..<width {
                paddedMask[(y + borderRadius) * outputWidth + x + borderRadius] = subjectMask[y * width + x]
            }
        }
        let expandedMask = dilate(paddedMask, width: outputWidth, height: outputHeight, radius: borderRadius)
        let outputPixels = composedPixels(
            source: sourcePixels,
            expandedMask: expandedMask,
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
        expandedMask: [UInt8],
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
                expandedMask: expandedMask,
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
        expandedMask: [UInt8],
        width: Int,
        height: Int,
        outputWidth: Int,
        into output: inout [UInt8]
    ) {
        let outputOffset = index * 4
        let hasStickerRim = expandedMask[index] != 0
        writeRimIfNeeded(hasStickerRim, at: outputOffset, into: &output)

        let outputX = index % outputWidth
        let outputY = index / outputWidth
        let sourceX = outputX - borderRadius
        let sourceY = outputY - borderRadius
        guard sourceX >= 0, sourceX < width, sourceY >= 0, sourceY < height else { return }
        let sourceOffset = (sourceY * width + sourceX) * 4
        let sourceAlpha = source[sourceOffset + 3]
        guard sourceAlpha != 0 else { return }

        writeSourcePixel(
            hasStickerRim: hasStickerRim,
            source: source,
            sourceOffset: sourceOffset,
            sourceAlpha: sourceAlpha,
            outputOffset: outputOffset,
            into: &output
        )
    }

    nonisolated private static func writeRimIfNeeded(
        _ hasStickerRim: Bool,
        at offset: Int,
        into output: inout [UInt8]
    ) {
        if hasStickerRim { writeWhiteRim(at: offset, into: &output) }
    }

    nonisolated private static func writeSourcePixel(
        hasStickerRim: Bool,
        source: [UInt8],
        sourceOffset: Int,
        sourceAlpha: UInt8,
        outputOffset: Int,
        into output: inout [UInt8]
    ) {
        if hasStickerRim {
            blendPremultipliedPixel(
                source: source,
                sourceOffset: sourceOffset,
                sourceAlpha: sourceAlpha,
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

    nonisolated private static func writeWhiteRim(at offset: Int, into output: inout [UInt8]) {
        output[offset] = 255
        output[offset + 1] = 255
        output[offset + 2] = 255
        output[offset + 3] = 255
    }

    nonisolated private static func blendPremultipliedPixel(
        source: [UInt8],
        sourceOffset: Int,
        sourceAlpha: UInt8,
        outputOffset: Int,
        into output: inout [UInt8]
    ) {
        let alpha = CGFloat(sourceAlpha) / 255
        output[outputOffset] = UInt8(min(255, CGFloat(source[sourceOffset]) + 255 * (1 - alpha)))
        output[outputOffset + 1] = UInt8(min(255, CGFloat(source[sourceOffset + 1]) + 255 * (1 - alpha)))
        output[outputOffset + 2] = UInt8(min(255, CGFloat(source[sourceOffset + 2]) + 255 * (1 - alpha)))
        output[outputOffset + 3] = 255
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

    /// Binary dilation using separable sliding windows, avoiding repeated contour artifacts.
    nonisolated private static func dilate(_ mask: [UInt8], width: Int, height: Int, radius: Int) -> [UInt8] {
        verticalDilation(
            horizontalDilation(mask, width: width, height: height, radius: radius),
            width: width,
            height: height,
            radius: radius
        )
    }

    nonisolated private static func horizontalDilation(
        _ mask: [UInt8],
        width: Int,
        height: Int,
        radius: Int
    ) -> [UInt8] {
        var horizontal = [UInt8](repeating: 0, count: mask.count)
        for y in 0..<height {
            let row = dilatedRow(mask, width: width, row: y, radius: radius)
            horizontal.replaceSubrange((y * width)..<((y + 1) * width), with: row)
        }
        return horizontal
    }

    nonisolated private static func dilatedRow(
        _ mask: [UInt8],
        width: Int,
        row: Int,
        radius: Int
    ) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: width)
        var count = initialDilationCount(
            length: width,
            radius: radius,
            valueAt: { x in mask[row * width + x] }
        )
        for x in 0..<width {
            count = updatedDilationCount(
                count: count,
                index: x,
                limit: width,
                radius: radius,
                valueAt: { offset in mask[row * width + offset] }
            )
            result[x] = count > 0 ? 255 : 0
        }
        return result
    }

    nonisolated private static func verticalDilation(
        _ horizontal: [UInt8],
        width: Int,
        height: Int,
        radius: Int
    ) -> [UInt8] {
        var expanded = [UInt8](repeating: 0, count: horizontal.count)
        for x in 0..<width {
            let column = dilatedColumn(horizontal, width: width, height: height, column: x, radius: radius)
            for y in 0..<height {
                expanded[y * width + x] = column[y]
            }
        }
        return expanded
    }

    nonisolated private static func dilatedColumn(
        _ horizontal: [UInt8],
        width: Int,
        height: Int,
        column: Int,
        radius: Int
    ) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: height)
        var count = initialDilationCount(
            length: height,
            radius: radius,
            valueAt: { y in horizontal[y * width + column] }
        )
        for y in 0..<height {
            count = updatedDilationCount(
                count: count,
                index: y,
                limit: height,
                radius: radius,
                valueAt: { offset in horizontal[offset * width + column] }
            )
            result[y] = count > 0 ? 255 : 0
        }
        return result
    }

    nonisolated private static func initialDilationCount(
        length: Int,
        radius: Int,
        valueAt: (Int) -> UInt8
    ) -> Int {
        (0..<min(length, radius + 1)).reduce(into: 0) { count, index in
            if valueAt(index) != 0 { count += 1 }
        }
    }

    nonisolated private static func updatedDilationCount(
        count: Int,
        index: Int,
        limit: Int,
        radius: Int,
        valueAt: (Int) -> UInt8
    ) -> Int {
        guard index > 0 else { return count }
        var result = count
        let added = index + radius
        if added < limit, valueAt(added) != 0 { result += 1 }
        let removed = index - radius - 1
        if removed >= 0, valueAt(removed) != 0 { result -= 1 }
        return result
    }
}
