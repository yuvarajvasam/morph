import Foundation

public final class DataEngine: Sendable {
    public static let shared = DataEngine()

    private let safety = FileSafetyService.shared

    public init() {}

    // MARK: - Convert Data Format

    public func convertData(
        inputURL: URL,
        targetFormat: String,
        destinationDirectory: URL? = nil
    ) async throws -> ConversionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fromExt = inputURL.pathExtension.lowercased()
        let toExt = targetFormat.lowercased().replacingOccurrences(of: ".", with: "")

        let originalData = try Data(contentsOf: inputURL)
        let originalAttributes = (try? FileManager.default.attributesOfItem(atPath: inputURL.path)) ?? [:]
        let originalSize = originalAttributes[.size] as? Int64 ?? Int64(originalData.count)

        let outputData: Data

        if fromExt == "json" && toExt == "plist" {
            // JSON -> Plist
            let jsonObject = try JSONSerialization.jsonObject(with: originalData, options: [])
            outputData = try PropertyListSerialization.data(fromPropertyList: jsonObject, format: .xml, options: 0)
        } else if fromExt == "plist" && toExt == "json" {
            // Plist -> JSON
            var format = PropertyListSerialization.PropertyListFormat.xml
            let plistObject = try PropertyListSerialization.propertyList(from: originalData, options: [], format: &format)
            outputData = try JSONSerialization.data(withJSONObject: plistObject, options: [.prettyPrinted, .sortedKeys])
        } else if fromExt == "json" && toExt == "csv" {
            // JSON -> CSV
            let jsonObject = try JSONSerialization.jsonObject(with: originalData, options: [])
            if let array = jsonObject as? [[String: Any]] {
                outputData = try generateCSV(from: array)
            } else if let dict = jsonObject as? [String: Any] {
                outputData = try generateCSV(from: [dict])
            } else {
                throw ProcessingError.conversionFailed("JSON root must be an object or an array of objects to convert to CSV.")
            }
        } else if fromExt == "csv" && toExt == "json" {
            // CSV -> JSON
            guard let csvString = String(data: originalData, encoding: .utf8) else {
                throw ProcessingError.unreadableFile(inputURL)
            }
            let objects = parseCSV(csvString)
            outputData = try JSONSerialization.data(withJSONObject: objects, options: [.prettyPrinted, .sortedKeys])
        } else if (fromExt == "json" && toExt == "json") || toExt == "format" {
            // Format / Prettify JSON
            let jsonObject = try JSONSerialization.jsonObject(with: originalData, options: [])
            outputData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        } else {
            throw ProcessingError.unsupportedFormatForTool(format: fromExt, tool: "Data Converter", supported: "JSON, PLIST, CSV")
        }

        let destURL = safety.uniqueDestinationURL(
            for: inputURL,
            suffix: "data",
            newExtension: toExt == "format" ? fromExt : toExt,
            in: destinationDirectory
        )

        try outputData.write(to: destURL, options: .atomic)

        let outputAttributes = (try? FileManager.default.attributesOfItem(atPath: destURL.path)) ?? [:]
        let outputSize = outputAttributes[.size] as? Int64 ?? Int64(outputData.count)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        return ConversionResult(
            originalURL: inputURL,
            outputURLs: [destURL],
            originalSize: originalSize,
            outputSize: outputSize,
            outputFormat: toExt.uppercased(),
            durationSeconds: elapsed,
            notes: "Converted \(fromExt.uppercased()) data to \(toExt.uppercased())."
        )
    }

    // MARK: - CSV Helpers

    private func generateCSV(from array: [[String: Any]]) throws -> Data {
        guard !array.isEmpty else { return Data("".utf8) }

        // Gather all unique keys across rows
        var allKeys: [String] = []
        for row in array {
            for key in row.keys where !allKeys.contains(key) {
                allKeys.append(key)
            }
        }

        var lines: [String] = []
        // Header
        let escapedHeaders = allKeys.map { escapeCSVValue($0) }
        lines.append(escapedHeaders.joined(separator: ","))

        // Data rows
        for row in array {
            let values = allKeys.map { key -> String in
                if let val = row[key] {
                    return escapeCSVValue("\(val)")
                }
                return ""
            }
            lines.append(values.joined(separator: ","))
        }

        return Data(lines.joined(separator: "\n").utf8)
    }

    private func escapeCSVValue(_ val: String) -> String {
        if val.contains(",") || val.contains("\"") || val.contains("\n") {
            let escaped = val.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return val
    }

    private func parseCSV(_ csv: String) -> [[String: String]] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return [] }

        let headers = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
        var result: [[String: String]] = []

        for line in lines.dropFirst() {
            let cols = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
            var row: [String: String] = [:]
            for (idx, header) in headers.enumerated() {
                if idx < cols.count {
                    row[header] = cols[idx]
                }
            }
            if !row.isEmpty {
                result.append(row)
            }
        }

        return result
    }
}
