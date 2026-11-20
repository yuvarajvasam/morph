import Foundation

public struct EngineInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let isNative: Bool
    public let isAvailable: Bool
    public let version: String?
    public let path: String?
    public let installCommand: String?
    public let description: String
    public let supportedConversions: [String]

    public var statusBadgeText: String {
        if isNative {
            return "Built-in (macOS)"
        } else if isAvailable {
            return "Installed"
        } else {
            return "Missing Tool"
        }
    }
}

public final class EngineManager: @unchecked Sendable {
    public static let shared = EngineManager()

    private let fileManager = FileManager.default

    public init() {}

    // MARK: - Executable Resolution

    public func findExecutable(named name: String) -> String? {
        let commonPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)",
            "/opt/homebrew/sbin/\(name)",
            "/usr/local/sbin/\(name)",
            "\(NSHomeDirectory())/.local/bin/\(name)",
            "\(NSHomeDirectory())/bin/\(name)"
        ]

        for path in commonPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Check PATH environment variable
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            let directories = pathEnv.split(separator: ":").map { String($0) }
            for dir in directories {
                let candidate = (dir as NSString).appendingPathComponent(name)
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    public func findLibreOffice() -> String? {
        let appPaths = [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            "\(NSHomeDirectory())/Applications/LibreOffice.app/Contents/MacOS/soffice"
        ]
        for path in appPaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }
        return findExecutable(named: "soffice")
    }

    // MARK: - Process Execution

    @discardableResult
    public func runProcess(
        executable: String,
        arguments: [String],
        workingDirectory: URL? = nil
    ) async throws -> (exitCode: Int32, stdout: String, stderr: String) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                if let workingDirectory {
                    process.currentDirectoryURL = workingDirectory
                }

                var env = ProcessInfo.processInfo.environment
                let extraPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
                if let current = env["PATH"] {
                    env["PATH"] = "\(extraPaths):\(current)"
                } else {
                    env["PATH"] = extraPaths
                }
                process.environment = env

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdout = String(data: outData, encoding: .utf8) ?? ""
                    let stderr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: (process.terminationStatus, stdout, stderr))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Tool Version Queries

    public func queryVersion(executable: String, versionFlag: String = "--version") async -> String? {
        do {
            let res = try await runProcess(executable: executable, arguments: [versionFlag])
            let output = res.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? res.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                : res.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            if let firstLine = output.components(separatedBy: .newlines).first {
                return firstLine
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Engines List

    public func allEngines() async -> [EngineInfo] {
        let ffmpegPath = findExecutable(named: "ffmpeg")
        let ffmpegVersion = ffmpegPath != nil ? await queryVersion(executable: ffmpegPath!, versionFlag: "-version") : nil

        let libreOfficePath = findLibreOffice()
        let libreOfficeVersion = libreOfficePath != nil ? await queryVersion(executable: libreOfficePath!, versionFlag: "--version") : nil

        let pandocPath = findExecutable(named: "pandoc")
        let pandocVersion = pandocPath != nil ? await queryVersion(executable: pandocPath!, versionFlag: "--version") : nil

        let exiftoolPath = findExecutable(named: "exiftool")
        let exiftoolVersion = exiftoolPath != nil ? await queryVersion(executable: exiftoolPath!, versionFlag: "-ver") : nil

        let whisperPath = findExecutable(named: "whisper") ?? findExecutable(named: "whisper-cli")
        let whisperVersion = whisperPath != nil ? await queryVersion(executable: whisperPath!, versionFlag: "--help") : nil

        return [
            // Built-in Native Engines
            EngineInfo(
                id: "engine.vision",
                name: "Apple Vision OCR",
                category: "Text Recognition",
                isNative: true,
                isAvailable: true,
                version: "macOS System Vision.framework",
                path: "/System/Library/Frameworks/Vision.framework",
                installCommand: nil,
                description: "On-device Neural Engine/GPU OCR for images and PDFs. Zero cloud, 100% offline.",
                supportedConversions: ["Images → Text", "Scanned PDF → Searchable PDF", "PDF → Text"]
            ),
            EngineInfo(
                id: "engine.imageio",
                name: "Apple ImageIO & Core Graphics",
                category: "Images",
                isNative: true,
                isAvailable: true,
                version: "macOS Native ImageIO",
                path: "/System/Library/Frameworks/ImageIO.framework",
                installCommand: nil,
                description: "Hardware-accelerated image encoding, resizing, color-space management, and compression.",
                supportedConversions: ["JPEG, PNG, HEIC, WebP, TIFF ↔ All", "Image Resizing", "Metadata Stripping"]
            ),
            EngineInfo(
                id: "engine.pdfkit",
                name: "Apple PDFKit & Quartz",
                category: "Documents",
                isNative: true,
                isAvailable: true,
                version: "macOS Native PDFKit",
                path: "/System/Library/Frameworks/PDFKit.framework",
                installCommand: nil,
                description: "Native high-performance PDF manipulation, vector downsampling, split, merge, and rendering.",
                supportedConversions: ["PDF Merge", "PDF Split", "PDF Compression", "PDF → Images", "Page Management"]
            ),
            EngineInfo(
                id: "engine.iconutil",
                name: "Apple Icon Utility",
                category: "Icons",
                isNative: true,
                isAvailable: true,
                version: "macOS System iconutil",
                path: "/usr/bin/iconutil",
                installCommand: nil,
                description: "Generates native multi-resolution Apple .icns application icons (16px to 1024px).",
                supportedConversions: ["Images → macOS .icns", ".icns → PNG"]
            ),
            EngineInfo(
                id: "engine.data",
                name: "Apple Foundation Data Engine",
                category: "Structured Data",
                isNative: true,
                isAvailable: true,
                version: "macOS PropertyList & JSONSerialization",
                path: "/System/Library/Frameworks/Foundation.framework",
                installCommand: nil,
                description: "High-speed conversion between JSON, macOS Property Lists (.plist), XML, and CSV.",
                supportedConversions: ["JSON ↔ Plist", "JSON ↔ CSV", "Plist ↔ XML", "Format / Prettify"]
            ),
            EngineInfo(
                id: "engine.coreimage",
                name: "Apple CoreImage Barcode Engine",
                category: "Codes",
                isNative: true,
                isAvailable: true,
                version: "macOS CoreImage CIFilters",
                path: "/System/Library/Frameworks/CoreImage.framework",
                installCommand: nil,
                description: "Generates and scans QR codes (with Wi-Fi, vCard, URLs) and Code 128 barcodes.",
                supportedConversions: ["QR Generator", "Barcode 128", "Vision QR / Barcode Scanner"]
            ),
            // Optional External CLI Engines (Filee style)
            EngineInfo(
                id: "engine.ffmpeg",
                name: "FFmpeg Media Engine",
                category: "Audio & Video",
                isNative: false,
                isAvailable: ffmpegPath != nil,
                version: ffmpegVersion,
                path: ffmpegPath,
                installCommand: "brew install ffmpeg",
                description: "Industry-standard multimedia transcoding, video-to-GIF conversion, and audio extraction.",
                supportedConversions: ["Video ↔ Video (MP4, MOV, MKV, WebM)", "Video → GIF", "Extract Audio", "Audio Transcoding"]
            ),
            EngineInfo(
                id: "engine.libreoffice",
                name: "LibreOffice Headless Engine",
                category: "Office Documents",
                isNative: false,
                isAvailable: libreOfficePath != nil,
                version: libreOfficeVersion,
                path: libreOfficePath,
                installCommand: "brew install --cask libreoffice",
                description: "Converts Word (.docx, .doc), PowerPoint (.pptx, .ppt), and Excel (.xlsx, .xls) to PDF.",
                supportedConversions: ["DOCX, DOC → PDF", "PPTX, PPT → PDF", "XLSX, XLS → PDF", "ODT, RTF → PDF"]
            ),
            EngineInfo(
                id: "engine.pandoc",
                name: "Pandoc Document Markup Engine",
                category: "Documents & Markup",
                isNative: false,
                isAvailable: pandocPath != nil,
                version: pandocVersion,
                path: pandocPath,
                installCommand: "brew install pandoc",
                description: "Universal document converter for Markdown, LaTeX, EPUB, and HTML documents.",
                supportedConversions: ["Markdown → PDF", "Markdown → HTML", "Markdown → DOCX"]
            ),
            EngineInfo(
                id: "engine.exiftool",
                name: "ExifTool Engine",
                category: "Metadata",
                isNative: false,
                isAvailable: exiftoolPath != nil,
                version: exiftoolVersion,
                path: exiftoolPath,
                installCommand: "brew install exiftool",
                description: "Deep inspection and editing of image and media metadata tags and color profiles.",
                supportedConversions: ["Deep EXIF Inspection", "GPS & Private Tag Purge"]
            ),
            EngineInfo(
                id: "engine.whisper",
                name: "Whisper Speech Engine",
                category: "Transcription",
                isNative: false,
                isAvailable: whisperPath != nil,
                version: whisperVersion,
                path: whisperPath,
                installCommand: "brew install whisper-cpp",
                description: "Offline speech recognition and automatic subtitle/transcript generation.",
                supportedConversions: ["Audio/Video → Subtitles (.srt, .vtt)", "Audio → Text Transcript"]
            )
        ]
    }
}
