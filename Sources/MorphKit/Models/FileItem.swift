import Foundation
import CoreGraphics

public enum FileCategory: String, Sendable {
    case image
    case pdf
    case archive
    case media
    case audio
    case office
    case vector
    case data
    case icon
    case folder
    case link
    case unsupported
}

public struct FileItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let url: URL
    public let filename: String
    public let fileSize: Int64
    public let category: FileCategory
    public let formatName: String
    public let imageDimensions: CGSize?
    public let pageCount: Int?
    public let hasAlpha: Bool?
    public let colorSpace: String?

    public init(
        id: UUID = UUID(),
        url: URL,
        filename: String,
        fileSize: Int64,
        category: FileCategory,
        formatName: String,
        imageDimensions: CGSize? = nil,
        pageCount: Int? = nil,
        hasAlpha: Bool? = nil,
        colorSpace: String? = nil
    ) {
        self.id = id
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.category = category
        self.formatName = formatName
        self.imageDimensions = imageDimensions
        self.pageCount = pageCount
        self.hasAlpha = hasAlpha
        self.colorSpace = colorSpace
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var dimensionsDescription: String? {
        guard let dims = imageDimensions else { return nil }
        return "\(Int(dims.width)) × \(Int(dims.height)) px"
    }

    public var summaryDescription: String {
        switch category {
        case .image:
            var parts = [formatName.uppercased()]
            if let dims = dimensionsDescription {
                parts.append(dims)
            }
            if hasAlpha == true {
                parts.append("Alpha")
            }
            parts.append(formattedSize)
            return parts.joined(separator: " • ")
        case .pdf:
            var parts = ["PDF"]
            if let count = pageCount {
                parts.append("\(count) page\(count == 1 ? "" : "s")")
            }
            parts.append(formattedSize)
            return parts.joined(separator: " • ")
        case .archive:
            return "\(formatName.uppercased()) Archive • \(formattedSize)"
        case .media:
            return "\(formatName.uppercased()) Media • \(formattedSize)"
        case .audio:
            return "\(formatName.uppercased()) Audio • \(formattedSize)"
        case .folder:
            return "\(formatName.uppercased()) Folder • \(formattedSize)"
        case .link:
            return "\(formatName.uppercased()) Link"
        case .office:
            return "\(formatName.uppercased()) Document • \(formattedSize)"
        case .vector:
            return "\(formatName.uppercased()) Vector • \(formattedSize)"
        case .data:
            return "\(formatName.uppercased()) Data • \(formattedSize)"
        case .icon:
            return "\(formatName.uppercased()) Icon • \(formattedSize)"
        case .unsupported:
            return "\(formatName) • \(formattedSize)"
        }
    }
}

extension FileCategory {
    public static func category(for url: URL) -> FileCategory {
        if url.scheme == "http" || url.scheme == "https" || url.pathExtension.lowercased() == "webloc" {
            return .link
        }

        var isDir: ObjCBool = false
        if url.isFileURL && FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue {
            return .folder
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "bmp", "gif", "ico", "dng", "cr2", "nef", "arw", "rw2":
            return .image
        case "pdf":
            return .pdf
        case "zip", "tar", "gz", "bz2", "7z", "rar":
            return .archive
        case "mp3", "m4a", "wav", "aac", "flac", "ogg", "opus", "aiff", "wma":
            return .audio
        case "mp4", "mov", "mkv", "webm", "avi", "m4v", "flv", "wmv":
            return .media
        case "docx", "doc", "pptx", "ppt", "xlsx", "xls", "odt", "rtf", "md", "markdown":
            return .office
        case "svg":
            return .vector
        case "json", "plist", "xml", "csv":
            return .data
        case "icns":
            return .icon
        default:
            return .unsupported
        }
    }

    public var iconName: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.text.fill"
        case .archive: return "archivebox.fill"
        case .media: return "film"
        case .audio: return "music.note"
        case .folder: return "folder.fill"
        case .link: return "globe"
        case .office: return "doc.richtext"
        case .vector: return "triangle.fill"
        case .data: return "curlybraces"
        case .icon: return "app.fill"
        case .unsupported: return "doc"
        }
    }
}
