import Foundation
import CoreGraphics

public final class FileProcessor: Sendable {
    public static let shared = FileProcessor()

    public let imageEngine = ImageEngine.shared
    public let pdfEngine = PDFEngine.shared
    public let safety = FileSafetyService.shared
    public let registry = ConversionRegistry.shared

    public init() {}

    /// Inspects any file URL, determining if it is a supported image, a PDF, or unsupported.
    public func inspect(url: URL) -> FileItem {
        let ext = url.pathExtension.lowercased()

        if ext == "pdf" {
            if let item = try? pdfEngine.inspect(url: url) {
                return item
            }
        } else if imageEngine.isSupportedImage(url: url) {
            if let item = try? imageEngine.inspect(url: url) {
                return item
            }
        } else if ArchiveEngine.shared.isSupportedArchive(url: url) {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            let (count, _, _) = (try? ArchiveEngine.shared.inspect(url: url)) ?? (0, 0, [])
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .archive,
                formatName: ext.uppercased(),
                pageCount: count > 0 ? count : nil
            )
        }

        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let size = attributes[.size] as? Int64 ?? 0

        return FileItem(
            url: url,
            filename: url.lastPathComponent,
            fileSize: size,
            category: .unsupported,
            formatName: ext.uppercased()
        )
    }

    /// Inspects a collection of URLs.
    public func inspect(urls: [URL]) -> [FileItem] {
        return urls.map { inspect(url: $0) }
    }
}
