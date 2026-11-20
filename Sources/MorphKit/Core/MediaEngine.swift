import Foundation

public final class MediaEngine: Sendable {
    public static let shared = MediaEngine()

    private let safety = FileSafetyService.shared
    private let engineManager = EngineManager.shared

    public init() {}

    // MARK: - Helper

    private func requireFFmpeg() throws -> String {
        guard let path = engineManager.findExecutable(named: "ffmpeg") else {
            throw ProcessingError.toolMissing("FFmpeg is required for audio and video conversion. Install it using:\n  brew install ffmpeg")
        }
        return path
    }

    // MARK: - Video Transcoding & Compression

    public func convertVideo(
        inputURL: URL,
        targetFormat: String = "mp4",
        crfPreset: CompressionPreset = .balanced,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let ffmpeg = try requireFFmpeg()
        let startTime = CFAbsoluteTimeGetCurrent()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let crf: String
        switch crfPreset {
        case .light: crf = "20"
        case .balanced: crf = "26"
        case .maximum: crf = "32"
        }

        let targetExt = targetFormat.lowercased().replacingOccurrences(of: ".", with: "")
        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "converted",
            newExtension: targetExt,
            in: destinationDirectory
        )

        var args = ["-y", "-i", inputURL.path]

        if targetExt == "mp4" || targetExt == "mov" || targetExt == "mkv" {
            args += ["-c:v", "libx264", "-crf", crf, "-preset", "medium", "-c:a", "aac", "-b:a", "192k"]
        } else if targetExt == "webm" {
            args += ["-c:v", "libvpx-vp9", "-crf", crf, "-b:v", "0", "-c:a", "libopus"]
        }

        args.append(destURL.path)

        let (exitCode, stdout, stderr) = try await engineManager.runProcess(executable: ffmpeg, arguments: args)
        guard exitCode == 0, FileManager.default.fileExists(atPath: destURL.path) else {
            throw ProcessingError.conversionFailed("FFmpeg video conversion failed (exit code \(exitCode)): \(stderr) \(stdout)")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: targetExt.uppercased(),
            durationSeconds: elapsed,
            notes: "Encoded with H.264 / AAC (CRF \(crf))."
        )
    }

    // MARK: - Video to Animated GIF

    public func videoToGIF(
        inputURL: URL,
        fps: Int = 15,
        width: Int = 480,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let ffmpeg = try requireFFmpeg()
        let startTime = CFAbsoluteTimeGetCurrent()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "animated",
            newExtension: "gif",
            in: destinationDirectory
        )

        let tempPalette = FileManager.default.temporaryDirectory.appendingPathComponent("palette_\(UUID().uuidString.prefix(6)).png")
        defer { try? FileManager.default.removeItem(at: tempPalette) }

        // Pass 1: Generate optimal palette
        let filter1 = "fps=\(fps),scale=\(width):-1:flags=lanczos,palettegen"
        let pass1Args = ["-y", "-i", inputURL.path, "-vf", filter1, tempPalette.path]
        let (p1Code, _, p1Err) = try await engineManager.runProcess(executable: ffmpeg, arguments: pass1Args)
        guard p1Code == 0 else {
            throw ProcessingError.conversionFailed("FFmpeg palette generation failed: \(p1Err)")
        }

        // Pass 2: Render crisp GIF with palette
        let filter2 = "fps=\(fps),scale=\(width):-1:flags=lanczos[x];[x][1:v]paletteuse"
        let pass2Args = ["-y", "-i", inputURL.path, "-i", tempPalette.path, "-filter_complex", filter2, destURL.path]
        let (p2Code, _, p2Err) = try await engineManager.runProcess(executable: ffmpeg, arguments: pass2Args)
        guard p2Code == 0, FileManager.default.fileExists(atPath: destURL.path) else {
            throw ProcessingError.conversionFailed("FFmpeg GIF generation failed: \(p2Err)")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: "GIF",
            durationSeconds: elapsed,
            notes: "Rendered at \(fps) fps (\(width)px width) with Lanczos palette mapping."
        )
    }

    // MARK: - Extract Audio from Video

    public func extractAudio(
        inputURL: URL,
        targetFormat: String = "mp3",
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let ffmpeg = try requireFFmpeg()
        let startTime = CFAbsoluteTimeGetCurrent()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let targetExt = targetFormat.lowercased().replacingOccurrences(of: ".", with: "")
        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "audio",
            newExtension: targetExt,
            in: destinationDirectory
        )

        var args = ["-y", "-i", inputURL.path, "-vn"]
        if targetExt == "mp3" {
            args += ["-c:a", "libmp3lame", "-q:a", "2"]
        } else if targetExt == "m4a" || targetExt == "aac" {
            args += ["-c:a", "aac", "-b:a", "256k"]
        } else if targetExt == "wav" {
            args += ["-c:a", "pcm_s16le"]
        }
        args.append(destURL.path)

        let (exitCode, stdout, stderr) = try await engineManager.runProcess(executable: ffmpeg, arguments: args)
        guard exitCode == 0, FileManager.default.fileExists(atPath: destURL.path) else {
            throw ProcessingError.conversionFailed("FFmpeg audio extraction failed (code \(exitCode)): \(stderr) \(stdout)")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: targetExt.uppercased(),
            durationSeconds: elapsed,
            notes: "Extracted audio track to \(targetExt.uppercased())."
        )
    }

    // MARK: - Audio Transcoding

    public func convertAudio(
        inputURL: URL,
        targetFormat: String = "mp3",
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let ffmpeg = try requireFFmpeg()
        let startTime = CFAbsoluteTimeGetCurrent()

        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? 0

        let targetExt = targetFormat.lowercased().replacingOccurrences(of: ".", with: "")
        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "audio-conv",
            newExtension: targetExt,
            in: destinationDirectory
        )

        let args = ["-y", "-i", inputURL.path, destURL.path]
        let (exitCode, stdout, stderr) = try await engineManager.runProcess(executable: ffmpeg, arguments: args)
        guard exitCode == 0, FileManager.default.fileExists(atPath: destURL.path) else {
            throw ProcessingError.conversionFailed("FFmpeg audio conversion failed: \(stderr) \(stdout)")
        }

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? 0
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: targetExt.uppercased(),
            durationSeconds: elapsed,
            notes: "Transcoded to \(targetExt.uppercased())."
        )
    }
}
