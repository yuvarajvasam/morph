import Foundation
import CoreGraphics
import PDFKit

public final class CLIHandler {
    public static func run(arguments: [String]) async -> Int32 {
        guard !arguments.isEmpty else {
            printUsage()
            return 0
        }

        let command = arguments[0]
        let remainingArgs = Array(arguments.dropFirst())

        if command == "--help" || command == "-h" || command == "help" {
            printUsage()
            return 0
        }

        let isJSON = remainingArgs.contains("--json")

        do {
            switch command {
            case "info":
                return try await handleInfo(args: remainingArgs, json: isJSON)
            case "compress":
                return try await handleCompress(args: remainingArgs, json: isJSON)
            case "convert":
                return try await handleConvert(args: remainingArgs, json: isJSON)
            case "resize":
                return try await handleResize(args: remainingArgs, json: isJSON)
            case "merge":
                return try await handleMerge(args: remainingArgs, json: isJSON)
            case "split":
                return try await handleSplit(args: remainingArgs, json: isJSON)
            case "to-image":
                return try await handleToImage(args: remainingArgs, json: isJSON)
            case "to-pdf":
                return try await handleToPDF(args: remainingArgs, json: isJSON)
            default:
                print("❌ Unknown command '\(command)'. Run 'morph --help' for available commands.")
                return 1
            }
        } catch {
            if isJSON {
                let errJSON = "{\"error\": \"\(error.localizedDescription)\"}"
                print(errJSON)
            } else {
                print("❌ Error: \(error.localizedDescription)")
            }
            return 1
        }
    }

    // MARK: - Info Command

    private static func handleInfo(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph info <filepath> [--json]")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let item = FileProcessor.shared.inspect(url: url)

        if json {
            var dict: [String: Any] = [
                "filename": item.filename,
                "fileSize": item.fileSize,
                "formattedSize": item.formattedSize,
                "category": item.category.rawValue,
                "format": item.formatName
            ]
            if let dims = item.imageDimensions {
                dict["width"] = Int(dims.width)
                dict["height"] = Int(dims.height)
            }
            if let count = item.pageCount {
                dict["pageCount"] = count
            }
            if let alpha = item.hasAlpha {
                dict["hasAlpha"] = alpha
            }

            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            if let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            print("📄 File: \(item.filename)")
            print("  Category: \(item.category.rawValue.uppercased()) (\(item.formatName))")
            print("  Size:     \(item.formattedSize) (\(item.fileSize) bytes)")
            if let dims = item.dimensionsDescription {
                print("  Dimensions: \(dims)")
            }
            if let count = item.pageCount {
                print("  Pages:      \(count)")
            }
            if let alpha = item.hasAlpha {
                print("  Alpha:      \(alpha ? "Yes (Transparent)" : "No")")
            }
        }
        return 0
    }

    // MARK: - Compress Command

    private static func handleCompress(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph compress <filepath> [--preset light|balanced|maximum] [--json]")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let presetStr = getFlagValue(args, flag: "--preset")?.lowercased() ?? "balanced"
        let preset: CompressionPreset
        switch presetStr {
        case "light": preset = .light
        case "maximum", "max": preset = .maximum
        default: preset = .balanced
        }

        let outDir = resolveOutputDirectory(from: getFlagValue(args, flag: "--output"))
        let ext = url.pathExtension.lowercased()

        let result: ConversionResult
        if ext == "pdf" {
            result = try await PDFEngine.shared.compress(inputURL: url, preset: preset, destinationDirectory: outDir)
        } else {
            result = try await ImageEngine.shared.compress(inputURL: url, preset: preset, destinationDirectory: outDir)
        }

        printResult(result, json: json)
        return 0
    }

    // MARK: - Convert Command

    private static func handleConvert(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph convert <filepath> --to <jpg|png|heic|webp> [--json]")
            return 1
        }

        guard let targetStr = getFlagValue(args, flag: "--to")?.lowercased() else {
            print("❌ Target format required: --to <jpg|png|heic|webp>")
            return 1
        }

