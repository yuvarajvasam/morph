import SwiftUI
import AppKit
import UserNotifications
import Combine

@MainActor
public final class LauncherViewModel: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public var selectedIndex: Int = 0
    @Published public var droppedFiles: [FileItem] = []
    @Published public var selectedCategory: CommandCategory?
    @Published public var activeCommand: ConversionCommand?
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var currentResult: ConversionResult?
    @Published public var errorMessage: String?
    @Published public var isShowingSettings: Bool = false
    @Published public var isShowingActionPanel: Bool = false
    @Published public var copyStatusMessage: String?

    // Settings
    @Published public var imageSettings = ImageSettings()
    @Published public var pdfSettings = PDFSettings()
    @Published public var customOutputFilename: String = ""
    @Published public var selectedPageIndices: Set<Int> = []
    @Published public var pageReorderList: [Int] = []

    // Archive & QR States
    @Published public var archiveFormat: ArchiveFormat = .zip
    @Published public var qrContentType: QRContentType = .url
    @Published public var qrTextContent: String = "https://morph.app"
    @Published public var qrWifiSSID: String = "MyHomeWiFi"
    @Published public var qrWifiPassword: String = ""
    @Published public var qrWifiSecurity: String = "WPA"
    @Published public var qrErrorCorrection: QRErrorCorrection = .medium
    @Published public var qrPixelSize: CGFloat = 1024
    @Published public var qrExportAsPDF: Bool = false
    @Published public var barcodeContent: String = "MORPH-123456"

    // Archive UI state
    @Published public var archiveEntries: [String] = []
    @Published public var isLoadingArchiveEntries: Bool = false

    // QR UI state
    @Published public var qrLivePreviewImage: NSImage? = nil
    @Published public var qrScanResultText: String? = nil
    @Published public var isScanningQR: Bool = false

    // Action Panel UI state
    @Published public var actionSearchQuery: String = ""
    @Published public var selectedActionIndex: Int = 0

    // View UI States
    @Published public var isTargetedForDrop: Bool = false
    @Published public var exactWidth: String = "1920"
    @Published public var exactHeight: String = "1080"
    @Published public var maxWidth: String = "1920"
    @Published public var maxHeight: String = "1080"
    @Published public var resizePercentage: Double = 50.0
    @Published public var resizeTab: Int = 0
    @Published public var splitRangeText: String = "1-2"
    @Published public var splitModeTab: Int = 0
    @Published public var rotationSelection: Int = 90
    @Published public var dpiSelection: CGFloat = 150.0

    public let registry = ConversionRegistry.shared
    public let processor = FileProcessor.shared
    public let preferences = PreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.imageSettings.compressionPreset = preferences.defaultImagePreset
        self.pdfSettings.compressionPreset = preferences.defaultPDFPreset

        preferences.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    public var formattedQRPayload: String {
        switch qrContentType {
        case .url:
            return qrTextContent.trimmingCharacters(in: .whitespacesAndNewlines)
        case .text:
            return qrTextContent
        case .wifi:
            let ssid = qrWifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
            let pass = qrWifiPassword
            return "WIFI:S:\(ssid);T:\(qrWifiSecurity);P:\(pass);;"
        case .email:
            let email = qrTextContent.trimmingCharacters(in: .whitespacesAndNewlines)
            return email.hasPrefix("mailto:") ? email : "mailto:\(email)"
        case .phone:
            let phone = qrTextContent.trimmingCharacters(in: .whitespacesAndNewlines)
            return phone.hasPrefix("tel:") ? phone : "tel:\(phone)"
        case .vcard:
            return "BEGIN:VCARD\nVERSION:3.0\nFN:\(qrTextContent)\nEND:VCARD"
        }
    }

    public var selectedCommandForActions: ConversionCommand? {
        let commands = filteredCommands
        if selectedIndex >= 0 && selectedIndex < commands.count {
            return commands[selectedIndex]
        }
        return nil
    }

    public var favoriteCommands: [ConversionCommand] {
        preferences.favoriteCommandIDs.compactMap { registry.command(id: $0) }
    }

    public var recentCommands: [ConversionCommand] {
        preferences.recentCommandIDs.compactMap { registry.command(id: $0) }
    }

    public var filteredCommands: [ConversionCommand] {
        if !droppedFiles.isEmpty {
            let suggestions = registry.suggestedCommands(for: droppedFiles.map { $0.url })
            if !searchQuery.isEmpty {
                let searched = registry.search(query: searchQuery)
                return suggestions.filter { sug in searched.contains(where: { $0.id == sug.id }) }
            }
            return suggestions
        }

        let baseCommands: [ConversionCommand]
        if let category = selectedCategory {
            baseCommands = registry.allCommands.filter { $0.matches(category: category) }
        } else {
            baseCommands = registry.allCommands
        }

        if searchQuery.isEmpty {
            return baseCommands
        } else {
            let searched = registry.search(query: searchQuery)
            return baseCommands.filter { cmd in searched.contains(where: { $0.id == cmd.id }) }
        }
    }

    public var topShelfCommands: [ConversionCommand] {
        let defaultIDs = ["image.compress", "image.convert", "pdf.merge", "archive.compress", "qr.generate"]
        var list: [ConversionCommand] = []
        for cmd in recentCommands {
            if !list.contains(where: { $0.id == cmd.id }) {
                list.append(cmd)
            }
            if list.count == 5 { break }
        }
        for id in defaultIDs {
            if !list.contains(where: { $0.id == id }), let cmd = registry.command(id: id) {
                list.append(cmd)
            }
            if list.count == 5 { break }
        }
        return list
    }

    // MARK: - Navigation

    public func navigateUp() {
        let count = filteredCommands.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }

    public func navigateDown() {
        let count = filteredCommands.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }

    public func navigateLeft() {
        let count = filteredCommands.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex - 1 + count) % count
    }

    public func navigateRight() {
        let count = filteredCommands.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + 1) % count
    }

    public func navigateGridUp(columns: Int = 7) {
        let count = filteredCommands.count
        guard count > 0 else { return }
        if selectedIndex - columns >= 0 {
            selectedIndex -= columns
        } else {
            selectedIndex = (selectedIndex - 1 + count) % count
        }
    }

    public func navigateGridDown(columns: Int = 7) {
        let count = filteredCommands.count
        guard count > 0 else { return }
        if selectedIndex + columns < count {
            selectedIndex += columns
        } else {
            selectedIndex = (selectedIndex + 1) % count
        }
    }

    public func selectCurrent() {
        let commands = filteredCommands
        guard selectedIndex >= 0 && selectedIndex < commands.count else { return }
        selectCommand(commands[selectedIndex])
    }

    public func selectCommand(_ command: ConversionCommand, promptForFilesIfEmpty: Bool = true) {
        self.activeCommand = command
        self.currentResult = nil
        self.errorMessage = nil

        // Initialize PDF reorder list if needed
        if let first = droppedFiles.first, let pageCount = first.pageCount, command.id == "pdf.reorderPages" {
            self.pageReorderList = Array(0..<pageCount)
        }

        // Sync fresh defaults from PreferencesManager
        if command.category == .image {
            self.imageSettings.compressionPreset = preferences.defaultImagePreset
            if let targetFmt = preferences.defaultImageFormat.targetImageFormat {
                self.imageSettings.format = targetFmt
            }
        } else if command.category == .pdf {
            self.pdfSettings.compressionPreset = preferences.defaultPDFPreset
            self.pdfSettings.pdfToImageDPI = preferences.defaultPDFRasterDPI
            self.dpiSelection = preferences.defaultPDFRasterDPI
            self.pdfSettings.pdfToImageFormat = preferences.defaultPDFToImageFormat
            self.pdfSettings.imageToPDFPageSize = preferences.defaultImageToPDFPageSize
        } else if command.category == .archive {
            self.archiveFormat = preferences.defaultArchiveFormat
        } else if command.category == .qrBarcode {
            self.qrErrorCorrection = preferences.defaultQRErrorCorrection
            self.qrPixelSize = preferences.defaultQRPixelSize
        }

        // If command does not require input file (like QR/Barcode generator), skip file picker
        if promptForFilesIfEmpty && command.id != "qr.generate" && command.id != "barcode.generate" && droppedFiles.isEmpty {
            openFilePicker()
        }
    }

    public func goBack() {
        if isShowingActionPanel {
            isShowingActionPanel = false
        } else if isShowingSettings {
            isShowingSettings = false
        } else if currentResult != nil {
            currentResult = nil
        } else if activeCommand != nil {
            activeCommand = nil
        } else if !droppedFiles.isEmpty {
            droppedFiles = []
        } else if selectedCategory != nil {
            selectedCategory = nil
            selectedIndex = 0
        }
        errorMessage = nil
    }

    public func clearAll() {
        searchQuery = ""
        droppedFiles = []
        selectedCategory = nil
        activeCommand = nil
        currentResult = nil
        errorMessage = nil
        selectedIndex = 0
        isProcessing = false
        isShowingSettings = false
        copyStatusMessage = nil
    }

    public func convertAnother() {
        currentResult = nil
        errorMessage = nil
        isProcessing = false
        // Prompt for another file if command is set
        if activeCommand != nil {
            openFilePicker()
        }
    }

    // MARK: - File Handling

    public func handleDroppedURLs(_ urls: [URL]) {
        let inspected = processor.inspect(urls: urls)
        self.droppedFiles = inspected
        self.selectedIndex = 0
        self.errorMessage = nil

        // Initialize PDF page helpers if applicable
        if let first = inspected.first, let count = first.pageCount {
            self.pageReorderList = Array(0..<count)
            self.selectedPageIndices = []
        }
    }

    public func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = (activeCommand?.id == "archive.compress")
        panel.allowsMultipleSelection = activeCommand?.supportsMultipleFiles ?? true
        panel.title = "Select files for Morph"

        if panel.runModal() == .OK {
            handleDroppedURLs(panel.urls)
        }
    }

    // MARK: - PDF Page Reordering

    public func movePage(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < pageReorderList.count,
              destinationIndex >= 0 && destinationIndex < pageReorderList.count,
              sourceIndex != destinationIndex else { return }
        let element = pageReorderList.remove(at: sourceIndex)
        pageReorderList.insert(element, at: destinationIndex)
    }

    // MARK: - Quick Look, Clipboard & Save As

    public func toggleQuickLook() {
        if let primaryURL = currentResult?.primaryOutputURL {
            QuickLookManager.shared.toggle(url: primaryURL)
        } else if let firstFile = droppedFiles.first {
            QuickLookManager.shared.toggle(url: firstFile.url)
        }
    }

    public func copyOutputToClipboard() {
        guard let url = currentResult?.primaryOutputURL else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])

        if let image = NSImage(contentsOf: url) {
            pasteboard.writeObjects([image])
        }

        withAnimation(LiquidGlass.quickSpring) {
            copyStatusMessage = "Copied to Clipboard"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(LiquidGlass.quickSpring) {
                self?.copyStatusMessage = nil
            }
        }
    }

    public func saveOutputAs(url: URL) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = url.lastPathComponent
        savePanel.directoryURL = preferences.targetOutputDirectory(for: url)
        savePanel.title = "Save Converted File As..."

        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
                SoundEffectManager.shared.playSuccess()
                copyStatusMessage = "Saved to \(destinationURL.lastPathComponent)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.copyStatusMessage = nil
                }
            } catch {
                errorMessage = "Failed to save file: \(error.localizedDescription)"
                SoundEffectManager.shared.playError()
            }
        }
    }

    // MARK: - Execution

    public func executeCurrentOperation() async {
        await runActiveCommand()
    }

    public func runActiveCommand() async {
        guard let command = activeCommand, (!droppedFiles.isEmpty || command.id == "qr.generate" || command.id == "barcode.generate") else {
            errorMessage = "Please select an operation and at least one file."
            SoundEffectManager.shared.playError()
            return
        }

        isProcessing = true
        progress = 0.1
        errorMessage = nil

        do {
            let targetDirectory: URL?
            if preferences.outputLocationMode == .sameAsSource {
                targetDirectory = droppedFiles.first?.url.deletingLastPathComponent()
            } else if preferences.outputLocationMode == .customFolder {
                targetDirectory = preferences.customOutputDirectoryURL ?? droppedFiles.first?.url.deletingLastPathComponent()
            } else if preferences.outputLocationMode == .askWhereToSave {
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                let savePanel = NSSavePanel()
                savePanel.canCreateDirectories = true
                let defaultExt: String
                if command.id == "image.convert" {
                    defaultExt = imageSettings.format.fileExtension
                } else if command.id.hasPrefix("pdf") || command.id == "image.toPDF" {
                    defaultExt = "pdf"
                } else {
                    defaultExt = first.url.pathExtension
                }
                let baseName = (first.filename as NSString).deletingPathExtension
                let opSuffix = command.id.components(separatedBy: ".").last ?? "processed"
                savePanel.nameFieldStringValue = "\(baseName)-\(opSuffix).\(defaultExt)"
                savePanel.directoryURL = first.url.deletingLastPathComponent()
                savePanel.title = "Save \(command.title) Output As..."
                if savePanel.runModal() == .OK, let chosenURL = savePanel.url {
                    targetDirectory = chosenURL.deletingLastPathComponent()
                    customOutputFilename = chosenURL.lastPathComponent
                } else {
                    isProcessing = false
                    return
                }
            } else {
                targetDirectory = droppedFiles.first?.url.deletingLastPathComponent()
            }

            // Synchronize active parameters from user interface state
            if command.id == "image.resize" {
                switch resizeTab {
                case 0:
                    let w = Int(exactWidth) ?? 1920
                    let h = Int(exactHeight) ?? 1080
                    imageSettings.resizeMode = .exact(width: w, height: h)
                case 1:
                    let mw = Int(maxWidth) ?? 1920
                    imageSettings.resizeMode = .maxWidth(mw)
                case 2:
                    let mh = Int(maxHeight) ?? 1080
                    imageSettings.resizeMode = .maxHeight(mh)
                case 3:
                    imageSettings.resizeMode = .percentage(Int(resizePercentage))
                default:
                    break
                }
            } else if command.id == "pdf.split" {
                if splitModeTab == 0 {
                    pdfSettings.splitMode = .allPages
                } else {
                    pdfSettings.splitMode = .pageRange(splitRangeText)
                }
            } else if command.id == "pdf.toImage" {
                pdfSettings.pdfToImageDPI = dpiSelection
            } else if command.id == "pdf.rotate" {
                pdfSettings.rotationAngle = rotationSelection
            }

            switch command.id {
            case "image.compress":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.imageEngine.compress(
                    inputURL: first.url,
                    preset: imageSettings.compressionPreset,
                    destinationDirectory: targetDirectory,
                    stripMetadata: preferences.stripImageMetadata
                )
                self.currentResult = res

            case "image.convert":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.imageEngine.convert(
                    inputURL: first.url,
                    targetFormat: imageSettings.format,
                    quality: imageSettings.compressionPreset.imageQualityFactor,
                    destinationDirectory: targetDirectory,
                    stripMetadata: preferences.stripImageMetadata
                )
                self.currentResult = res

            case "image.resize":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.imageEngine.resize(
                    inputURL: first.url,
                    mode: imageSettings.resizeMode,
                    maintainAspectRatio: imageSettings.maintainAspectRatio,
                    destinationDirectory: targetDirectory,
                    stripMetadata: preferences.stripImageMetadata
                )
                self.currentResult = res

            case "image.toPDF":
                let urls = droppedFiles.map { $0.url }
                progress = 0.4
                let res = try await processor.imageEngine.imagesToPDF(
                    imageURLs: urls,
                    pageSize: pdfSettings.imageToPDFPageSize,
                    destinationDirectory: targetDirectory,
                    outputFilename: customOutputFilename.isEmpty ? "combined-images.pdf" : customOutputFilename
                )
                self.currentResult = res

            case "image.batch":
                let urls = droppedFiles.map { $0.url }
                var completedURLs: [URL] = []
                var originalTotalSize: Int64 = 0
                var outputTotalSize: Int64 = 0

                let results = await processor.imageEngine.batchProcess(urls: urls) { [weak self] url in
                    guard let self else { throw ProcessingError.cancelled }
                    return try await self.processor.imageEngine.compress(
                        inputURL: url,
                        preset: self.imageSettings.compressionPreset,
                        destinationDirectory: targetDirectory,
                        stripMetadata: self.preferences.stripImageMetadata
                    )
                } progressHandler: { [weak self] current, total, _, _ in
                    Task { @MainActor in
                        self?.progress = Double(current) / Double(total)
                    }
                }

                for r in results {
                    if case .success(let conv) = r {
                        completedURLs.append(contentsOf: conv.outputURLs)
                        originalTotalSize += conv.originalSize
                        outputTotalSize += conv.outputSize
                    } else if case .failure(let err) = r {
                        if preferences.batchFailBehavior == .stopOnError {
                            throw err
                        }
                    }
                }

                self.currentResult = ConversionResult(
                    originalURL: urls[0],
                    outputURLs: completedURLs,
                    originalSize: originalTotalSize,
                    outputSize: outputTotalSize,
                    outputFormat: "BATCH",
                    durationSeconds: 1.0
                )

            case "pdf.compress":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.pdfEngine.compress(
                    inputURL: first.url,
                    preset: pdfSettings.compressionPreset,
                    destinationDirectory: targetDirectory,
                    stripMetadata: preferences.stripPDFMetadata
                )
                self.currentResult = res

            case "pdf.merge":
                let urls = droppedFiles.map { $0.url }
                progress = 0.4
                let res = try await processor.pdfEngine.merge(
                    pdfURLs: urls,
                    outputFilename: customOutputFilename.isEmpty ? "merged-document.pdf" : customOutputFilename,
                    destinationDirectory: targetDirectory,
                    stripMetadata: preferences.stripPDFMetadata
                )
                self.currentResult = res

            case "pdf.split":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.pdfEngine.split(
                    inputURL: first.url,
                    mode: pdfSettings.splitMode,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "pdf.toImage":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.pdfEngine.pdfToImage(
                    inputURL: first.url,
                    format: pdfSettings.pdfToImageFormat,
                    dpi: pdfSettings.pdfToImageDPI,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "pdf.rotate":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.pdfEngine.rotatePages(
                    inputURL: first.url,
                    angleDegrees: rotationSelection,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "pdf.extractPages":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let indices = Array(selectedPageIndices).sorted()
                let res = try await processor.pdfEngine.extractPages(
                    inputURL: first.url,
                    pageIndices: indices,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "pdf.removePages", "pdf.managePages":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let indices = Array(selectedPageIndices)
                let res = try await processor.pdfEngine.removePages(
                    inputURL: first.url,
                    indicesToRemove: indices,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "pdf.reorderPages":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await processor.pdfEngine.reorderPages(
                    inputURL: first.url,
                    newOrderIndices: pageReorderList,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "archive.compress":
                let urls = droppedFiles.map { $0.url }
                progress = 0.4
                let res = try await ArchiveEngine.shared.createArchive(
                    sources: urls,
                    format: archiveFormat,
                    customName: customOutputFilename.isEmpty ? nil : customOutputFilename,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "archive.extract":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                progress = 0.4
                let res = try await ArchiveEngine.shared.extractArchive(
                    archiveURL: first.url,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res
                if preferences.revealInFinderOnExtract, let outURL = res.outputURLs.first {
                    revealInFinder(url: outURL)
                }

            case "archive.inspect":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                let (count, size, _) = try ArchiveEngine.shared.inspect(url: first.url)
                self.currentResult = ConversionResult(
                    originalURL: first.url,
                    outputURLs: [first.url],
                    originalSize: size,
                    outputSize: size,
                    outputFormat: "ARCHIVE",
                    durationSeconds: 0.1,
                    notes: "Archive contains \(count) files. Verified safe archive layout."
                )

            case "qr.generate":
                progress = 0.4
                let payload = formattedQRPayload
                let cg = try QRCodeEngine.shared.generateQRCode(
                    message: payload,
                    errorCorrection: qrErrorCorrection,
                    pixelSize: qrPixelSize
                )
                let name = customOutputFilename.isEmpty ? "QRCode" : customOutputFilename
                let res = try await QRCodeEngine.shared.exportCode(
                    cgImage: cg,
                    baseFilename: name,
                    asPDF: qrExportAsPDF,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "barcode.generate":
                progress = 0.4
                let cg = try QRCodeEngine.shared.generateBarcode(message: barcodeContent)
                let name = customOutputFilename.isEmpty ? "Barcode" : customOutputFilename
                let res = try await QRCodeEngine.shared.exportCode(
                    cgImage: cg,
                    baseFilename: name,
                    asPDF: qrExportAsPDF,
                    destinationDirectory: targetDirectory
                )
                self.currentResult = res

            case "qr.scan":
                guard let first = droppedFiles.first else { throw ProcessingError.emptyInput }
                let payloads = try await QRCodeEngine.shared.scanCode(url: first.url)
                let joined = payloads.isEmpty ? "No readable barcode or QR code found." : payloads.joined(separator: "\n")
                self.currentResult = ConversionResult(
                    originalURL: first.url,
                    outputURLs: [first.url],
                    originalSize: first.fileSize,
                    outputSize: first.fileSize,
                    outputFormat: "TEXT",
                    durationSeconds: 0.1,
                    notes: "Decoded text: \(joined)"
                )

            default:
                break
            }

            preferences.recordRecent(id: command.id)
            SoundEffectManager.shared.playSuccess()

            if preferences.showNotifications, Bundle.main.bundleIdentifier != nil, let res = self.currentResult {
                let content = UNMutableNotificationContent()
                content.title = "Morph — \(command.title)"
                let targetName = droppedFiles.first?.filename ?? "Generated File"
                content.body = "Processed \(targetName) successfully (\(res.formattedOutputSize))."
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                try? await UNUserNotificationCenter.current().add(request)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            SoundEffectManager.shared.playError()
        }

        isProcessing = false
        progress = 1.0
    }

    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func openFile(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
