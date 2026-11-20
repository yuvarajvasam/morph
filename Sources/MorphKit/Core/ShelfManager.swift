import Foundation
import AppKit
import QuickLookThumbnailing

@MainActor
public final class ShelfManager: ObservableObject {
    public static let shared = ShelfManager()

    @Published public var items: [ShelfItem] = []
    @Published public var selectedItemId: UUID? = nil
    @Published public var isProcessing: Bool = false
    @Published public var statusMessage: String? = nil
    @Published public var activeCollection: String = "Main"
    @Published public var availableCollections: [String] = ["Main", "Work", "Scratch"]

    private let baseStorageKey = "morph.shelf.collection."
    private let legacyStorageKey = "morph.shelf.persisted_paths"

    public init() {
        loadPersistedItems()
    }

    // MARK: - Adding Items
    public func addItems(urls: [URL]) {
        for url in urls {
            // Check for duplicate URLs in active collection
            if items.contains(where: { $0.url.absoluteString == url.absoluteString }) {
                continue
            }

            var newItem = ShelfItem(url: url)

            // Setup default thumbnail or icon
            if newItem.isWebLink {
                // Link items use custom SVG/symbol rendering in DropShelfView
                newItem.thumbnail = nil
            } else if url.isFileURL {
                newItem.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
            }

            items.append(newItem)

            let itemId = newItem.id
            if url.isFileURL && !newItem.isDirectory {
                Task {
                    if let thumb = await self.generateThumbnail(for: url) {
                        if let idx = self.items.firstIndex(where: { $0.id == itemId }) {
                            self.items[idx].thumbnail = thumb
                        }
                    }
                }
            }
        }
        savePersistedItems()
        SoundEffectManager.shared.playSuccess()
    }

    public func addItem(url: URL) {
        addItems(urls: [url])
    }

    public func addLink(urlString: String) {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.lowercased().hasPrefix("http://") && !clean.lowercased().hasPrefix("https://") {
            clean = "https://" + clean
        }
        if let url = URL(string: clean) {
            addItem(url: url)
        }
    }

    // MARK: - Removing & Clearing Items
    public func removeItem(id: UUID) {
        items.removeAll(where: { $0.id == id })
        if selectedItemId == id {
            selectedItemId = nil
        }
        savePersistedItems()
    }

    public func clearShelf() {
        items.removeAll()
        selectedItemId = nil
        savePersistedItems()
    }

    // MARK: - Workspace / Collections Management
    public func switchCollection(to name: String) {
        guard name != activeCollection else { return }
        savePersistedItems()
        activeCollection = name
        if !availableCollections.contains(name) {
            availableCollections.append(name)
        }
        items.removeAll()
        selectedItemId = nil
        loadPersistedItems()
    }

    public func createWorkspace(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !availableCollections.contains(trimmed) {
            availableCollections.append(trimmed)
        }
        switchCollection(to: trimmed)
    }

