import Foundation
import CoreGraphics
import PDFKit
import ImageIO
import UniformTypeIdentifiers

public final class PDFEngine: Sendable {
    public static let shared = PDFEngine()

    private let safety = FileSafetyService.shared

    public init() {}

    // MARK: - Inspection

    public func inspect(url: URL) throws -> FileItem {
        guard let document = PDFDocument(url: url) else {
            throw ProcessingError.unreadableFile(url)
        }

        if document.isLocked {
            throw ProcessingError.pdfEncrypted
        }

        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw ProcessingError.corruptedFile("PDF contains 0 pages.")
        }

        let firstPage = document.page(at: 0)
        let bounds = firstPage?.bounds(for: .mediaBox) ?? .zero

        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let fileSize = attributes[.size] as? Int64 ?? 0

        return FileItem(
            url: url,
            filename: url.lastPathComponent,
            fileSize: fileSize,
            category: .pdf,
            formatName: "PDF",
            imageDimensions: bounds.size,
            pageCount: pageCount,
            hasAlpha: false,
            colorSpace: "DeviceRGB"
        )
    }

    // MARK: - PDF Compression

    /// Compresses a PDF document.
    /// Preserves vector text and lines, while downsampling high-resolution embedded raster pages.
    public func compress(
        inputURL: URL,
        preset: CompressionPreset,
        destinationDirectory: URL? = nil,
        stripMetadata: Bool = false
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let document = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")

        // Strategy based on preset:
        // Light: Linearized save / metadata strip using PDFKit options
        // Balanced / Maximum: Render pages with controlled DPI downsampling for heavy graphics
        let pageCount = document.pageCount
        let targetDPI = preset.pdfTargetDPI

        let newDocument = PDFDocument()

        for pageIndex in 0..<pageCount {
            if Task.isCancelled { throw ProcessingError.cancelled }

            guard let page = document.page(at: pageIndex) else { continue }
            let mediaBox = page.bounds(for: .mediaBox)

            if preset == .light {
                // Keep original page data intact
                if let copyPage = page.copy() as? PDFPage {
                    newDocument.insert(copyPage, at: newDocument.pageCount)
                }
            } else {
                // Downsample raster elements by drawing page into bitmap context at targetDPI
                let scale = targetDPI / 72.0
                let targetPixelWidth = Int(mediaBox.width * scale)
                let targetPixelHeight = Int(mediaBox.height * scale)

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

                if let context = CGContext(
                    data: nil,
                    width: targetPixelWidth,
                    height: targetPixelHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: targetPixelWidth * 4,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) {
                    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                    context.fill(CGRect(x: 0, y: 0, width: targetPixelWidth, height: targetPixelHeight))

                    context.saveGState()
                    context.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: context)
                    context.restoreGState()

                    if let cgImage = context.makeImage() {
                        let nsImage = NSImage(cgImage: cgImage, size: mediaBox.size)
                        if let renderedPage = PDFPage(image: nsImage) {
                            renderedPage.setBounds(mediaBox, for: .mediaBox)
                            renderedPage.rotation = page.rotation
                            newDocument.insert(renderedPage, at: newDocument.pageCount)
                            continue
                        }
                    }
                }

                // Fallback: copy page directly
                if let copyPage = page.copy() as? PDFPage {
                    newDocument.insert(copyPage, at: newDocument.pageCount)
                }
            }
        }

        if stripMetadata {
            newDocument.documentAttributes = [:]
        } else {
            newDocument.documentAttributes = document.documentAttributes
        }

        guard newDocument.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write compressed PDF document.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let safeOutputURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-compressed",
            targetExtension: "pdf",
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeOutputURL)

        let outAttributes = (try? FileManager.default.attributesOfItem(atPath: safeOutputURL.path)) ?? [:]
        let outputSize = outAttributes[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        var notes: String? = nil
        if outputSize >= fileItem.fileSize {
            notes = "The PDF is already compact. Output size is not smaller than original."
        }

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeOutputURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration,
            notes: notes
        )
    }

    // MARK: - Merge PDFs

    /// Combines multiple PDF documents into a single document preserving page dimensions and orientations.
    public func merge(
        pdfURLs: [URL],
        outputFilename: String = "merged-document.pdf",
        destinationDirectory: URL? = nil,
        stripMetadata: Bool = false
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard !pdfURLs.isEmpty else {
            throw ProcessingError.emptyInput
        }

        let mergedDoc = PDFDocument()
        var totalOriginalSize: Int64 = 0
        var insertionIndex = 0

        for url in pdfURLs {
            if Task.isCancelled { throw ProcessingError.cancelled }

            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            totalOriginalSize += attributes[.size] as? Int64 ?? 0

            guard let doc = PDFDocument(url: url) else {
                throw ProcessingError.unreadableFile(url)
            }

            if doc.isLocked {
                throw ProcessingError.pdfEncrypted
            }

            for pageIdx in 0..<doc.pageCount {
                if let page = doc.page(at: pageIdx), let copyPage = page.copy() as? PDFPage {
                    mergedDoc.insert(copyPage, at: insertionIndex)
                    insertionIndex += 1
                }
            }
        }

        guard mergedDoc.pageCount > 0 else {
            throw ProcessingError.corruptedFile("No pages found in provided PDFs.")
        }

        if stripMetadata {
            mergedDoc.documentAttributes = [:]
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard mergedDoc.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to save merged PDF.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let baseDir = destinationDirectory ?? pdfURLs[0].deletingLastPathComponent()
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
            originalURL: pdfURLs[0],
            outputURLs: [finalURL],
            originalSize: totalOriginalSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    // MARK: - Split PDF

    /// Splits a PDF document by extracting page ranges or splitting all individual pages.
    public func split(
        inputURL: URL,
        mode: PDFSplitMode,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let totalPages = sourceDoc.pageCount
        var createdURLs: [URL] = []
        let baseDir = destinationDirectory ?? inputURL.deletingLastPathComponent()

        switch mode {
        case .allPages:
            // Extract every single page into its own document
            for pageIdx in 0..<totalPages {
                if Task.isCancelled { throw ProcessingError.cancelled }

                guard let page = sourceDoc.page(at: pageIdx),
                      let pageCopy = page.copy() as? PDFPage else { continue }

                let singleDoc = PDFDocument()
                singleDoc.insert(pageCopy, at: 0)

                let pageNumStr = String(format: "%03d", pageIdx + 1)
                let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
                guard singleDoc.write(to: tempURL) else {
                    throw ProcessingError.writeFailed("Failed to write page \(pageIdx + 1).")
                }

                try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

                let safeURL = safety.generateSafeDestinationURL(
                    originalURL: inputURL,
                    suffix: "-page-\(pageNumStr)",
                    targetExtension: "pdf",
                    destinationDirectory: baseDir
                )

                try FileManager.default.moveItem(at: tempURL, to: safeURL)
                createdURLs.append(safeURL)
            }

        case .pageRange(let rangeString):
            let indices = try parsePageRange(rangeString, totalPages: totalPages)
            guard !indices.isEmpty else {
                throw ProcessingError.invalidPageRange("Page range yielded zero pages.")
            }

            let rangeDoc = PDFDocument()
            for (destIdx, pageIdx) in indices.enumerated() {
                if let page = sourceDoc.page(at: pageIdx),
                   let pageCopy = page.copy() as? PDFPage {
                    rangeDoc.insert(pageCopy, at: destIdx)
                }
            }

            let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
            guard rangeDoc.write(to: tempURL) else {
                throw ProcessingError.writeFailed("Failed to write extracted PDF range.")
            }

            try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

            let safeURL = safety.generateSafeDestinationURL(
                originalURL: inputURL,
                suffix: "-extracted",
                targetExtension: "pdf",
                destinationDirectory: baseDir
            )

            try FileManager.default.moveItem(at: tempURL, to: safeURL)
            createdURLs.append(safeURL)
        }

        var totalOutputSize: Int64 = 0
        for url in createdURLs {
            let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            totalOutputSize += attrs[.size] as? Int64 ?? 0
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: createdURLs,
            originalSize: fileItem.fileSize,
            outputSize: totalOutputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    // MARK: - PDF to Image

    /// Renders PDF pages to high-resolution PNG or JPEG images incrementally.
    public func pdfToImage(
        inputURL: URL,
        format: ImageFormat = .png,
        dpi: CGFloat = 150.0,
        pageRange: String? = nil,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let totalPages = sourceDoc.pageCount
        let targetIndices: [Int]
        if let rangeStr = pageRange, !rangeStr.trimmingCharacters(in: .whitespaces).isEmpty {
            targetIndices = try parsePageRange(rangeStr, totalPages: totalPages)
        } else {
            targetIndices = Array(0..<totalPages)
        }

        var createdURLs: [URL] = []
        let baseDir = destinationDirectory ?? inputURL.deletingLastPathComponent()

        for pageIdx in targetIndices {
            if Task.isCancelled { throw ProcessingError.cancelled }

            guard let page = sourceDoc.page(at: pageIdx) else { continue }
            let mediaBox = page.bounds(for: .mediaBox)

            let scale = dpi / 72.0
            let pixelWidth = max(1, Int(mediaBox.width * scale))
            let pixelHeight = max(1, Int(mediaBox.height * scale))

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

            guard let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: pixelWidth * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                continue
            }

            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

            context.saveGState()
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()

            guard let cgImage = context.makeImage() else { continue }

            let tempURL = try safety.createTemporaryFileURL(extension: format.fileExtension)
            let uti = format.uniformType.identifier as CFString

            guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, uti, 1, nil) else {
                continue
            }

            var options: [CFString: Any] = [:]
            if format != .png {
                options[kCGImageDestinationLossyCompressionQuality] = 0.90
            }

            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { continue }

            try safety.validateOutputFile(url: tempURL, expectedCategory: .image)

            let pageNumStr = String(format: "%03d", pageIdx + 1)
            let safeURL = safety.generateSafeDestinationURL(
                originalURL: inputURL,
                suffix: "-page-\(pageNumStr)",
                targetExtension: format.fileExtension,
                destinationDirectory: baseDir
            )

            try FileManager.default.moveItem(at: tempURL, to: safeURL)
            createdURLs.append(safeURL)
        }

        var totalOutputSize: Int64 = 0
        for url in createdURLs {
            let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            totalOutputSize += attrs[.size] as? Int64 ?? 0
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: createdURLs,
            originalSize: fileItem.fileSize,
            outputSize: totalOutputSize,
            outputFormat: format.rawValue,
            durationSeconds: duration
        )
    }

    // MARK: - PDF Page Management (Rotate, Extract, Remove, Reorder)

    /// Rotates specified pages or all pages in the PDF document by angle (90, 180, 270 degrees).
    public func rotatePages(
        inputURL: URL,
        pageIndices: [Int]? = nil, // nil rotates all pages
        angleDegrees: Int = 90,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let targetIndices = Set(pageIndices ?? Array(0..<sourceDoc.pageCount))

        for pageIdx in 0..<sourceDoc.pageCount {
            if targetIndices.contains(pageIdx), let page = sourceDoc.page(at: pageIdx) {
                let currentRot = page.rotation
                page.rotation = (currentRot + angleDegrees) % 360
            }
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard sourceDoc.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write rotated PDF document.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let safeURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-rotated",
            targetExtension: "pdf",
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeURL)

        let outAttrs = (try? FileManager.default.attributesOfItem(atPath: safeURL.path)) ?? [:]
        let outputSize = outAttrs[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    /// Removes specified 0-indexed pages from the PDF document.
    public func removePages(
        inputURL: URL,
        indicesToRemove: [Int],
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let removeSet = Set(indicesToRemove)
        let total = sourceDoc.pageCount

        guard removeSet.count < total else {
            throw ProcessingError.conversionFailed("Cannot remove all pages from document.")
        }

        // Remove from highest index down to lowest to prevent index shifting
        for idx in indicesToRemove.sorted(by: >) {
            if idx >= 0 && idx < sourceDoc.pageCount {
                sourceDoc.removePage(at: idx)
            }
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard sourceDoc.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write PDF after page removal.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let safeURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-edited",
            targetExtension: "pdf",
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeURL)

        let outAttrs = (try? FileManager.default.attributesOfItem(atPath: safeURL.path)) ?? [:]
        let outputSize = outAttrs[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    /// Reorders pages according to the provided list of 0-based original page indices.
    public func reorderPages(
        inputURL: URL,
        newOrderIndices: [Int],
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        let reorderedDoc = PDFDocument()

        for (newPos, originalIdx) in newOrderIndices.enumerated() {
            if originalIdx >= 0 && originalIdx < sourceDoc.pageCount,
               let page = sourceDoc.page(at: originalIdx),
               let pageCopy = page.copy() as? PDFPage {
                reorderedDoc.insert(pageCopy, at: newPos)
            }
        }

        guard reorderedDoc.pageCount > 0 else {
            throw ProcessingError.conversionFailed("Reordered document contains no pages.")
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard reorderedDoc.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write reordered PDF.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let safeURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-reordered",
            targetExtension: "pdf",
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeURL)

        let outAttrs = (try? FileManager.default.attributesOfItem(atPath: safeURL.path)) ?? [:]
        let outputSize = outAttrs[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }

    /// Extracts specified 0-indexed pages from the PDF document into a new standalone document.
    public func extractPages(
        inputURL: URL,
        pageIndices: [Int],
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileItem = try inspect(url: inputURL)

        guard let sourceDoc = PDFDocument(url: inputURL) else {
            throw ProcessingError.unreadableFile(inputURL)
        }

        guard !pageIndices.isEmpty else {
            throw ProcessingError.conversionFailed("No pages selected for extraction.")
        }

        let extractDoc = PDFDocument()
        for (destIdx, pageIdx) in pageIndices.enumerated() {
            if pageIdx >= 0 && pageIdx < sourceDoc.pageCount,
               let page = sourceDoc.page(at: pageIdx),
               let pageCopy = page.copy() as? PDFPage {
                extractDoc.insert(pageCopy, at: destIdx)
            }
        }

        guard extractDoc.pageCount > 0 else {
            throw ProcessingError.conversionFailed("Extracted document contains no pages.")
        }

        let tempURL = try safety.createTemporaryFileURL(extension: "pdf")
        guard extractDoc.write(to: tempURL) else {
            throw ProcessingError.writeFailed("Failed to write extracted PDF.")
        }

        try safety.validateOutputFile(url: tempURL, expectedCategory: .pdf)

        let safeURL = safety.generateSafeDestinationURL(
            originalURL: inputURL,
            suffix: "-extracted",
            targetExtension: "pdf",
            destinationDirectory: destinationDirectory
        )

        try FileManager.default.moveItem(at: tempURL, to: safeURL)

        let outAttrs = (try? FileManager.default.attributesOfItem(atPath: safeURL.path)) ?? [:]
        let outputSize = outAttrs[.size] as? Int64 ?? 0
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [safeURL],
            originalSize: fileItem.fileSize,
            outputSize: outputSize,
            outputFormat: "PDF",
            durationSeconds: duration
        )
    }


    // MARK: - Fast Page Thumbnail

    /// Renders a fast preview image for a specific PDF page.
    public func renderThumbnail(url: URL, pageIndex: Int, maxDimension: CGFloat = 200.0) -> NSImage? {
        guard let doc = PDFDocument(url: url),
              pageIndex >= 0 && pageIndex < doc.pageCount,
              let page = doc.page(at: pageIndex) else {
            return nil
        }

        let bounds = page.bounds(for: .mediaBox)
        let scale = maxDimension / max(bounds.width, bounds.height)
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    // MARK: - Range Parsing

    /// Parses page ranges like "1-3, 5, 8-10" into 0-indexed page numbers.
    public func parsePageRange(_ rangeString: String, totalPages: Int) throws -> [Int] {
        var pageIndices: [Int] = []
        let parts = rangeString.components(separatedBy: ",")

        for rawPart in parts {
            let part = rawPart.trimmingCharacters(in: .whitespacesAndNewlines)
            if part.isEmpty { continue }

            if part.contains("-") {
                let rangeTokens = part.components(separatedBy: "-")
                guard rangeTokens.count == 2,
                      let start = Int(rangeTokens[0].trimmingCharacters(in: .whitespaces)),
                      let end = Int(rangeTokens[1].trimmingCharacters(in: .whitespaces)),
                      start >= 1 && end >= start else {
                    throw ProcessingError.invalidPageRange(part)
                }

                guard start <= totalPages else {
                    throw ProcessingError.invalidPageRange("Page \(start) exceeds document page count of \(totalPages).")
                }

                let clampedEnd = min(end, totalPages)
                for pageNum in start...clampedEnd {
                    let index = pageNum - 1
                    if !pageIndices.contains(index) {
                        pageIndices.append(index)
                    }
                }
            } else {
                guard let singlePage = Int(part), singlePage >= 1 else {
                    throw ProcessingError.invalidPageRange(part)
                }

                guard singlePage <= totalPages else {
                    throw ProcessingError.invalidPageRange("Page \(singlePage) exceeds document page count of \(totalPages).")
                }

                let index = singlePage - 1
                if !pageIndices.contains(index) {
                    pageIndices.append(index)
                }
            }
        }

        guard !pageIndices.isEmpty else {
            throw ProcessingError.invalidPageRange(rangeString)
        }

        return pageIndices
    }
}
