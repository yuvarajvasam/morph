import Foundation
import CoreGraphics
import CoreText

public final class OfficeEngine: Sendable {
    public static let shared = OfficeEngine()

    private let safety = FileSafetyService.shared
    private let engineManager = EngineManager.shared

    public init() {}

    // MARK: - Office Documents to PDF (LibreOffice)

    public func officeToPDF(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        guard let soffice = engineManager.findLibreOffice() else {
            throw ProcessingError.toolMissing(
                "LibreOffice is required to convert Word, Excel, and PowerPoint files offline without Office installed. Install it with:\n  brew install --cask libreoffice"
            )
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("office_\(UUID().uuidString.prefix(8))")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Run soffice --headless --convert-to pdf --outdir <tempDir> <inputURL>
        let args = ["--headless", "--convert-to", "pdf", "--outdir", tempDir.path, inputURL.path]
        let (exitCode, stdout, stderr) = try await engineManager.runProcess(executable: soffice, arguments: args)

        guard exitCode == 0 else {
            throw ProcessingError.conversionFailed("LibreOffice conversion failed (code \(exitCode)): \(stderr) \(stdout)")
        }

        let baseName = (inputURL.lastPathComponent as NSString).deletingPathExtension
        let generatedPDF = tempDir.appendingPathComponent("\(baseName).pdf")

        guard FileManager.default.fileExists(atPath: generatedPDF.path) else {
            throw ProcessingError.corruptedFile("LibreOffice completed without producing an output PDF.")
        }

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "document",
            newExtension: "pdf",
            in: destinationDirectory
        )

        try FileManager.default.copyItem(at: generatedPDF, to: destURL)

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
            notes: "Converted \(inputURL.pathExtension.uppercased()) to PDF via LibreOffice headless."
        )
    }

    // MARK: - Markdown to PDF (Pandoc or native fallback)

    public func markdownToPDF(
        inputURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "doc",
            newExtension: "pdf",
            in: destinationDirectory
        )

        if let pandoc = engineManager.findExecutable(named: "pandoc") {
            let args = ["-s", inputURL.path, "-o", destURL.path]
            let (exitCode, _, _) = try await engineManager.runProcess(executable: pandoc, arguments: args)
            if exitCode == 0 && FileManager.default.fileExists(atPath: destURL.path) {
                let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
                let outputSize = outputAttributes[.size] as? Int64 ?? 0
                return ConversionResult(
                    originalURL: inputURL,
                    outputURLs: [destURL],
                    originalSize: originalSize,
                    outputSize: outputSize,
                    outputFormat: "PDF",
                    durationSeconds: CFAbsoluteTimeGetCurrent() - startTime,
                    notes: "Rendered Markdown to PDF using Pandoc."
                )
            }
        }

        // Native fallback: Render Markdown text to formatted PDF
        guard let markdownContent = try? String(contentsOf: inputURL, encoding: .utf8) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter

        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ProcessingError.writeFailed("Failed to create PDF context for Markdown.")
        }

        pdfContext.beginPage(mediaBox: &mediaBox)

        // Draw title
        let titleFont = CTFontCreateWithName("Helvetica-Bold" as CFString, 16, nil)
        let titleStr = NSAttributedString(
            string: inputURL.lastPathComponent,
            attributes: [.font: titleFont, .foregroundColor: CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)]
        )
        let titleLine = CTLineCreateWithAttributedString(titleStr)
        pdfContext.textPosition = CGPoint(x: 54, y: 730)
        CTLineDraw(titleLine, pdfContext)

        // Draw body lines
        let bodyFont = CTFontCreateWithName("Menlo" as CFString, 10, nil)
        let lines = markdownContent.components(separatedBy: .newlines).prefix(55)
        var yPos: CGFloat = 700

        for lineText in lines {
            let lineStr = NSAttributedString(
                string: String(lineText.prefix(80)),
                attributes: [.font: bodyFont, .foregroundColor: CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)]
            )
            let line = CTLineCreateWithAttributedString(lineStr)
            pdfContext.textPosition = CGPoint(x: 54, y: yPos)
            CTLineDraw(line, pdfContext)
            yPos -= 12
            if yPos < 54 { break }
        }

        pdfContext.endPage()
        pdfContext.closePDF()

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
            notes: "Rendered Markdown to styled PDF."
        )
    }
}
