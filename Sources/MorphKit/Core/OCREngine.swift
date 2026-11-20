import Foundation
import CoreGraphics
import Vision
import PDFKit
import ImageIO

public final class OCREngine: Sendable {
    public static let shared = OCREngine()

    private let safety = FileSafetyService.shared

    public init() {}

    // MARK: - Recognize Text from Image

    public func recognizeText(
        imageURL: URL,
        languages: [String] = ["en-US"]
    ) async throws -> String {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.unreadableFile(imageURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ProcessingError.conversionFailed("Vision OCR failed: \(error.localizedDescription)"))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if !languages.isEmpty {
                request.recognitionLanguages = languages
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ProcessingError.conversionFailed("Vision handler failed: \(error.localizedDescription)"))
            }
        }
    }

    // MARK: - Recognize Text from PDF

    public func recognizePDF(pdfURL: URL) async throws -> String {
        guard let doc = PDFDocument(url: pdfURL) else {
            throw ProcessingError.unreadableFile(pdfURL)
        }

        let pageCount = doc.pageCount
        guard pageCount > 0 else {
            throw ProcessingError.corruptedFile("PDF has 0 pages.")
        }

        var fullDocumentText: [String] = []

        for pageIndex in 0..<pageCount {
            guard let page = doc.page(at: pageIndex) else { continue }

            // First check if PDF already has embedded selectable text
            if let existingText = page.string, !existingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fullDocumentText.append("--- Page \(pageIndex + 1) ---\n\(existingText)")
                continue
            }

            // Otherwise, render page to bitmap and OCR via Apple Vision
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0 // 144 DPI equivalent for accurate OCR
            let pixelWidth = Int(bounds.width * scale)
            let pixelHeight = Int(bounds.height * scale)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: pixelWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else {
                continue
            }

            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
            context.scaleBy(x: scale, y: scale)

            // Render page in context
            page.draw(with: .mediaBox, to: context)

            if let pageImage = context.makeImage() {
                let text = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    let request = VNRecognizeTextRequest { req, err in
                        if let err {
                            continuation.resume(throwing: err)
                            return
                        }
                        let candidates = (req.results as? [VNRecognizedTextObservation])?.compactMap {
                            $0.topCandidates(1).first?.string
                        } ?? []
                        continuation.resume(returning: candidates.joined(separator: "\n"))
                    }
                    request.recognitionLevel = .accurate
                    let handler = VNImageRequestHandler(cgImage: pageImage, options: [:])
                    do {
                        try handler.perform([request])
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }

                fullDocumentText.append("--- Page \(pageIndex + 1) ---\n\(text)")
            }
        }

        return fullDocumentText.joined(separator: "\n\n")
    }

    // MARK: - Create Searchable PDF

    public func createSearchablePDF(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let ext = inputURL.pathExtension.lowercased()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let recognizedText: String
        if ext == "pdf" {
            recognizedText = try await recognizePDF(pdfURL: inputURL)
        } else {
            recognizedText = try await recognizeText(imageURL: inputURL)
        }

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "searchable",
            newExtension: "pdf",
            in: destinationDirectory
        )

        // Generate PDF document with text content and imagery
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // Default US Letter
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ProcessingError.writeFailed("Failed to initialize PDF graphics context.")
        }

        pdfContext.beginPage(mediaBox: &mediaBox)

        // Draw background if image
        if ext != "pdf", let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
           let img = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            let imgRect = CGRect(x: 40, y: 40, width: mediaBox.width - 80, height: mediaBox.height - 80)
            pdfContext.draw(img, in: imgRect)
        }

        // Add OCR metadata/watermark
        let font = CTFontCreateWithName("Helvetica" as CFString, 10, nil)
        let attrString = NSAttributedString(
            string: "Morph OCR Searchable Text Export • \(inputURL.lastPathComponent)",
            attributes: [
                .font: font,
                .foregroundColor: CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
            ]
        )
        let line = CTLineCreateWithAttributedString(attrString)
        pdfContext.textPosition = CGPoint(x: 40, y: 20)
        CTLineDraw(line, pdfContext)

        pdfContext.endPage()
        pdfContext.closePDF()

        // Write searchable PDF
        try (pdfData as Data).write(to: destURL, options: .atomic)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        let snippet = recognizedText.prefix(200).replacingOccurrences(of: "\n", with: " ")

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: elapsed,
            notes: "Recognized text: \"\(snippet)...\""
        )
    }

    // MARK: - Export Recognized Text to File

    public func exportText(
        text: String,
        baseFilename: String,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let targetDir = destinationDirectory ?? FileManager.default.temporaryDirectory
        let safeBase = (baseFilename as NSString).deletingPathExtension
        let destURL = targetDir.appendingPathComponent("\(safeBase)-extracted.txt")

        let utf8Data = Data(text.utf8)
        try utf8Data.write(to: destURL, options: .atomic)

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: destURL,
            outputURLs: [destURL],
            originalSize: Int64(utf8Data.count),
            outputSize: Int64(utf8Data.count),
            outputFormat: "TXT",
            durationSeconds: elapsed,
            notes: text
        )
    }
}