        let targetFormat: ImageFormat
        switch targetStr {
        case "jpg", "jpeg": targetFormat = .jpeg
        case "png": targetFormat = .png
        case "heic": targetFormat = .heic
        case "webp": targetFormat = .webp
        default:
            print("❌ Unsupported format: \(targetStr)")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let outDir = resolveOutputDirectory(from: getFlagValue(args, flag: "--output"))
        let result = try await ImageEngine.shared.convert(inputURL: url, targetFormat: targetFormat, destinationDirectory: outDir)

        printResult(result, json: json)
        return 0
    }

    // MARK: - Resize Command

    private static func handleResize(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph resize <filepath> [--width <w>] [--height <h>] [--max-width <mw>] [--scale <percent>]")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let outDir = resolveOutputDirectory(from: getFlagValue(args, flag: "--output"))

        let mode: ImageResizeMode
        if let wStr = getFlagValue(args, flag: "--width"), let hStr = getFlagValue(args, flag: "--height"),
           let w = Int(wStr), let h = Int(hStr) {
            mode = .exact(width: w, height: h)
        } else if let mwStr = getFlagValue(args, flag: "--max-width"), let mw = Int(mwStr) {
            mode = .maxWidth(mw)
        } else if let mhStr = getFlagValue(args, flag: "--max-height"), let mh = Int(mhStr) {
            mode = .maxHeight(mh)
        } else if let sStr = getFlagValue(args, flag: "--scale"), let s = Int(sStr) {
            mode = .percentage(s)
        } else {
            print("❌ Specify either --width and --height, --max-width, or --scale <percent>")
            return 1
        }

        let result = try await ImageEngine.shared.resize(inputURL: url, mode: mode, maintainAspectRatio: true, destinationDirectory: outDir)
        printResult(result, json: json)
        return 0
    }

    // MARK: - Merge Command

    private static func handleMerge(args: [String], json: Bool) async throws -> Int32 {
        let filePaths = args.filter { !$0.hasPrefix("-") }
        guard filePaths.count >= 2 else {
            print("Usage: morph merge <pdf1> <pdf2> ... [--output <filename>]")
            return 1
        }

        let urls = filePaths.map { URL(fileURLWithPath: $0) }
        let outName = getFlagValue(args, flag: "--output") ?? "merged-document.pdf"
        let outDir = getFlagValue(args, flag: "--dir").map { URL(fileURLWithPath: $0) }

        let result = try await PDFEngine.shared.merge(pdfURLs: urls, outputFilename: outName, destinationDirectory: outDir)
        printResult(result, json: json)
        return 0
    }

    // MARK: - Split Command

    private static func handleSplit(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph split <pdf> [--mode all | --range \"1-3, 5\"]")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let outDir = resolveOutputDirectory(from: getFlagValue(args, flag: "--output"))

        let mode: PDFSplitMode
        if let range = getFlagValue(args, flag: "--range") {
            mode = .pageRange(range)
        } else {
            mode = .allPages
        }

        let result = try await PDFEngine.shared.split(inputURL: url, mode: mode, destinationDirectory: outDir)
        printResult(result, json: json)
        return 0
    }

    // MARK: - PDF to Image Command

    private static func handleToImage(args: [String], json: Bool) async throws -> Int32 {
        guard let path = args.first(where: { !$0.hasPrefix("-") }) else {
            print("Usage: morph to-image <pdf> [--format png|jpg] [--dpi 150]")
            return 1
        }

        let url = URL(fileURLWithPath: path)
        let fmtStr = getFlagValue(args, flag: "--format")?.lowercased() ?? "png"
        let format: ImageFormat = (fmtStr == "jpg" || fmtStr == "jpeg") ? .jpeg : .png
        let dpiVal = CGFloat(Double(getFlagValue(args, flag: "--dpi") ?? "150") ?? 150.0)
        let rangeStr = getFlagValue(args, flag: "--range")
        let outDir = resolveOutputDirectory(from: getFlagValue(args, flag: "--output"))

        let result = try await PDFEngine.shared.pdfToImage(inputURL: url, format: format, dpi: dpiVal, pageRange: rangeStr, destinationDirectory: outDir)
        printResult(result, json: json)
        return 0
    }

    // MARK: - Images to PDF Command

