import Foundation

public enum ConversionCategory: String, CaseIterable, Identifiable, Sendable {
    case image = "Images"
    case pdf = "PDFs"
    case archive = "Archives"
    case qrBarcode = "QR & Barcodes"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    public var singularName: String {
        switch self {
        case .image: return "Image"
        case .pdf: return "PDF"
        case .archive: return "Archive"
        case .qrBarcode: return "QR & Barcode"
        }
    }

    public var icon: String {
        switch self {
        case .image: return "photo.on.rectangle.angled"
        case .pdf: return "doc.richtext"
        case .archive: return "archivebox"
        case .qrBarcode: return "qrcode"
        }
    }
}


public typealias CommandCategory = ConversionCategory



public struct ConversionCommand: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let category: ConversionCategory
    public let systemIcon: String
    public let keywords: [String]
    public let synonyms: [String]
    public let supportedExtensions: Set<String>
    public let supportsMultipleFiles: Bool

    public init(
        id: String,
        title: String,
        subtitle: String,
        category: ConversionCategory,
        systemIcon: String,
        keywords: [String],
        synonyms: [String] = [],
        supportedExtensions: Set<String>,
        supportsMultipleFiles: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.systemIcon = systemIcon
        self.keywords = keywords
        self.synonyms = synonyms
        self.supportedExtensions = supportedExtensions
        self.supportsMultipleFiles = supportsMultipleFiles
    }

    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return true }

        if title.lowercased().contains(trimmed) { return true }
        if subtitle.lowercased().contains(trimmed) { return true }
        if category.rawValue.lowercased().contains(trimmed) { return true }

        for keyword in keywords {
            if keyword.lowercased().contains(trimmed) || trimmed.contains(keyword.lowercased()) {
                return true
            }
        }

        for synonym in synonyms {
            if synonym.lowercased().contains(trimmed) || trimmed.contains(synonym.lowercased()) {
                return true
            }
        }

        // Tokenized matching (e.g. "make smaller" matches "make image smaller")
        let queryTokens = trimmed.split(separator: " ").map { String($0) }
        let allHaystack = (title + " " + subtitle + " " + keywords.joined(separator: " ") + " " + synonyms.joined(separator: " ")).lowercased()

        let allTokensMatch = queryTokens.allSatisfy { token in
            allHaystack.contains(token)
        }

        return allTokensMatch
    }
}
