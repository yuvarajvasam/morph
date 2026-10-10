import Foundation
import CoreGraphics

public struct ConversionResult: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let originalURL: URL
    public let outputURLs: [URL] // Can be multiple files, e.g. for split PDF or PDF to Image
    public let originalSize: Int64
    public let outputSize: Int64
    public let originalDimensions: CGSize?
    public let outputDimensions: CGSize?
    public let outputFormat: String
    public let durationSeconds: Double
    public let isOutputLargerThanOriginal: Bool
    public let notes: String?

    public init(
        id: UUID = UUID(),
        originalURL: URL,
        outputURLs: [URL],
        originalSize: Int64,
        outputSize: Int64,
        originalDimensions: CGSize? = nil,
        outputDimensions: CGSize? = nil,
        outputFormat: String,
        durationSeconds: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.originalURL = originalURL
        self.outputURLs = outputURLs
        self.originalSize = originalSize
        self.outputSize = outputSize
        self.originalDimensions = originalDimensions
        self.outputDimensions = outputDimensions
        self.outputFormat = outputFormat
        self.durationSeconds = durationSeconds
        self.isOutputLargerThanOriginal = outputSize > originalSize
        self.notes = notes
    }

    public var primaryOutputURL: URL? {
        outputURLs.first
    }

    public var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file)
    }

    public var formattedOutputSize: String {
        ByteCountFormatter.string(fromByteCount: outputSize, countStyle: .file)
    }

    public var bytesSaved: Int64 {
        max(0, originalSize - outputSize)
    }

    public var formattedBytesSaved: String {
        ByteCountFormatter.string(fromByteCount: bytesSaved, countStyle: .file)
    }

    public var savingsPercentage: Double {
        guard originalSize > 0 else { return 0.0 }
        let diff = Double(originalSize - outputSize)
        return (diff / Double(originalSize)) * 100.0
    }

    public var formattedSavingsText: String {
        if isOutputLargerThanOriginal {
            let increase = abs(savingsPercentage)
            return "+\(String(format: "%.1f", increase))% (larger than original)"
        } else {
            return "-\(String(format: "%.1f", savingsPercentage))% saved (\(formattedBytesSaved))"
        }
    }
}
