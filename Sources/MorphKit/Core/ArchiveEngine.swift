import Foundation
import AppKit

public enum ArchiveFormat: String, CaseIterable, Identifiable, Sendable {
    case zip = "ZIP"
    case tar = "TAR"
    case tarGz = "TAR.GZ"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .zip: return "zip"
        case .tar: return "tar"
        case .tarGz: return "tar.gz"
        }
    }
}

public final class ArchiveEngine: @unchecked Sendable {
    public static let shared = ArchiveEngine()

    private let safety = FileSafetyService.shared

    public init() {}

    public static let supportedExtensions: Set<String> = [
        "zip", "tar", "gz", "tgz", "bz2", "xz"
    ]

    public func isSupportedArchive(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if Self.supportedExtensions.contains(ext) {
            return true
        }
        let full = url.lastPathComponent.lowercased()
        if full.hasSuffix(".tar.gz") || full.hasSuffix(".tar.bz2") || full.hasSuffix(".tar.xz") {
            return true
        }
        return false
    }

    /// Inspects an archive's contents safely without full extraction.
    public func inspect(url: URL) throws -> (itemCount: Int, uncompressedSize: Int64, entries: [String]) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProcessingError.fileNotFound(url)
        }

        let ext = url.pathExtension.lowercased()
        let isZip = (ext == "zip")

        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        if isZip {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zipinfo")
            process.arguments = ["-1", url.path]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-tf", url.path]
        }

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return (0, 0, [])
        }

        let lines = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Security check: ensure no path traversal exploits like ../
        for entry in lines {
            if entry.contains("../") || entry.hasPrefix("/") {
                throw ProcessingError.corruptedFile("Archive contains potentially unsafe relative path: \(entry)")
            }
        }

        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let archiveSize = attributes[.size] as? Int64 ?? 0

        return (lines.count, archiveSize, lines)
    }

    /// Compresses one or more files/folders into a ZIP, TAR, or TAR.GZ archive.
    public func createArchive(
        sources: [URL],
        format: ArchiveFormat = .zip,
        customName: String? = nil,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        guard !sources.isEmpty else {
            throw ProcessingError.emptyInput
        }

        for src in sources {
            guard FileManager.default.fileExists(atPath: src.path) else {
                throw ProcessingError.fileNotFound(src)
            }
        }

        let startTime = Date()

        // Calculate original total size
        var totalOriginalSize: Int64 = 0
        for src in sources {
            if let size = try? directorySize(at: src) {
                totalOriginalSize += size
            }
        }

        let baseName: String
        if let custom = customName, !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            baseName = custom.trimmingCharacters(in: .whitespaces)
        } else if sources.count == 1 {
            baseName = sources[0].deletingPathExtension().lastPathComponent
        } else {
            baseName = "Archive"
        }

        let resolvedTargetDir: URL
        if let destinationDirectory {
            resolvedTargetDir = destinationDirectory
        } else {
            let prefTarget = await MainActor.run {
                PreferencesManager.shared.targetOutputDirectory(for: sources[0])
            }
            resolvedTargetDir = prefTarget ?? sources[0].deletingLastPathComponent()
        }

        // Generate safe output filename
        var finalURL = resolvedTargetDir.appendingPathComponent("\(baseName).\(format.fileExtension)")
        if FileManager.default.fileExists(atPath: finalURL.path) {
            var counter = 1
            while FileManager.default.fileExists(atPath: finalURL.path) {
                finalURL = resolvedTargetDir.appendingPathComponent("\(baseName) (\(counter)).\(format.fileExtension)")
                counter += 1
            }
        }

        let process = Process()
        process.standardError = Pipe()

        switch format {
        case .zip:
            if sources.count == 1 {
                process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", sources[0].path, finalURL.path]
            } else {
                let parentDir = sources[0].deletingLastPathComponent()
                process.currentDirectoryURL = parentDir
                process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                var args = ["-r", "-q", finalURL.path]
                for s in sources {
                    if s.deletingLastPathComponent().path == parentDir.path {
                        args.append(s.lastPathComponent)
                    } else {
                        args.append(s.path)
                    }
                }
                process.arguments = args
            }

        case .tar:
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            let parentDir = sources[0].deletingLastPathComponent().path
            var args = ["-cf", finalURL.path, "-C", parentDir]
            for s in sources {
                args.append(s.lastPathComponent)
            }
            process.arguments = args

        case .tarGz:
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            let parentDir = sources[0].deletingLastPathComponent().path
            var args = ["-czf", finalURL.path, "-C", parentDir]
            for s in sources {
                args.append(s.lastPathComponent)
            }
            process.arguments = args
        }

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: finalURL.path) else {
            throw ProcessingError.compressionFailed("Archive creation failed with status code \(process.terminationStatus).")
        }

        let finalAttributes = (try? FileManager.default.attributesOfItem(atPath: finalURL.path)) ?? [:]
        let outputSize = finalAttributes[.size] as? Int64 ?? 0

        var notes: String? = nil
        if outputSize >= totalOriginalSize && totalOriginalSize > 0 {
            notes = "Archive contains pre-compressed files. Output size is slightly larger due to archive headers."
        }

        let duration = Date().timeIntervalSince(startTime)

        return ConversionResult(
            originalURL: sources[0],
            outputURLs: [finalURL],
            originalSize: totalOriginalSize,
            outputSize: outputSize,
            outputFormat: format.rawValue,
            durationSeconds: duration,
            notes: notes
        )
    }

    /// Extracts an archive into a target directory.
    public func extractArchive(
        archiveURL: URL,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else {
            throw ProcessingError.fileNotFound(archiveURL)
        }

        let startTime = Date()
        let attributes = (try? FileManager.default.attributesOfItem(atPath: archiveURL.path)) ?? [:]
        let archiveSize = attributes[.size] as? Int64 ?? 0

        let folderName = archiveURL.deletingPathExtension().lastPathComponent + "-extracted"
        let resolvedTargetDir: URL
        if let destinationDirectory {
            resolvedTargetDir = destinationDirectory
        } else {
            let prefTarget = await MainActor.run {
                PreferencesManager.shared.targetOutputDirectory(for: archiveURL)
            }
            resolvedTargetDir = prefTarget ?? archiveURL.deletingLastPathComponent()
        }

        var extractDir = resolvedTargetDir.appendingPathComponent(folderName)
        if FileManager.default.fileExists(atPath: extractDir.path) {
            var counter = 1
            while FileManager.default.fileExists(atPath: extractDir.path) {
                extractDir = resolvedTargetDir.appendingPathComponent("\(folderName) (\(counter))")
                counter += 1
            }
        }

        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let ext = archiveURL.pathExtension.lowercased()
        let process = Process()
        process.standardError = Pipe()

        if ext == "zip" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", archiveURL.path, extractDir.path]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-xf", archiveURL.path, "-C", extractDir.path]
        }

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ProcessingError.conversionFailed("Archive extraction failed with code \(process.terminationStatus).")
        }

        let extractedSize = (try? directorySize(at: extractDir)) ?? archiveSize
        let duration = Date().timeIntervalSince(startTime)

        return ConversionResult(
            originalURL: archiveURL,
            outputURLs: [extractDir],
            originalSize: archiveSize,
            outputSize: extractedSize,
            outputFormat: "Folder",
            durationSeconds: duration,
            notes: "Extracted contents saved to \(extractDir.lastPathComponent)"
        )
    }

    private func directorySize(at url: URL) throws -> Int64 {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
                return 0
            }
            var size: Int64 = 0
            for case let fileURL as URL in enumerator {
                let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                size += Int64(values.fileSize ?? 0)
            }
            return size
        } else {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(values.fileSize ?? 0)
        }
    }
}
