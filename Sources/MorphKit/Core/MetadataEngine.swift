import Foundation
import CoreGraphics
import ImageIO
import PDFKit

public final class MetadataEngine: Sendable {
    public static let shared = MetadataEngine()

    private let safety = FileSafetyService.shared
    private let engineManager = EngineManager.shared

    public init() {}

    // MARK: - Inspect Metadata

    public func inspectMetadata(url: URL) -> [String: String] {
        var tags: [String: String] = [:]
        let ext = url.pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"].contains(ext),
           let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {

            if let width = properties[kCGImagePropertyPixelWidth] as? Int,
               let height = properties[kCGImagePropertyPixelHeight] as? Int {
                tags["Dimensions"] = "\(width) × \(height) px"
            }
            if let colorSpace = properties[kCGImagePropertyColorModel] as? String {
                tags["Color Model"] = colorSpace
            }
            if let dpi = properties[kCGImagePropertyDPIWidth] as? Double {
                tags["DPI"] = "\(Int(dpi))"
            }

            if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                if let date = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                    tags["Date Taken"] = date
                }
                if let exposure = exif[kCGImagePropertyExifExposureTime] as? Double {
                    tags["Exposure"] = "1/\(Int(round(1.0 / exposure)))s"
                }
                if let fnumber = exif[kCGImagePropertyExifFNumber] as? Double {
                    tags["Aperture"] = "f/\(String(format: "%.1f", fnumber))"
                }
                if let iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first {
                    tags["ISO"] = "\(iso)"
                }
                if let lens = exif[kCGImagePropertyExifLensModel] as? String {
                    tags["Lens"] = lens
                }
            }

            if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                if let make = tiff[kCGImagePropertyTIFFMake] as? String {
                    tags["Camera Make"] = make
                }
                if let model = tiff[kCGImagePropertyTIFFModel] as? String {
                    tags["Camera Model"] = model
                }
                if let software = tiff[kCGImagePropertyTIFFSoftware] as? String {
                    tags["Software"] = software
                }
            }

            if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
                if let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
                   let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
                   let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
                   let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
                    tags["GPS Coordinates"] = "\(String(format: "%.4f", lat))° \(latRef), \(String(format: "%.4f", lon))° \(lonRef)"
                }
            }
        } else if ext == "pdf", let doc = PDFDocument(url: url) {
            tags["Pages"] = "\(doc.pageCount)"
            if let attrs = doc.documentAttributes {
                if let title = attrs[PDFDocumentAttribute.titleAttribute] as? String {
                    tags["Title"] = title
                }
                if let author = attrs[PDFDocumentAttribute.authorAttribute] as? String {
                    tags["Author"] = author
                }
                if let creator = attrs[PDFDocumentAttribute.creatorAttribute] as? String {
                    tags["Creator"] = creator
                }
                if let producer = attrs[PDFDocumentAttribute.producerAttribute] as? String {
                    tags["Producer"] = producer
                }
            }
        }

        return tags
    }

    // MARK: - Strip Metadata & GPS

    public func stripMetadata(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let ext = inputURL.pathExtension.lowercased()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "clean",
            newExtension: ext,
            in: destinationDirectory
        )

        if ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"].contains(ext) {
            guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
                  let uti = CGImageSourceGetType(source) else {
                throw ProcessingError.unreadableFile(inputURL)
            }

            guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, uti, 1, nil) else {
                throw ProcessingError.writeFailed("Failed to create stripped image destination.")
            }

            // Exclude EXIF, GPS, IPTC, TIFF metadata dictionaries
            let cleanProperties: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: 0.95
            ]

            CGImageDestinationAddImage(dest, cgImage, cleanProperties as CFDictionary)
            guard CGImageDestinationFinalize(dest) else {
                throw ProcessingError.writeFailed("Failed to finalize stripped image.")
            }
        } else if ext == "pdf" {
            guard let doc = PDFDocument(url: inputURL) else {
                throw ProcessingError.unreadableFile(inputURL)
            }

            // Wipe document metadata attributes
            doc.documentAttributes = [:]
            doc.write(to: destURL)
        } else {
            throw ProcessingError.unsupportedFormatForTool(format: ext, tool: "Strip Metadata", supported: "JPEG, PNG, HEIC, TIFF, PDF")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: ext.uppercased(),
            durationSeconds: elapsed,
            notes: "Purged all EXIF, GPS location coordinates, camera profiles, and device signatures."
        )
    }
}
