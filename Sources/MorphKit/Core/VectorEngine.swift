import Foundation
import CoreGraphics
import AppKit
import ImageIO

public final class VectorEngine: Sendable {
    public static let shared = VectorEngine()

    private let safety = FileSafetyService.shared

    public init() {}

    // MARK: - SVG to Vector PDF

    public func svgToPDF(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let image = NSImage(contentsOf: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        var size = image.size
        if size.width <= 0 || size.height <= 0 {
            size = CGSize(width: 800, height: 600)
        }

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "vector",
            newExtension: "pdf",
            in: destinationDirectory
        )

        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ProcessingError.writeFailed("Failed to initialize PDF context for SVG.")
        }

        context.beginPage(mediaBox: &mediaBox)

        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        image.draw(in: mediaBox)

        NSGraphicsContext.restoreGraphicsState()
        context.endPage()
        context.closePDF()

        try (pdfData as Data).write(to: destURL, options: .atomic)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: elapsed,
            notes: "Rendered vector SVG into resolution-independent PDF (\(Int(size.width)) × \(Int(size.height)) pt)."
        )
    }

    // MARK: - SVG to Raster Image

    public func svgToImage(
        inputURL: URL,
        targetFormat: ImageFormat = .png,
        scale: CGFloat = 2.0,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let image = NSImage(contentsOf: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        var size = image.size
        if size.width <= 0 || size.height <= 0 {
            size = CGSize(width: 800, height: 600)
        }

        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = (targetFormat == .jpeg)
            ? CGImageAlphaInfo.noneSkipLast.rawValue
            : CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: pixelWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ProcessingError.writeFailed("Failed to create graphics context for rasterizing SVG.")
        }

        if targetFormat == .jpeg {
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        } else {
            context.clear(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        }

        context.scaleBy(x: scale, y: scale)

        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        image.draw(in: CGRect(origin: .zero, size: size))

        NSGraphicsContext.restoreGraphicsState()

        guard let cgImage = context.makeImage() else {
            throw ProcessingError.writeFailed("Failed to capture rasterized SVG image.")
        }

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "\(Int(scale))x",
            newExtension: targetFormat.fileExtension,
            in: destinationDirectory
        )

        let uti = targetFormat.uniformType.identifier as CFString
        guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, uti, 1, nil) else {
            throw ProcessingError.writeFailed("Failed to create raster destination for SVG.")
        }

        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw ProcessingError.writeFailed("Failed to finalize rasterized SVG image.")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: targetFormat.rawValue.uppercased(),
            durationSeconds: elapsed,
            notes: "Rasterized SVG at \(Int(scale))× scale (\(pixelWidth) × \(pixelHeight) px)."
        )
    }
}
