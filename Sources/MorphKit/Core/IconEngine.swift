import Foundation
import CoreGraphics
import ImageIO
import AppKit

public final class IconEngine: Sendable {
    public static let shared = IconEngine()

    private let safety = FileSafetyService.shared
    private let engineManager = EngineManager.shared

    public init() {}

    // MARK: - Convert Image to macOS .icns

    public func convertToICNS(
        imageURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let masterImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.unreadableFile(imageURL)
        }

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: imageURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        // Create temporary iconset folder
        let tempDir = FileManager.default.temporaryDirectory
        let iconsetName = "morph_\(UUID().uuidString.prefix(8)).iconset"
        let iconsetURL = tempDir.appendingPathComponent(iconsetName)
        try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: iconsetURL)
        }

        // Standard Apple iconset resolutions
        let iconSizes: [(name: String, pixelSize: Int)] = [
            ("icon_16x16.png", 16),
            ("icon_16x16@2x.png", 32),
            ("icon_32x32.png", 32),
            ("icon_32x32@2x.png", 64),
            ("icon_128x128.png", 128),
            ("icon_128x128@2x.png", 256),
            ("icon_256x256.png", 256),
            ("icon_256x256@2x.png", 512),
            ("icon_512x512.png", 512),
            ("icon_512x512@2x.png", 1024)
        ]

        let masterWidth = CGFloat(masterImage.width)
        let masterHeight = CGFloat(masterImage.height)

        for item in iconSizes {
            let targetSize = item.pixelSize
            let targetURL = iconsetURL.appendingPathComponent(item.name)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: targetSize,
                height: targetSize,
                bitsPerComponent: 8,
                bytesPerRow: targetSize * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                continue
            }

            // Clear to transparent square
            context.clear(CGRect(x: 0, y: 0, width: targetSize, height: targetSize))

            // Aspect-fit master image inside the square
            let scale = min(CGFloat(targetSize) / masterWidth, CGFloat(targetSize) / masterHeight)
            let drawWidth = masterWidth * scale
            let drawHeight = masterHeight * scale
            let drawX = (CGFloat(targetSize) - drawWidth) / 2.0
            let drawY = (CGFloat(targetSize) - drawHeight) / 2.0

            context.interpolationQuality = .high
            context.draw(masterImage, in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))

            if let resized = context.makeImage(),
               let dest = CGImageDestinationCreateWithURL(targetURL as CFURL, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, resized, nil)
                CGImageDestinationFinalize(dest)
            }
        }

        let destURL = safety.uniqueDestinationURL(
            for: imageURL,
            suffix: "icon",
            newExtension: "icns",
            in: destinationDirectory
        )

        // Run macOS native iconutil: iconutil -c icns <iconsetPath> -o <destURL>
        let iconutilPath = "/usr/bin/iconutil"
        let (exitCode, stdout, stderr) = try await engineManager.runProcess(
            executable: iconutilPath,
            arguments: ["-c", "icns", iconsetURL.path, "-o", destURL.path]
        )

        guard exitCode == 0, FileManager.default.fileExists(atPath: destURL.path) else {
            throw ProcessingError.conversionFailed("iconutil failed (code \(exitCode)): \(stderr) \(stdout)")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: imageURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: "ICNS",
            durationSeconds: elapsed,
            notes: "Multi-resolution macOS icon bundle generated (16px to 1024px)."
        )
    }

    // MARK: - Extract High-Resolution Image from .icns

    public func extractFromICNS(
        icnsURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let source = CGImageSourceCreateWithURL(icnsURL as CFURL, nil) else {
            throw ProcessingError.unreadableFile(icnsURL)
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else {
            throw ProcessingError.corruptedFile("ICNS contains zero image representations.")
        }

        // Find the image with the largest dimension
        var bestIndex = 0
        var maxDimension: Int = 0

        for i in 0..<count {
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let width = properties[kCGImagePropertyPixelWidth] as? Int,
               let height = properties[kCGImagePropertyPixelHeight] as? Int {
                let dim = max(width, height)
                if dim > maxDimension {
                    maxDimension = dim
                    bestIndex = i
                }
            }
        }

        guard let bestImage = CGImageSourceCreateImageAtIndex(source, bestIndex, nil) else {
            throw ProcessingError.corruptedFile("Failed to decode highest-resolution frame from ICNS.")
        }

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: icnsURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let destURL = safety.uniqueDestinationURL(
            for: icnsURL,
            suffix: "extracted-\(maxDimension)px",
            newExtension: "png",
            in: destinationDirectory
        )

        guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, "public.png" as CFString, 1, nil) else {
            throw ProcessingError.writeFailed("Failed to create destination for extracted PNG.")
        }

        CGImageDestinationAddImage(dest, bestImage, nil)
        guard CGImageDestinationFinalize(dest) else {
            throw ProcessingError.writeFailed("Failed to finalize extracted PNG.")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: icnsURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: "PNG",
            durationSeconds: elapsed,
            notes: "Extracted \(maxDimension) × \(maxDimension) px master icon."
        )
    }
}