    // MARK: - Executing Shelf Actions
    public func executeAction(_ action: ShelfActionType, on item: ShelfItem) async {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "Running \(action.rawValue)..."

        let sourceURL = item.url
        var resultURL: URL? = nil

        do {
            switch action {
            case .compress:
                switch item.category {
                case .image:
                    let res = try await ImageEngine.shared.compress(inputURL: sourceURL, preset: .balanced)
                    resultURL = res.primaryOutputURL
                case .pdf:
                    let res = try await PDFEngine.shared.compress(inputURL: sourceURL, preset: .balanced)
                    resultURL = res.primaryOutputURL
                case .media:
                    let res = try await MediaEngine.shared.convertVideo(inputURL: sourceURL, targetFormat: "mp4", crfPreset: .balanced)
                    resultURL = res.primaryOutputURL
                case .audio:
                    let res = try await MediaEngine.shared.extractAudio(inputURL: sourceURL, targetFormat: "mp3")
                    resultURL = res.primaryOutputURL
                case .folder:
                    let res = try await ArchiveEngine.shared.createArchive(
                        sources: [sourceURL],
                        format: .zip,
                        customName: sourceURL.lastPathComponent,
                        destinationDirectory: sourceURL.deletingLastPathComponent()
                    )
                    resultURL = res.primaryOutputURL
                default:
                    throw ProcessingError.unsupportedFormat(item.name)
                }

            case .convert:
                switch item.category {
                case .image:
                    let targetFormat: ImageFormat = sourceURL.pathExtension.lowercased() == "png" ? .jpeg : .png
                    let res = try await ImageEngine.shared.convert(inputURL: sourceURL, targetFormat: targetFormat)
                    resultURL = res.primaryOutputURL
                case .media:
                    let targetFmt = sourceURL.pathExtension.lowercased() == "mov" ? "mp4" : "mov"
                    let res = try await MediaEngine.shared.convertVideo(inputURL: sourceURL, targetFormat: targetFmt)
                    resultURL = res.primaryOutputURL
                case .audio:
                    let targetFmt = sourceURL.pathExtension.lowercased() == "wav" ? "mp3" : "wav"
                    let res = try await MediaEngine.shared.extractAudio(inputURL: sourceURL, targetFormat: targetFmt)
                    resultURL = res.primaryOutputURL
                case .vector:
                    let res = try await VectorEngine.shared.svgToImage(inputURL: sourceURL, targetFormat: .png)
                    resultURL = res.primaryOutputURL
                default:
                    throw ProcessingError.unsupportedFormat(item.name)
                }

            case .toPDF:
                switch item.category {
                case .image:
                    let res = try await ImageEngine.shared.imagesToPDF(imageURLs: [sourceURL])
                    resultURL = res.primaryOutputURL
                case .office:
                    if sourceURL.pathExtension.lowercased() == "md" || sourceURL.pathExtension.lowercased() == "markdown" {
                        let res = try await OfficeEngine.shared.markdownToPDF(inputURL: sourceURL)
                        resultURL = res.primaryOutputURL
                    } else {
                        let res = try await OfficeEngine.shared.officeToPDF(inputURL: sourceURL)
                        resultURL = res.primaryOutputURL
                    }
                case .vector:
                    let res = try await VectorEngine.shared.svgToPDF(inputURL: sourceURL)
                    resultURL = res.primaryOutputURL
                default:
                    throw ProcessingError.unsupportedFormat(item.name)
                }

            case .ocr:
                if sourceURL.pathExtension.lowercased() == "pdf" {
                    let text = try await OCREngine.shared.recognizePDF(pdfURL: sourceURL)
                    let res = try await OCREngine.shared.exportText(text: text, baseFilename: sourceURL.lastPathComponent)
                    resultURL = res.primaryOutputURL
                } else if item.category == .image {
                    let text = try await OCREngine.shared.recognizeText(imageURL: sourceURL)
                    let res = try await OCREngine.shared.exportText(text: text, baseFilename: sourceURL.lastPathComponent)
                    resultURL = res.primaryOutputURL
                } else {
                    throw ProcessingError.unsupportedFormat("OCR requires an image or PDF")
                }

            case .makeIcon:
                if sourceURL.pathExtension.lowercased() == "icns" {
                    let res = try await IconEngine.shared.extractFromICNS(icnsURL: sourceURL)
                    resultURL = res.primaryOutputURL
                } else if item.category == .image {
                    let res = try await IconEngine.shared.convertToICNS(imageURL: sourceURL)
                    resultURL = res.primaryOutputURL
                } else {
                    throw ProcessingError.unsupportedFormat("Make Icon requires an image or .icns file")
                }

            case .extractAudio:
                if item.category == .media || item.category == .audio {
                    let res = try await MediaEngine.shared.extractAudio(inputURL: sourceURL, targetFormat: "mp3")
                    resultURL = res.primaryOutputURL
                } else {
                    throw ProcessingError.unsupportedFormat("Audio extraction requires a video or audio file")
                }

            case .stripMetadata:
                let res = try await MetadataEngine.shared.stripMetadata(inputURL: sourceURL)
                resultURL = res.primaryOutputURL

            case .delete:
                removeItem(id: item.id)
                isProcessing = false
                statusMessage = nil
                return
            }

            if let out = resultURL {
                self.addItem(url: out)
                self.statusMessage = "Created \(out.lastPathComponent)"
                SoundEffectManager.shared.playSuccess()
            }
        } catch {
            self.statusMessage = "Failed: \(error.localizedDescription)"
            SoundEffectManager.shared.playError()
        }

        self.isProcessing = false
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        if self.statusMessage?.hasPrefix("Created") == true {
            self.statusMessage = nil
        }
    }

    // MARK: - Thumbnail Generation
    private func generateThumbnail(for url: URL) async -> NSImage? {
        // Fallback directly to image contents for fast rendering if it's an image
        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "webp", "gif"].contains(ext) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }

        let size = CGSize(width: 160, height: 160)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)

        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return representation.nsImage
        } catch {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
    }

    // MARK: - Persistence
    private func savePersistedItems() {
        let rawValues = items.map { $0.url.absoluteString }
        UserDefaults.standard.set(rawValues, forKey: baseStorageKey + activeCollection)
        // Also update legacy key for "Main" compatibility
        if activeCollection == "Main" {
            UserDefaults.standard.set(items.map { $0.url.path }, forKey: legacyStorageKey)
        }
    }

    private func loadPersistedItems() {
        // First try the collection key
        if let strings = UserDefaults.standard.stringArray(forKey: baseStorageKey + activeCollection), !strings.isEmpty {
            for str in strings {
                if str.lowercased().hasPrefix("http://") || str.lowercased().hasPrefix("https://") {
                    if let url = URL(string: str) {
                        items.append(ShelfItem(url: url))
                    }
                } else {
                    let url = str.hasPrefix("file://") ? (URL(string: str) ?? URL(fileURLWithPath: str)) : URL(fileURLWithPath: str)
                    if FileManager.default.fileExists(atPath: url.path) {
                        var item = ShelfItem(url: url)
                        item.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
                        items.append(item)

                        let itemId = item.id
                        if !item.isDirectory {
                            Task {
                                if let thumb = await self.generateThumbnail(for: url) {
                                    if let idx = self.items.firstIndex(where: { $0.id == itemId }) {
                                        self.items[idx].thumbnail = thumb
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return
        }

        // Fallback to legacy paths for "Main"
        if activeCollection == "Main", let paths = UserDefaults.standard.stringArray(forKey: legacyStorageKey) {
            for path in paths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path) {
                    var item = ShelfItem(url: url)
                    item.thumbnail = NSWorkspace.shared.icon(forFile: path)
                    items.append(item)

                    let itemId = item.id
                    if !item.isDirectory {
                        Task {
                            if let thumb = await self.generateThumbnail(for: url) {
                                if let idx = self.items.firstIndex(where: { $0.id == itemId }) {
                                    self.items[idx].thumbnail = thumb
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
