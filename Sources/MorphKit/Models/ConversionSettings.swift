import Foundation
import UniformTypeIdentifiers

public enum CompressionPreset: String, CaseIterable, Identifiable, Sendable {
    case light = "Light"
    case balanced = "Balanced"
    case maximum = "Maximum"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .light:
            return "Prioritizes visual fidelity and preserves full dimensions."
        case .balanced:
            return "Optimal balance between visual quality and file size savings."
        case .maximum:
            return "Aggressive reduction for sharing and minimal storage footprint."
        }
    }

    public var imageQualityFactor: CGFloat {
        switch self {
        case .light: return 0.85
        case .balanced: return 0.68
        case .maximum: return 0.45
        }
    }

    public var pdfTargetDPI: CGFloat {
        switch self {
        case .light: return 200.0
        case .balanced: return 144.0
        case .maximum: return 96.0
        }
    }
}

public enum ImageFormat: String, CaseIterable, Identifiable, Sendable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case webp = "WebP"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .webp: return "webp"
        }
    }

    public var uniformType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .webp: return UTType(filenameExtension: "webp") ?? .image
        }
    }

    public var supportsAlpha: Bool {
        switch self {
        case .jpeg: return false
        case .png, .heic, .webp: return true
        }
    }
}

public enum ImageResizeMode: Equatable, Sendable {
    case original
    case exact(width: Int, height: Int)
    case maxWidth(Int)
    case maxHeight(Int)
    case percentage(Int)
}

public struct ImageSettings: Equatable, Sendable {
    public var format: ImageFormat
    public var compressionPreset: CompressionPreset
    public var customQuality: Double?
    public var resizeMode: ImageResizeMode
    public var maintainAspectRatio: Bool
    public var preserveTransparency: Bool

    public init(
        format: ImageFormat = .jpeg,
        compressionPreset: CompressionPreset = .balanced,
        customQuality: Double? = nil,
        resizeMode: ImageResizeMode = .original,
        maintainAspectRatio: Bool = true,
        preserveTransparency: Bool = true
    ) {
        self.format = format
        self.compressionPreset = compressionPreset
        self.customQuality = customQuality
        self.resizeMode = resizeMode
        self.maintainAspectRatio = maintainAspectRatio
        self.preserveTransparency = preserveTransparency
    }
}

public enum PDFSplitMode: Equatable, Sendable {
    case allPages
    case pageRange(String)
}

public enum PDFPageSize: String, CaseIterable, Identifiable, Sendable {
    case matchImage = "Match Image"
    case a4 = "A4"
    case letter = "US Letter"

    public var id: String { rawValue }

    public var dimensionsInPoints: CGSize? {
        switch self {
        case .matchImage: return nil
        case .a4: return CGSize(width: 595.28, height: 841.89)
        case .letter: return CGSize(width: 612.0, height: 792.0)
        }
    }
}

public struct PDFSettings: Equatable, Sendable {
    public var compressionPreset: CompressionPreset
    public var splitMode: PDFSplitMode
    public var pdfToImageDPI: CGFloat
    public var pdfToImageFormat: ImageFormat
    public var imageToPDFPageSize: PDFPageSize
    public var rotationAngle: Int // 90, 180, 270

    public init(
        compressionPreset: CompressionPreset = .balanced,
        splitMode: PDFSplitMode = .allPages,
        pdfToImageDPI: CGFloat = 150.0,
        pdfToImageFormat: ImageFormat = .png,
        imageToPDFPageSize: PDFPageSize = .matchImage,
        rotationAngle: Int = 90
    ) {
        self.compressionPreset = compressionPreset
        self.splitMode = splitMode
        self.pdfToImageDPI = pdfToImageDPI
        self.pdfToImageFormat = pdfToImageFormat
        self.imageToPDFPageSize = imageToPDFPageSize
        self.rotationAngle = rotationAngle
    }
}
