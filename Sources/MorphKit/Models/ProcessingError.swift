import Foundation

public enum ProcessingError: LocalizedError, Sendable, Equatable {
    case fileNotFound(URL)
    case unreadableFile(URL)
    case unsupportedFormat(String)
    case invalidDimensions
    case invalidPageRange(String)
    case compressionFailed(String)
    case conversionFailed(String)
    case corruptedFile(String)
    case cancelled
    case writeFailed(String)
    case destinationConflict(URL)
    case emptyInput
    case pdfEncrypted
    case outOfMemory

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found at: \(url.path)"
        case .unreadableFile(let url):
            return "Unable to read file: \(url.lastPathComponent). Please check permissions."
        case .unsupportedFormat(let ext):
            return "Unsupported format: .\(ext). Supported formats are JPEG, PNG, HEIC, WebP, and PDF."
        case .invalidDimensions:
            return "Invalid target dimensions. Width and height must be greater than zero."
        case .invalidPageRange(let range):
            return "Invalid page range '\(range)'. Format examples: '1-3, 5, 8-10'."
        case .compressionFailed(let reason):
            return "Compression failed: \(reason)"
        case .conversionFailed(let reason):
            return "Format conversion failed: \(reason)"
        case .corruptedFile(let reason):
            return "The file appears corrupted or invalid: \(reason)"
        case .cancelled:
            return "Operation was cancelled by user."
        case .writeFailed(let reason):
            return "Unable to save output file: \(reason)"
        case .destinationConflict(let url):
            return "Destination file already exists: \(url.lastPathComponent)"
        case .emptyInput:
            return "No input files provided."
        case .pdfEncrypted:
            return "The PDF document is password-protected or encrypted."
        case .outOfMemory:
            return "Operation exceeded available system memory."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidPageRange:
            return "Check the total page count and specify ranges like '1-3' or individual pages like '1, 3, 5'."
        case .unsupportedFormat:
            return "Convert the file to a supported format (PNG, JPEG, HEIC, or PDF) first."
        case .pdfEncrypted:
            return "Unlock or decrypt the PDF before manipulating it."
        case .compressionFailed:
            return "Try using the Balanced or Light preset, or check if the file is already highly compressed."
        default:
            return "Try again or check file permissions."
        }
    }
}
