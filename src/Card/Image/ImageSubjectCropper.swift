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
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }

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
            guard let subjectImage = context.createCGImage(subject, from: subject.extent.integral) else {
                return nil
            }
            return stickerPNG(from: subjectImage)
        } catch {
            return nil
        }
    }

    nonisolated private static func stickerPNG(from image: CGImage) -> Data? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var sourcePixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let bitmap = CGContext(
            data: &sourcePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        bitmap.interpolationQuality = .high
        bitmap.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

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
        var outputPixels = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

        for outputY in 0..<outputHeight {
            for outputX in 0..<outputWidth {
                let sourceX = outputX - borderRadius
                let sourceY = outputY - borderRadius
                let outputOffset = (outputY * outputWidth + outputX) * 4
                let hasStickerRim = expandedMask[outputY * outputWidth + outputX] != 0

                if hasStickerRim {
                    outputPixels[outputOffset] = 255
                    outputPixels[outputOffset + 1] = 255
                    outputPixels[outputOffset + 2] = 255
                    outputPixels[outputOffset + 3] = 255
                }

                guard sourceX >= 0, sourceX < width, sourceY >= 0, sourceY < height else { continue }
                let sourceOffset = (sourceY * width + sourceX) * 4
                let sourceAlpha = sourcePixels[sourceOffset + 3]
                guard sourceAlpha != 0 else { continue }

                if hasStickerRim {
                    // Source pixels are premultiplied. Composite them over the opaque white rim.
                    let alpha = CGFloat(sourceAlpha) / 255
                    outputPixels[outputOffset] = UInt8(min(255, CGFloat(sourcePixels[sourceOffset]) + 255 * (1 - alpha)))
                    outputPixels[outputOffset + 1] = UInt8(min(255, CGFloat(sourcePixels[sourceOffset + 1]) + 255 * (1 - alpha)))
                    outputPixels[outputOffset + 2] = UInt8(min(255, CGFloat(sourcePixels[sourceOffset + 2]) + 255 * (1 - alpha)))
                    outputPixels[outputOffset + 3] = 255
                } else {
                    outputPixels[outputOffset] = sourcePixels[sourceOffset]
                    outputPixels[outputOffset + 1] = sourcePixels[sourceOffset + 1]
                    outputPixels[outputOffset + 2] = sourcePixels[sourceOffset + 2]
                    outputPixels[outputOffset + 3] = sourceAlpha
                }
            }
        }

        let provider = CGDataProvider(data: Data(outputPixels) as CFData)
        guard let provider,
              let outputImage = CGImage(
                  width: outputWidth,
                  height: outputHeight,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: outputWidth * 4,
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
        var horizontal = [UInt8](repeating: 0, count: mask.count)
        for y in 0..<height {
            var count = 0
            for x in 0..<min(width, radius + 1) where mask[y * width + x] != 0 { count += 1 }
            for x in 0..<width {
                if x > 0 {
                    let added = x + radius
                    if added < width, mask[y * width + added] != 0 { count += 1 }
                    let removed = x - radius - 1
                    if removed >= 0, mask[y * width + removed] != 0 { count -= 1 }
                }
                horizontal[y * width + x] = count > 0 ? 255 : 0
            }
        }

        var expanded = [UInt8](repeating: 0, count: mask.count)
        for x in 0..<width {
            var count = 0
            for y in 0..<min(height, radius + 1) where horizontal[y * width + x] != 0 { count += 1 }
            for y in 0..<height {
                if y > 0 {
                    let added = y + radius
                    if added < height, horizontal[added * width + x] != 0 { count += 1 }
                    let removed = y - radius - 1
                    if removed >= 0, horizontal[removed * width + x] != 0 { count -= 1 }
                }
                expanded[y * width + x] = count > 0 ? 255 : 0
            }
        }
        return expanded
    }
}
