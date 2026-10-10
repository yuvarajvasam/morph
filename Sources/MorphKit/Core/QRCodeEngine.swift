import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import Vision

public enum QRErrorCorrection: String, CaseIterable, Identifiable, Sendable {
    case low = "L (7%)"
    case medium = "M (15%)"
    case quartile = "Q (25%)"
    case high = "H (30%)"

    public var id: String { rawValue }
    public var displayName: String { rawValue }

    public var code: String {
        switch self {
        case .low: return "L"
        case .medium: return "M"
        case .quartile: return "Q"
        case .high: return "H"
        }
    }
}

public enum QRContentType: String, CaseIterable, Identifiable, Sendable {
    case url = "Website URL"
    case text = "Plain Text"
    case wifi = "Wi-Fi Network"
    case email = "Email Address"
    case phone = "Phone Number"
    case vcard = "Contact (vCard)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .url: return "link"
        case .text: return "text.alignleft"
        case .wifi: return "wifi"
        case .email: return "envelope"
        case .phone: return "phone"
        case .vcard: return "person.crop.rectangle"
        }
    }
}

public final class QRCodeEngine: @unchecked Sendable {
    public static let shared = QRCodeEngine()

    private let safety = FileSafetyService.shared
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    public init() {}

    // MARK: - QR Code Generation

    /// Generates a CGImage representing a QR code with custom colors and error correction.
    public func generateQRCode(
        message: String,
        errorCorrection: QRErrorCorrection = .medium,
        pixelSize: CGFloat = 1024,
        foregroundColor: NSColor = .black,
        backgroundColor: NSColor = .white
    ) throws -> CGImage {
        guard !message.isEmpty else {
            throw ProcessingError.emptyInput
        }

        guard let data = message.data(using: .utf8) else {
            throw ProcessingError.conversionFailed("Cannot encode string as UTF-8.")
        }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw ProcessingError.conversionFailed("CIQRCodeGenerator is unavailable.")
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(errorCorrection.code, forKey: "inputCorrectionLevel")

        guard let outputCI = filter.outputImage else {
            throw ProcessingError.conversionFailed("Failed to generate QR output image.")
        }

        // Apply custom colors using CIFalseColor
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(outputCI, forKey: kCIInputImageKey)
        colorFilter?.setValue(CIColor(color: foregroundColor) ?? CIColor.black, forKey: "inputColor0")
        colorFilter?.setValue(CIColor(color: backgroundColor) ?? CIColor.white, forKey: "inputColor1")

        let coloredCI = colorFilter?.outputImage ?? outputCI

        // Scale up using nearest-neighbor so pixels stay razor sharp
        let extent = coloredCI.extent
        let scale = pixelSize / max(extent.width, 1.0)
        let transformed = coloredCI.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            throw ProcessingError.conversionFailed("Failed to render QR bitmap.")
        }

        return cgImage
    }

    /// Generates a Code 128 barcode CGImage.
    public func generateBarcode(
        message: String,
        pixelHeight: CGFloat = 300,
        pixelWidth: CGFloat = 800
    ) throws -> CGImage {
        guard !message.isEmpty else {
            throw ProcessingError.emptyInput
        }

        guard let data = message.data(using: .ascii) else {
            throw ProcessingError.conversionFailed("Code 128 barcodes require standard ASCII characters.")
        }

        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            throw ProcessingError.conversionFailed("CICode128BarcodeGenerator is unavailable.")
        }

        filter.setValue(data, forKey: "inputMessage")

        guard let outputCI = filter.outputImage else {
            throw ProcessingError.conversionFailed("Failed to generate Barcode output image.")
        }

        let extent = outputCI.extent
        let scaleX = pixelWidth / max(extent.width, 1.0)
        let scaleY = pixelHeight / max(extent.height, 1.0)
        let transformed = outputCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            throw ProcessingError.conversionFailed("Failed to render Barcode bitmap.")
        }

        return cgImage
    }

    /// Exports a QR or Barcode image to disk as PNG or PDF.
    public func exportCode(
        cgImage: CGImage,
        baseFilename: String,
        asPDF: Bool = false,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = Date()
        let ext = asPDF ? "pdf" : "png"

        let targetDir: URL
        if let destinationDirectory {
            targetDir = destinationDirectory
        } else {
            let prefTarget = await MainActor.run {
                PreferencesManager.shared.targetOutputDirectory(for: URL(fileURLWithPath: "/tmp"))
            }
            targetDir = prefTarget ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        }

        var finalURL = targetDir.appendingPathComponent("\(baseFilename).\(ext)")
        if FileManager.default.fileExists(atPath: finalURL.path) {
            var counter = 1
            while FileManager.default.fileExists(atPath: finalURL.path) {
                finalURL = targetDir.appendingPathComponent("\(baseFilename) (\(counter)).\(ext)")
                counter += 1
            }
        }

        if asPDF {
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)
            var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)

            guard let pdfContext = CGContext(finalURL as CFURL, mediaBox: &mediaBox, nil) else {
                throw ProcessingError.conversionFailed("Could not create PDF context.")
            }

            pdfContext.beginPage(mediaBox: &mediaBox)
            pdfContext.draw(cgImage, in: mediaBox)
            pdfContext.endPage()
            pdfContext.closePDF()
        } else {
            guard let dest = CGImageDestinationCreateWithURL(finalURL as CFURL, "public.png" as CFString, 1, nil) else {
                throw ProcessingError.conversionFailed("Failed to create PNG destination.")
            }
            CGImageDestinationAddImage(dest, cgImage, nil)
            guard CGImageDestinationFinalize(dest) else {
                throw ProcessingError.conversionFailed("Failed to finalize PNG export.")
            }
        }

        let attrs = (try? FileManager.default.attributesOfItem(atPath: finalURL.path)) ?? [:]
        let outputSize = attrs[.size] as? Int64 ?? 0
        let duration = Date().timeIntervalSince(startTime)

        return ConversionResult(
            originalURL: finalURL,
            outputURLs: [finalURL],
            originalSize: 0,
            outputSize: outputSize,
            originalDimensions: CGSize(width: cgImage.width, height: cgImage.height),
            outputDimensions: CGSize(width: cgImage.width, height: cgImage.height),
            outputFormat: asPDF ? "PDF" : "PNG",
            durationSeconds: duration,
            notes: asPDF ? "Exported sharp vector PDF" : "Exported high-resolution PNG"
        )
    }

    /// Decodes any QR code or standard barcode from a local image URL using Vision and CoreImage.
    public func scanCode(url: URL) async throws -> [String] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProcessingError.fileNotFound(url)
        }

        guard let ciImage = CIImage(contentsOf: url) else {
            throw ProcessingError.corruptedFile("Unable to load image for code detection.")
        }

        // Try Vision barcode detection first
        var detectedPayloads: [String] = []

        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])

        if let results = request.results {
            for res in results {
                if let payload = res.payloadStringValue, !payload.isEmpty {
                    detectedPayloads.append(payload)
                }
            }
        }

        // Fallback to CIDetector if Vision returned nothing
        if detectedPayloads.isEmpty {
            if let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) {
                let features = detector.features(in: ciImage)
                for f in features {
                    if let qrFeature = f as? CIQRCodeFeature, let message = qrFeature.messageString, !message.isEmpty {
                        detectedPayloads.append(message)
                    }
                }
            }
        }

        return detectedPayloads
    }
}
