import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import PDFKit

public final class ImageEngine: Sendable {
    public static let shared = ImageEngine()

    private let safety = FileSafetyService.shared

    public init() {}

    // MARK: - Supported Types

    /// Checks if a given UTType or file extension can be decoded and encoded locally.
    public func isSupportedImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        let supported = ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"]
        return supported.contains(ext)
    }

    public func availableDestinationTypes() -> [String] {
        let identifiers = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return identifiers
    }

    public func isEncoderAvailable(for format: ImageFormat) -> Bool {
        let uti = format.uniformType.identifier
        return availableDestinationTypes().contains(uti)
    }

    // MARK: - Inspection

    /// Inspects an image file to obtain dimensions, format, alpha channel, and color profile.
    public func inspect(url: URL) throws -> FileItem {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ProcessingError.unreadableFile(url)
        }

        guard CGImageSourceGetCount(source) > 0 else {
            throw ProcessingError.corruptedFile("Image contains no decodable frames.")
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
        let hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool ?? false
        let colorModel = properties[kCGImagePropertyColorModel] as? String

        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let fileSize = attributes[.size] as? Int64 ?? 0

        let ext = url.pathExtension.lowercased()
        let formatName: String
        switch ext {
        case "jpg", "jpeg": formatName = "JPEG"
        case "png": formatName = "PNG"
        case "heic": formatName = "HEIC"
        case "webp": formatName = "WebP"
        case "tiff", "tif": formatName = "TIFF"
        default: formatName = ext.uppercased()
        }

        return FileItem(
            url: url,
            filename: url.lastPathComponent,
            fileSize: fileSize,
            category: .image,
            formatName: formatName,
            imageDimensions: (pixelWidth > 0 && pixelHeight > 0) ? CGSize(width: pixelWidth, height: pixelHeight) : nil,
            pageCount: nil,
            hasAlpha: hasAlpha,
            colorSpace: colorModel
        )
    }

    // MARK: - Compression

    /// Compresses an image based on the provided preset.
    /// Preserves transparency for PNG/HEIC/WebP.
    /// Reports accurately if compressed size is larger than original.
    public func compress(
        inputURL: URL,
        preset: CompressionPreset,
        destinationDirectory: URL? = nil,
        stripMetadata: Bool = false
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode image data.")
        }

        let originalDimensions = CGSize(width: cgImage.width, height: cgImage.height)
        var targetDimensions = originalDimensions

        // Calculate dimensional downscaling if Maximum preset is chosen and image is very large
        if preset == .maximum {
            let maxDimension: CGFloat = 2048.0
            if targetDimensions.width > maxDimension || targetDimensions.height > maxDimension {
                let ratio = min(maxDimension / targetDimensions.width, maxDimension / targetDimensions.height)
                targetDimensions = CGSize(
                    width: max(1, floor(targetDimensions.width * ratio)),
                    height: max(1, floor(targetDimensions.height * ratio))
                )
            }
        }

        let processedCGImage: CGImage
        if targetDimensions != originalDimensions {
            processedCGImage = try resizeCGImage(cgImage, to: targetDimensions)
        } else {
            processedCGImage = cgImage
        }

        // Determine destination format based on input format
        let ext = inputURL.pathExtension.lowercased()
        let outputFormat: ImageFormat
        if ext == "png" {
            outputFormat = .png
        } else if ext == "heic" {
            outputFormat = .heic
        } else if ext == "webp" {
            outputFormat = .webp
        } else {
            outputFormat = .jpeg
        }

        let tempURL = try safety.createTemporaryFileURL(extension: outputFormat.fileExtension)
        let uti = outputFormat.uniformType.identifier as CFString

        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.conversionFailed("Could not create image destination for \(outputFormat.rawValue).")
        }

        var options: [CFString: Any] = [:]
        if !stripMetadata, let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            options = props
        }
        if outputFormat != .png {
            options[kCGImageDestinationLossyCompressionQuality] = preset.imageQualityFactor
        }

        CGImageDestinationAddImage(destination, processedCGImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.compressionFailed("Failed to finalize compressed image stream.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .image)

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-compressed",
            targetExtension: outputFormat.fileExtension,
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        var notes: String? = nil
        if outputSize >= fileItem.fileSize {
            notes = "The image was already highly compressed. Output is not smaller than original."
        }

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: originalDimensions,
            outputDimensions: targetDimensions,
            outputFormat: outputFormat.rawValue,
            durationSeconds: duration,
            notes: notes
        )
    }

    // MARK: - Format Conversion

    /// Converts an image to the target format (JPEG, PNG, HEIC, WebP).
    /// Warns or safely composites when converting an image with transparency to a format lacking alpha (like JPEG).
    public func convert(
        inputURL: URL,
        targetFormat: ImageFormat,
        quality: CGFloat = 0.85,
        destinationDirectory: URL? = nil,
        stripMetadata: Bool = false
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode source image.")
        }

        let originalDimensions = CGSize(width: cgImage.width, height: cgImage.height)
        var notes: String? = nil

        var finalCGImage = cgImage

        // Check alpha channel conversion
        if fileItem.hasAlpha == true && !targetFormat.supportsAlpha {
            notes = "Source had transparency. Replaced with white background because \(targetFormat.rawValue) does not support alpha channels."
            finalCGImage = try flattenAlphaToWhite(cgImage)
        }

        let tempURL = try safety.createTemporaryFileURL(extension: targetFormat.fileExtension)
        let uti = targetFormat.uniformType.identifier as CFString

        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.conversionFailed("System cannot encode to \(targetFormat.rawValue).")
        }

        var options: [CFString: Any] = [:]
        if !stripMetadata, let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            options = props
        }
        if targetFormat != .png {
            options[kCGImageDestinationLossyCompressionQuality] = quality
        }

        CGImageDestinationAddImage(destination, finalCGImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.conversionFailed("Failed to finalize destination image.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .image)

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-\(targetFormat.fileExtension)",
            targetExtension: targetFormat.fileExtension,
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: originalDimensions,
            outputDimensions: originalDimensions,
            outputFormat: targetFormat.rawValue,
            durationSeconds: duration,
            notes: notes
        )
    }

    // MARK: - Resizing

    /// Resizes an image according to the specified resize mode while preventing accidental distortion.
    public func resize(
        inputURL: URL,
        mode: ImageResizeMode,
        maintainAspectRatio: Bool = true,
        destinationDirectory: URL? = nil,
        stripMetadata: Bool = false
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode image.")
        }

        let originalDimensions = CGSize(width: cgImage.width, height: cgImage.height)
        let targetDimensions = calculateTargetDimensions(
            original: originalDimensions,
            mode: mode,
            maintainAspectRatio: maintainAspectRatio
        )

        guard targetDimensions.width >= 1 && targetDimensions.height >= 1 else {
            throw ProcessingError.invalidDimensions
        }

        let resizedImage = try resizeCGImage(cgImage, to: targetDimensions)

        let ext = inputURL.pathExtension.lowercased()
        let outputExt = ext.isEmpty ? "jpg" : ext
        let tempURL = try safety.createTemporaryFileURL(extension: outputExt)

        guard let utiString = UTType(filenameExtension: outputExt)?.identifier,
              let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, utiString as CFString, 1, nil) else {
            throw ProcessingError.writeFailed("Unable to create image destination for resizing.")
        }

        var options: [CFString: Any] = [:]
        if !stripMetadata, let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            options = props
        }
        if outputExt != "png" {
            options[kCGImageDestinationLossyCompressionQuality] = 0.90
        }

        CGImageDestinationAddImage(destination, resizedImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.writeFailed("Failed to finalize resized image.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .image)

        let dimSuffix = "-\(Int(targetDimensions.width))x\(Int(targetDimensions.height))"
        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: dimSuffix,
            targetExtension: outputExt,
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: originalDimensions,
            outputDimensions: targetDimensions,
            outputFormat: outputExt.uppercased(),
            durationSeconds: duration
        )
    }

    // MARK: - Batch Processing

    /// Processes multiple images in sequence without overloading memory.
    public func batchProcess(
        urls: [URL],
        action: @escaping @Sendable (URL) async throws -> ConversionResult,
        progressHandler: (@Sendable (Int, Int, URL, Result<ConversionResult, Error>) -> Void)? = nil
    ) async -> [Result<ConversionResult, Error>] {
        var results: [Result<ConversionResult, Error>] = []
        let total = urls.count

        for (index, url) in urls.enumerated() {
            // Check for task cancellation
            if Task.isCancelled {
                let err = Result<ConversionResult, Error>.failure(ProcessingError.cancelled)
                results.append(err)
                progressHandler?(index + 1, total, url, err)
                break
            }

            // Execute each item isolated
            let itemResult: Result<ConversionResult, Error>
            do {
                let res = try await action(url)
                itemResult = .success(res)
            } catch {
                itemResult = .failure(error)
            }

            results.append(itemResult)
            progressHandler?(index + 1, total, url, itemResult)
        }

        return results
    }

    // MARK: - Images to PDF

    /// Combines multiple image files into a single multi-page PDF document.
    public func imagesToPDF(
        imageURLs: [URL],
        pageSize: PDFPageSize = .matchImage,
        destinationDirectory: URL? = nil,
        outputFilename: String = "combined-images.pdf"
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard !imageURLs.isEmpty else {
            throw ProcessingError.emptyInput
        }

        let pdfDocument = PDFDocument()
        var totalOriginalSize: Int64 = 0

        for (index, url) in imageURLs.enumerated() {
            if Task.isCancelled { throw ProcessingError.cancelled }

            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            totalOriginalSize += attributes[.size] as? Int64 ?? 0

            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                continue
            }

            let imgWidth = CGFloat(cgImage.width)
            let imgHeight = CGFloat(cgImage.height)

            let pageBounds: CGRect
            if let standardDims = pageSize.dimensionsInPoints {
                pageBounds = CGRect(origin: .zero, size: standardDims)
            } else {
                pageBounds = CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight)
            }

            // Create image representation
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: imgWidth, height: imgHeight))
            if let page = PDFPage(image: nsImage) {
                page.setBounds(pageBounds, for: .mediaBox)
                pdfDocument.insert(page, at: index)
            }
        }

        guard pdfDocument.pageCount > 0 else {
            throw ProcessingError.conversionFailed("No valid images could be rendered into PDF pages.")
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard pdfDocument.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write generated PDF document.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let baseDir = destinationDirectory ?? imageURLs[0].deletingLastPathComponent()
        var finalURL = baseDir.appendingPathComponent(outputFilename)
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let baseName = (outputFilename as NSString).deletingPathExtension
            finalURL = baseDir.appendingPathComponent("\(baseName) (\(counter)).pdf")
            counter += 1
        }

        try FileManager.default.moveItem(at: tempURL, to: finalURL)

        let outAttributes = (try? FileManager.default.attributesOfItem(atPath: finalURL.path)) ?? [:]
        let outputSize = outAttributes[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: imageURLs[0],
            outputURLs: [finalURL],
            originalSize: totalOriginalSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    // MARK: - Internal Helper Methods

    public func calculateTargetDimensions(
        original: CGSize,
        mode: ImageResizeMode,
        maintainAspectRatio: Bool
    ) -> CGSize {
        switch mode {
        case .original:
            return original

        case .exact(let width, let height):
            let targetW = CGFloat(width)
            let targetH = CGFloat(height)
            if !maintainAspectRatio {
                return CGSize(width: targetW, height: targetH)
            }
            let ratio = min(targetW / original.width, targetH / original.height)
            return CGSize(
                width: max(1, floor(original.width * ratio)),
                height: max(1, floor(original.height * ratio))
            )

        case .maxWidth(let maxW):
            let targetW = CGFloat(maxW)
            if original.width <= targetW { return original }
            let ratio = targetW / original.width
            return CGSize(
                width: targetW,
                height: max(1, floor(original.height * ratio))
            )

        case .maxHeight(let maxH):
            let targetH = CGFloat(maxH)
            if original.height <= targetH { return original }
            let ratio = targetH / original.height
            return CGSize(
                width: max(1, floor(original.width * ratio)),
                height: targetH
            )

        case .percentage(let percent):
            let factor = CGFloat(max(1, percent)) / 100.0
            return CGSize(
                width: max(1, floor(original.width * factor)),
                height: max(1, floor(original.height * factor))
            )
        }
    }

    private func resizeCGImage(_ image: CGImage, to newSize: CGSize) throws -> CGImage {
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = image.bitmapInfo

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw ProcessingError.invalidDimensions
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))

        guard let resized = context.makeImage() else {
            throw ProcessingError.conversionFailed("Failed to render resized image.")
        }

        return resized
    }

    private func flattenAlphaToWhite(_ image: CGImage) throws -> CGImage {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ProcessingError.conversionFailed("Failed to create RGB graphics context.")
        }

        // Draw solid white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw image on top
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let flattened = context.makeImage() else {
            throw ProcessingError.conversionFailed("Failed to create flattened image.")
        }

        return flattened
    }

    // MARK: - Crop Image
    public func crop(
        inputURL: URL,
        aspectRatio: String = "1:1 Square",
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode source image.")
        }

        let origW = CGFloat(cgImage.width)
        let origH = CGFloat(cgImage.height)
        let targetRatio: CGFloat
        switch aspectRatio {
        case "1:1 Square": targetRatio = 1.0
        case "4:3 Standard": targetRatio = 4.0 / 3.0
        case "16:9 Widescreen": targetRatio = 16.0 / 9.0
        case "3:2 Classic": targetRatio = 3.0 / 2.0
        default: targetRatio = 1.0
        }

        var cropW = origW
        var cropH = origH
        if origW / origH > targetRatio {
            cropW = origH * targetRatio
        } else {
            cropH = origW / targetRatio
        }

        let cropX = (origW - cropW) / 2.0
        let cropY = (origH - cropH) / 2.0
        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            throw ProcessingError.conversionFailed("Failed to crop image.")
        }

        let outExt = inputURL.pathExtension.isEmpty ? "jpg" : inputURL.pathExtension.lowercased()
        let tempURL = try safety.createTemporaryFileURL(extension: outExt)
        let uti = (UTType(filenameExtension: outExt)?.identifier ?? UTType.jpeg.identifier) as CFString

        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.writeFailed("Unable to create image destination.")
        }
        CGImageDestinationAddImage(destination, croppedImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.writeFailed("Failed to write cropped image.")
        }

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-cropped",
            targetExtension: outExt,
            destinationDirectory: destinationDirectory
        )
        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outAttr = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outAttr[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: CGSize(width: origW, height: origH),
            outputDimensions: CGSize(width: cropW, height: cropH),
            outputFormat: outExt.uppercased(),
            durationSeconds: duration
        )
    }

    // MARK: - Rotate Image
    public func rotate(
        inputURL: URL,
        degrees: Int = 90,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode source image.")
        }

        let origW = CGFloat(cgImage.width)
        let origH = CGFloat(cgImage.height)
        let radians = CGFloat(degrees) * .pi / 180.0

        let newSize: CGSize
        if degrees == 90 || degrees == 270 {
            newSize = CGSize(width: origH, height: origW)
        } else {
            newSize = CGSize(width: origW, height: origH)
        }

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ProcessingError.conversionFailed("Failed to create graphics context for rotation.")
        }

        context.translateBy(x: newSize.width / 2.0, y: newSize.height / 2.0)
        context.rotate(by: radians)
        context.draw(cgImage, in: CGRect(x: -origW / 2.0, y: -origH / 2.0, width: origW, height: origH))

        guard let rotatedImage = context.makeImage() else {
            throw ProcessingError.conversionFailed("Failed to render rotated image.")
        }

        let outExt = inputURL.pathExtension.isEmpty ? "jpg" : inputURL.pathExtension.lowercased()
        let tempURL = try safety.createTemporaryFileURL(extension: outExt)
        let uti = (UTType(filenameExtension: outExt)?.identifier ?? UTType.jpeg.identifier) as CFString

        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.writeFailed("Unable to create image destination.")
        }
        CGImageDestinationAddImage(destination, rotatedImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.writeFailed("Failed to write rotated image.")
        }

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-rotated-\(degrees)",
            targetExtension: outExt,
            destinationDirectory: destinationDirectory
        )
        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outAttr = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outAttr[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: CGSize(width: origW, height: origH),
            outputDimensions: newSize,
            outputFormat: outExt.uppercased(),
            durationSeconds: duration
        )
    }

    // MARK: - Watermark Image
    public func watermark(
        inputURL: URL,
        text: String = "Confidential",
        opacity: CGFloat = 0.5,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode source image.")
        }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ProcessingError.conversionFailed("Failed to create context.")
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw watermark text using NSGraphicsContext
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        let fontSize = max(CGFloat(width) * 0.04, 24.0)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(opacity)
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attrString.size()
        let point = CGPoint(x: CGFloat(width) - textSize.width - 24, y: 24)
        attrString.draw(at: point)

        NSGraphicsContext.restoreGraphicsState()

        guard let watermarkedImage = context.makeImage() else {
            throw ProcessingError.conversionFailed("Failed to render watermarked image.")
        }

        let outExt = inputURL.pathExtension.isEmpty ? "jpg" : inputURL.pathExtension.lowercased()
        let tempURL = try safety.createTemporaryFileURL(extension: outExt)
        let uti = (UTType(filenameExtension: outExt)?.identifier ?? UTType.jpeg.identifier) as CFString

        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.writeFailed("Unable to create image destination.")
        }
        CGImageDestinationAddImage(destination, watermarkedImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.writeFailed("Failed to write watermarked image.")
        }

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-watermarked",
            targetExtension: outExt,
            destinationDirectory: destinationDirectory
        )
        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outAttr = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outAttr[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: CGSize(width: width, height: height),
            outputDimensions: CGSize(width: width, height: height),
            outputFormat: outExt.uppercased(),
            durationSeconds: duration
        )
    }

    // MARK: - Remove Background
    public func removeBackground(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode source image.")
        }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ProcessingError.conversionFailed("Failed to create context.")
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let transparentImage = context.makeImage() else {
            throw ProcessingError.conversionFailed("Failed to render background-removed image.")
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "png")
        let uti = UTType.png.identifier as CFString
        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.writeFailed("Unable to create PNG destination.")
        }
        CGImageDestinationAddImage(destination, transparentImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.writeFailed("Failed to write PNG image.")
        }

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-transparent",
            targetExtension: "png",
            destinationDirectory: destinationDirectory
        )
        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outAttr = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outAttr[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            originalDimensions: CGSize(width: width, height: height),
            outputDimensions: CGSize(width: width, height: height),
            outputFormat: "PNG",
            durationSeconds: duration
        )
    }

    // MARK: - HEIC to JPG
    public func heicToJpg(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        return try await convert(
            inputURL: inputURL,
            targetFormat: .jpeg,
            quality: 0.90,
            destinationDirectory: destinationDirectory
        )
    }
}
