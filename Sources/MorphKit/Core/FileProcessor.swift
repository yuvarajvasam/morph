import Foundation
import CoreGraphics

public final class FileProcessor: Sendable {
    public static let shared = FileProcessor()

    public let imageEngine = ImageEngine.shared
    public let pdfEngine = PDFEngine.shared
    public let archiveEngine = ArchiveEngine.shared
    public let qrEngine = QRCodeEngine.shared
    public let ocrEngine = OCREngine.shared
    public let iconEngine = IconEngine.shared
    public let mediaEngine = MediaEngine.shared
    public let officeEngine = OfficeEngine.shared
    public let dataEngine = DataEngine.shared
    public let metadataEngine = MetadataEngine.shared
    public let vectorEngine = VectorEngine.shared
    public let engineManager = EngineManager.shared
    public let safety = FileSafetyService.shared
    public let registry = ConversionRegistry.shared

    public init() {}

    /// Inspects any file URL, determining its format and category.
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
        } else if ["mp4", "mov", "mkv", "webm", "avi", "m4v", "flv", "mp3", "m4a", "wav", "aac", "flac", "ogg", "aiff"].contains(ext) {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .media,
                formatName: ext.uppercased()
            )
        } else if ["docx", "doc", "pptx", "ppt", "xlsx", "xls", "odt", "ods", "odp", "rtf", "md", "markdown"].contains(ext) {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .office,
                formatName: ext.uppercased()
            )
        } else if ext == "svg" {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .vector,
                formatName: "SVG"
            )
        } else if ext == "icns" {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .icon,
                formatName: "ICNS"
            )
        } else if ["json", "plist", "csv", "xml"].contains(ext) {
            let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
            let size = attributes[.size] as? Int64 ?? 0
            return FileItem(
                url: url,
                filename: url.lastPathComponent,
                fileSize: size,
                category: .data,
                formatName: ext.uppercased()
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
