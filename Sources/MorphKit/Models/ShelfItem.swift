import Foundation
import AppKit

public struct ShelfItem: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let dateAdded: Date
    public let category: FileCategory
    public var thumbnail: NSImage?
    public var textSnippet: String?
    public var itemCount: Int?
    public var duration: TimeInterval?
    public var subtitle: String?

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64? = nil,
        dateAdded: Date = Date(),
        category: FileCategory? = nil,
        thumbnail: NSImage? = nil,
        textSnippet: String? = nil,
        itemCount: Int? = nil,
        duration: TimeInterval? = nil,
        subtitle: String? = nil
    ) {
        self.id = id
        self.url = url
        self.dateAdded = dateAdded
        let cat = category ?? FileCategory.category(for: url)
        self.category = cat
        self.thumbnail = thumbnail
        self.textSnippet = textSnippet
        self.duration = duration

        if cat == .link {
            let host = url.host ?? url.absoluteString
            let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            self.name = name ?? cleanHost
            self.size = 0
            self.subtitle = subtitle ?? (url.path.isEmpty || url.path == "/" ? cleanHost : url.path)
            self.itemCount = nil
        } else if cat == .folder {
            self.name = name ?? (url.lastPathComponent.isEmpty ? "Folder" : url.lastPathComponent)
            let files = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
            self.itemCount = itemCount ?? files.count
            self.size = size ?? 0
            self.subtitle = subtitle ?? "\(self.itemCount ?? 0) items"
        } else if cat == .audio {
            self.name = name ?? url.lastPathComponent
            if let s = size {
                self.size = s
            } else {
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                self.size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
            }
            self.itemCount = nil
            self.subtitle = subtitle ?? ByteCountFormatter.string(fromByteCount: self.size, countStyle: .file)
        } else {
            self.name = name ?? url.lastPathComponent
            if let s = size {
                self.size = s
            } else {
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                self.size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
            }
            self.itemCount = nil
            self.subtitle = subtitle ?? ByteCountFormatter.string(fromByteCount: self.size, countStyle: .file)
        }
    }

    public var isWebLink: Bool {
        category == .link || url.scheme == "http" || url.scheme == "https"
    }

    public var isDirectory: Bool {
        category == .folder
    }

    public var formattedSize: String {
        if isWebLink {
            return "Web Link"
        } else if isDirectory {
            let count = itemCount ?? 0
            return "\(count) item\(count == 1 ? "" : "s")"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    public var tooltipText: String {
        if isWebLink {
            return "\(name)\n\(url.absoluteString)"
        } else if isDirectory {
            return "\(name) (Folder)\n\(itemCount ?? 0) items • \(url.path)"
        } else {
            return "\(name)\n\(formattedSize) • \(url.path)"
        }
    }

    public static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id && lhs.url == rhs.url
    }
}

public enum ShelfActionType: String, CaseIterable, Identifiable, Sendable {
    case compress = "Compress"
    case convert = "Convert"
    case toPDF = "To PDF"
    case ocr = "OCR"
    case makeIcon = "Make Icon"
    case extractAudio = "Audio"
    case stripMetadata = "Strip EXIF"
    case delete = "Remove"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .convert: return "arrow.triangle.2.circlepath"
        case .toPDF: return "doc.badge.plus"
        case .ocr: return "text.viewfinder"
        case .makeIcon: return "app.dashed"
        case .extractAudio: return "waveform"
        case .stripMetadata: return "shield.slash"
        case .delete: return "trash"
        }
    }

    public var tintColor: (red: Double, green: Double, blue: Double) {
        switch self {
        case .compress: return (0.2, 0.6, 1.0)
        case .convert: return (0.4, 0.7, 1.0)
        case .toPDF: return (0.95, 0.4, 0.3)
        case .ocr: return (0.6, 0.4, 0.9)
        case .makeIcon: return (0.9, 0.6, 0.2)
        case .extractAudio: return (0.2, 0.8, 0.5)
        case .stripMetadata: return (0.8, 0.3, 0.5)
        case .delete: return (0.9, 0.2, 0.2)
        }
    }
}
