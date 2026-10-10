import Foundation
import CoreGraphics

public enum FileCategory: String, Sendable {
    case image
    case pdf
    case archive
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

    public var formattedFileSize: String {
        formattedSize
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
        case .unsupported:
            return "\(formatName) • \(formattedSize)"
        }
    }
}