    private static func handleToPDF(args: [String], json: Bool) async throws -> Int32 {
        let filePaths = args.filter { !$0.hasPrefix("-") }
        guard !filePaths.isEmpty else {
            print("Usage: morph to-pdf <img1> <img2> ... [--output <name.pdf>] [--size a4|letter|match]")
            return 1
        }

        let urls = filePaths.map { URL(fileURLWithPath: $0) }
        let outName = getFlagValue(args, flag: "--output") ?? "combined-images.pdf"
        let sizeStr = getFlagValue(args, flag: "--size")?.lowercased() ?? "match"
        let pageSize: PDFPageSize
        switch sizeStr {
        case "a4": pageSize = .a4
        case "letter": pageSize = .letter
        default: pageSize = .matchImage
        }

        let outDir = getFlagValue(args, flag: "--dir").map { URL(fileURLWithPath: $0) }
        let result = try await ImageEngine.shared.imagesToPDF(imageURLs: urls, pageSize: pageSize, destinationDirectory: outDir, outputFilename: outName)

        printResult(result, json: json)
        return 0
    }

    // MARK: - Helper Output Functions

    private static func printResult(_ res: ConversionResult, json: Bool) {
        if json {
            var dict: [String: Any] = [
                "originalSize": res.originalSize,
                "outputSize": res.outputSize,
                "bytesSaved": res.bytesSaved,
                "savingsPercentage": res.savingsPercentage,
                "durationSeconds": res.durationSeconds,
                "outputs": res.outputURLs.map { $0.path }
            ]
            if let dims = res.outputDimensions {
                dict["outputWidth"] = Int(dims.width)
                dict["outputHeight"] = Int(dims.height)
            }
            if let note = res.notes {
                dict["notes"] = note
            }
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            print("✨ Done in \(String(format: "%.2f", res.durationSeconds))s")
            print("  Original: \(res.formattedOriginalSize) -> Output: \(res.formattedOutputSize)")
            print("  Savings:  \(res.formattedSavingsText)")
            if let note = res.notes {
                print("  Note:     \(note)")
            }
            print("  Created:")
            for u in res.outputURLs {
                print("    👉 \(u.path)")
            }
        }
    }

    private static func resolveOutputDirectory(from flagValue: String?) -> URL? {
        guard let flagValue, !flagValue.isEmpty else { return nil }
        let url = URL(fileURLWithPath: flagValue)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            return isDir.boolValue ? url : url.deletingLastPathComponent()
        }
        if !url.pathExtension.isEmpty {
            return url.deletingLastPathComponent()
        }
        return url
    }

    private static func getFlagValue(_ args: [String], flag: String) -> String? {
        guard let idx = args.firstIndex(of: flag), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    public static func printUsage() {
        print("""
        🪄 Morph — Privacy-First Native macOS Image & PDF Utility

        USAGE:
          morph [command] [options]
          morph (without arguments opens the Liquid Glass floating launcher)

        COMMANDS:
          info <file>                     Inspect image or PDF metadata
          compress <file>                 Compress image or PDF (presets: light, balanced, maximum)
          convert <file> --to <fmt>       Convert image between JPEG, PNG, HEIC, WebP
          resize <file> [options]         Resize image (--width/--height, --max-width, --scale)
          merge <pdf1> <pdf2> ...         Merge multiple PDF documents
          split <pdf> [options]           Split PDF into single pages or extract range (--range "1-3")
          to-image <pdf> [options]        Export PDF pages as PNG/JPEG images (--dpi 72|150|300)
          to-pdf <img1> <img2> ...        Combine images into a multi-page PDF document

        FLAGS:
          --json                          Output structured JSON for Raycast / scripting
          --preset <p>                    Compression preset: light, balanced, maximum
          --output <dir|file>             Destination directory or filename
          -h, --help                      Show this help message

        EXAMPLES:
          morph compress photo.jpg --preset maximum
          morph convert icon.png --to webp
          morph resize banner.jpg --scale 50
          morph merge a.pdf b.pdf --output bundle.pdf
          morph split book.pdf --range "1-5, 10"
          morph info doc.pdf --json
        """)
    }
}
