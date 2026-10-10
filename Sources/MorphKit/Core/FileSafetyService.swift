import Foundation
import CoreGraphics
import ImageIO
import PDFKit

public final class FileSafetyService: @unchecked Sendable {
    public static let shared = FileSafetyService()

    private let fileManager = FileManager.default
    private let tempDirectory: URL

    private init() {
        let baseTemp = fileManager.temporaryDirectory
        let morphTemp = baseTemp.appendingPathComponent("com.morph.utility.temp", isDirectory: true)
        self.tempDirectory = morphTemp
        try? fileManager.createDirectory(at: morphTemp, withIntermediateDirectories: true)
    }

    /// Creates a fresh unique temporary file URL that does not conflict with any existing file.
    public func createTemporaryFileURL(extension ext: String) throws -> URL {
        try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let uniqueID = UUID().uuidString.prefix(8)
        let filename = "morph_temp_\(uniqueID).\(ext)"
        return tempDirectory.appendingPathComponent(filename)
    }

    /// Cleans up all files in the managed temporary directory.
    public func cleanupTemporaryFiles() {
        guard let items = try? fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for item in items {
            try? fileManager.removeItem(at: item)
        }
    }

    /// Generates a non-conflicting destination URL next to the original file (or in chosen folder).
    /// Never overwrites an existing file.
    public func generateSafeDestinationURL(
        originalURL: URL,
        suffix: String,
        targetExtension: String? = nil,
        destinationDirectory: URL? = nil
    ) -> URL {
        let baseDir = destinationDirectory ?? originalURL.deletingLastPathComponent()
        let originalNameWithoutExt = originalURL.deletingPathExtension().lastPathComponent
        let ext = targetExtension ?? originalURL.pathExtension

        let baseCandidateName = "\(originalNameWithoutExt)\(suffix)"
        var candidateURL = baseDir.appendingPathComponent("\(baseCandidateName).\(ext)")

        var counter = 1
        while fileManager.fileExists(atPath: candidateURL.path) {
            candidateURL = baseDir.appendingPathComponent("\(baseCandidateName) (\(counter)).\(ext)")
            counter += 1
        }

        return candidateURL
    }

    /// Validates that the generated output exists, is non-empty, and can be decoded by system frameworks.
    public func validateOutputFile(url: URL, expectedCategory: FileCategory) throws {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
            throw ProcessingError.writeFailed("Output file does not exist at path: \(url.path)")
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > 0 else {
            throw ProcessingError.corruptedFile("Generated file is 0 bytes or unreadable.")
        }

        switch expectedCategory {
        case .image:
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                throw ProcessingError.corruptedFile("Output image could not be decoded by ImageIO.")
            }
            guard CGImageSourceGetCount(source) > 0 else {
                throw ProcessingError.corruptedFile("Output image contains zero valid frames.")
            }
        case .pdf:
            guard let pdf = PDFDocument(url: url) else {
                throw ProcessingError.corruptedFile("Output PDF could not be parsed by PDFKit.")
            }
            guard pdf.pageCount > 0 else {
                throw ProcessingError.corruptedFile("Output PDF has 0 pages.")
            }
        case .archive:
            guard (try? ArchiveEngine.shared.inspect(url: url)) != nil else {
                throw ProcessingError.corruptedFile("Output archive could not be verified.")
            }
        case .unsupported:
            break
        }
    }

    /// Safely wraps file operations requiring security-scoped access (e.g. App Sandbox file dialogs).
    public func withSecurityScope<T>(for url: URL, _ action: () throws -> T) rethrows -> T {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try action()
    }
}
