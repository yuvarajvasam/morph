import Foundation
import AppKit
import ServiceManagement

public enum OutputLocationMode: String, CaseIterable, Identifiable {
    case sameAsSource = "Same as Input File"
    case askWhereToSave = "Ask Where to Save"
    case customFolder = "Custom Output Folder"

    public var id: String { rawValue }
}

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "Follow System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { rawValue }
}

public enum LauncherSizePreset: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case comfortable = "Comfortable"
    case large = "Large"

    public var id: String { rawValue }

    public var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .compact: return (620, 420)
        case .comfortable: return (680, 460)
        case .large: return (760, 520)
        }
    }
}

public enum TextSizeMode: String, CaseIterable, Identifiable {
    case standard = "Default"
    case larger = "Larger"

    public var id: String { rawValue }
}

public enum AnimationPreference: String, CaseIterable, Identifiable {
    case system = "Follow System"
    case reducedMotion = "Reduced Motion"

    public var id: String { rawValue }
}

public enum TransparencyPreference: String, CaseIterable, Identifiable {
    case system = "Follow System"
    case reducedTransparency = "Reduced Transparency"

    public var id: String { rawValue }
}

public enum ImageOutputFormatOption: String, CaseIterable, Identifiable {
    case preserveOriginal = "Preserve Original"
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case webp = "WebP"

    public var id: String { rawValue }

    public var targetImageFormat: ImageFormat? {
        switch self {
        case .preserveOriginal: return nil
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .webp: return .webp
        }
    }
}

public enum BatchFailBehavior: String, CaseIterable, Identifiable {
    case continueOnError = "Continue with remaining files"
    case stopOnError = "Stop on first error"

    public var id: String { rawValue }
}

@MainActor
public final class PreferencesManager: ObservableObject {
    public static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    // MARK: - General Settings

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin(launchAtLogin)
        }
    }

    @Published public var showInMenuBar: Bool {
        didSet {
            defaults.set(showInMenuBar, forKey: "showInMenuBar")
        }
    }

    @Published public var globalShortcut: String {
        didSet {
            defaults.set(globalShortcut, forKey: "globalShortcut")
        }
    }

    @Published public var autoDismissOnBlur: Bool {
        didSet {
            defaults.set(autoDismissOnBlur, forKey: "autoDismissOnBlur")
        }
    }

    @Published public var playSounds: Bool {
        didSet {
            defaults.set(playSounds, forKey: "playSounds")
        }
    }

    @Published public var showNotifications: Bool {
        didSet {
            defaults.set(showNotifications, forKey: "showNotifications")
        }
    }

    // MARK: - Appearance Settings

    @Published public var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    @Published public var launcherSize: LauncherSizePreset {
        didSet {
            defaults.set(launcherSize.rawValue, forKey: "launcherSize")
        }
    }

    @Published public var textSize: TextSizeMode {
        didSet {
            defaults.set(textSize.rawValue, forKey: "textSize")
        }
    }

    @Published public var animationPreference: AnimationPreference {
        didSet {
            defaults.set(animationPreference.rawValue, forKey: "animationPreference")
        }
    }

    @Published public var transparencyPreference: TransparencyPreference {
        didSet {
            defaults.set(transparencyPreference.rawValue, forKey: "transparencyPreference")
        }
    }

    // MARK: - Image Tools Settings

    @Published public var defaultImagePreset: CompressionPreset {
        didSet {
            defaults.set(defaultImagePreset.rawValue, forKey: "defaultImagePreset")
        }
    }

    @Published public var defaultImageFormat: ImageOutputFormatOption {
        didSet {
            defaults.set(defaultImageFormat.rawValue, forKey: "defaultImageFormat")
        }
    }

    @Published public var defaultImageQuality: Double {
        didSet {
            defaults.set(defaultImageQuality, forKey: "defaultImageQuality")
        }
    }

    @Published public var preserveImageDimensions: Bool {
        didSet {
            defaults.set(preserveImageDimensions, forKey: "preserveImageDimensions")
        }
    }

    @Published public var stripImageMetadata: Bool {
        didSet {
            defaults.set(stripImageMetadata, forKey: "stripImageMetadata")
        }
    }

    @Published public var warnLossyTransparency: Bool {
        didSet {
            defaults.set(warnLossyTransparency, forKey: "warnLossyTransparency")
        }
    }

    @Published public var batchFailBehavior: BatchFailBehavior {
        didSet {
            defaults.set(batchFailBehavior.rawValue, forKey: "batchFailBehavior")
        }
    }

    // MARK: - PDF Tools Settings

    @Published public var defaultPDFPreset: CompressionPreset {
        didSet {
            defaults.set(defaultPDFPreset.rawValue, forKey: "defaultPDFPreset")
        }
    }

    @Published public var defaultPDFRasterDPI: CGFloat {
        didSet {
            defaults.set(Double(defaultPDFRasterDPI), forKey: "defaultPDFRasterDPI")
        }
    }

    @Published public var defaultPDFToImageFormat: ImageFormat {
        didSet {
            defaults.set(defaultPDFToImageFormat.rawValue, forKey: "defaultPDFToImageFormat")
        }
    }

    @Published public var defaultImageToPDFPageSize: PDFPageSize {
        didSet {
            defaults.set(defaultImageToPDFPageSize.rawValue, forKey: "defaultImageToPDFPageSize")
        }
    }

    @Published public var confirmDestructivePageRemoval: Bool {
        didSet {
            defaults.set(confirmDestructivePageRemoval, forKey: "confirmDestructivePageRemoval")
        }
    }

    @Published public var stripPDFMetadata: Bool {
        didSet {
            defaults.set(stripPDFMetadata, forKey: "stripPDFMetadata")
        }
    }

    // MARK: - Output Settings

    @Published public var outputLocationMode: OutputLocationMode {
        didSet {
            defaults.set(outputLocationMode.rawValue, forKey: "outputLocationMode")
        }
    }

    @Published public var customFolderPath: String {
        didSet {
            defaults.set(customFolderPath, forKey: "customFolderPath")
        }
    }

    @Published public var namingPrefix: String {
        didSet {
            defaults.set(namingPrefix, forKey: "namingPrefix")
        }
    }

    @Published public var namingSuffix: String {
        didSet {
            defaults.set(namingSuffix, forKey: "namingSuffix")
        }
    }

    // MARK: - Favorites & Recents (Raycast Model)

    @Published public var favoriteCommandIDs: [String] {
        didSet {
            defaults.set(favoriteCommandIDs, forKey: "favoriteCommandIDs")
        }
    }

    @Published public var recentCommandIDs: [String] {
        didSet {
            defaults.set(recentCommandIDs, forKey: "recentCommandIDs")
        }
    }

    // MARK: - Initialization

    public init() {
        // General
        if #available(macOS 13.0, *) {
            self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        } else {
            self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        }

        self.showInMenuBar = defaults.object(forKey: "showInMenuBar") != nil ? defaults.bool(forKey: "showInMenuBar") : true
        self.globalShortcut = defaults.string(forKey: "globalShortcut") ?? "⌥ Space"
        self.autoDismissOnBlur = defaults.bool(forKey: "autoDismissOnBlur")
        self.playSounds = defaults.object(forKey: "playSounds") != nil ? defaults.bool(forKey: "playSounds") : true
        self.showNotifications = defaults.object(forKey: "showNotifications") != nil ? defaults.bool(forKey: "showNotifications") : true

        // Appearance
        if let modeRaw = defaults.string(forKey: "appearanceMode"), let mode = AppearanceMode(rawValue: modeRaw) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .system
        }

        if let sizeRaw = defaults.string(forKey: "launcherSize"), let size = LauncherSizePreset(rawValue: sizeRaw) {
            self.launcherSize = size
        } else {
            self.launcherSize = .comfortable
        }

        if let textRaw = defaults.string(forKey: "textSize"), let text = TextSizeMode(rawValue: textRaw) {
            self.textSize = text
        } else {
            self.textSize = .standard
        }

        if let animRaw = defaults.string(forKey: "animationPreference"), let anim = AnimationPreference(rawValue: animRaw) {
            self.animationPreference = anim
        } else {
            self.animationPreference = .system
        }

        if let transRaw = defaults.string(forKey: "transparencyPreference"), let trans = TransparencyPreference(rawValue: transRaw) {
            self.transparencyPreference = trans
        } else {
            self.transparencyPreference = .system
        }

        // Image Tools
        if let imgPresetRaw = defaults.string(forKey: "defaultImagePreset"), let preset = CompressionPreset(rawValue: imgPresetRaw) {
            self.defaultImagePreset = preset
        } else {
            self.defaultImagePreset = .balanced
        }

        if let imgFmtRaw = defaults.string(forKey: "defaultImageFormat"), let fmt = ImageOutputFormatOption(rawValue: imgFmtRaw) {
            self.defaultImageFormat = fmt
        } else {
            self.defaultImageFormat = .preserveOriginal
        }

        self.defaultImageQuality = defaults.object(forKey: "defaultImageQuality") != nil ? defaults.double(forKey: "defaultImageQuality") : 0.80
        self.preserveImageDimensions = defaults.object(forKey: "preserveImageDimensions") != nil ? defaults.bool(forKey: "preserveImageDimensions") : true
        self.stripImageMetadata = defaults.bool(forKey: "stripImageMetadata")
        self.warnLossyTransparency = defaults.object(forKey: "warnLossyTransparency") != nil ? defaults.bool(forKey: "warnLossyTransparency") : true

        if let batchRaw = defaults.string(forKey: "batchFailBehavior"), let batch = BatchFailBehavior(rawValue: batchRaw) {
            self.batchFailBehavior = batch
        } else {
            self.batchFailBehavior = .continueOnError
        }

        // PDF Tools
        if let pdfPresetRaw = defaults.string(forKey: "defaultPDFPreset"), let preset = CompressionPreset(rawValue: pdfPresetRaw) {
            self.defaultPDFPreset = preset
        } else {
            self.defaultPDFPreset = .balanced
        }

        let storedDPI = defaults.double(forKey: "defaultPDFRasterDPI")
        self.defaultPDFRasterDPI = storedDPI > 0 ? CGFloat(storedDPI) : 150.0

        if let pdfFmtRaw = defaults.string(forKey: "defaultPDFToImageFormat"), let fmt = ImageFormat(rawValue: pdfFmtRaw) {
            self.defaultPDFToImageFormat = fmt
        } else {
            self.defaultPDFToImageFormat = .png
        }

        if let pageSizeRaw = defaults.string(forKey: "defaultImageToPDFPageSize"), let size = PDFPageSize(rawValue: pageSizeRaw) {
            self.defaultImageToPDFPageSize = size
        } else {
            self.defaultImageToPDFPageSize = .matchImage
        }

        self.confirmDestructivePageRemoval = defaults.object(forKey: "confirmDestructivePageRemoval") != nil ? defaults.bool(forKey: "confirmDestructivePageRemoval") : true
        self.stripPDFMetadata = defaults.bool(forKey: "stripPDFMetadata")

        // Output Settings
        if let locRaw = defaults.string(forKey: "outputLocationMode"), let loc = OutputLocationMode(rawValue: locRaw) {
            self.outputLocationMode = loc
        } else if let legacyRaw = defaults.string(forKey: "outputFolderMode") {
            if legacyRaw == "Desktop" || legacyRaw == "Downloads" {
                self.outputLocationMode = .customFolder
                self.customFolderPath = FileManager.default.urls(for: legacyRaw == "Desktop" ? .desktopDirectory : .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
            } else {
                self.outputLocationMode = .sameAsSource
                self.customFolderPath = ""
            }
        } else {
            self.outputLocationMode = .sameAsSource
            self.customFolderPath = ""
        }

        self.customFolderPath = defaults.string(forKey: "customFolderPath") ?? ""
        self.namingPrefix = defaults.string(forKey: "namingPrefix") ?? ""
        self.namingSuffix = defaults.string(forKey: "namingSuffix") ?? "-processed"

        // Favorites & Recents
        self.favoriteCommandIDs = defaults.stringArray(forKey: "favoriteCommandIDs") ?? [
            "image.compress",
            "image.convert",
            "pdf.merge",
            "archive.compress",
            "qr.generate"
        ]

        self.recentCommandIDs = defaults.stringArray(forKey: "recentCommandIDs") ?? [
            "image.compress",
            "image.resize",
            "pdf.merge"
        ]
    }

    // MARK: - Actions & Helpers

    public func applyAppearance() {
        let app = NSApplication.shared
        switch appearanceMode {
        case .system:
            app.appearance = nil
        case .light:
            app.appearance = NSAppearance(named: .aqua)
        case .dark:
            app.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Launch at login registration notice: \(error.localizedDescription)")
            }
        }
    }

    public var customOutputDirectoryURL: URL? {
        guard !customFolderPath.isEmpty else { return nil }
        let url = URL(fileURLWithPath: customFolderPath)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return url
        }
        return nil
    }

    public func targetOutputDirectory(for inputURL: URL) -> URL? {
        switch outputLocationMode {
        case .sameAsSource:
            return inputURL.deletingLastPathComponent()
        case .customFolder:
            return customOutputDirectoryURL ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? inputURL.deletingLastPathComponent()
        case .askWhereToSave:
            return nil
        }
    }

    public func resetToDefaults() {
        self.launchAtLogin = false
        self.showInMenuBar = true
        self.globalShortcut = "⌥ Space"
        self.autoDismissOnBlur = false
        self.playSounds = true
        self.showNotifications = true

        self.appearanceMode = .system
        self.launcherSize = .comfortable
        self.textSize = .standard
        self.animationPreference = .system
        self.transparencyPreference = .system

        self.defaultImagePreset = .balanced
        self.defaultImageFormat = .preserveOriginal
        self.defaultImageQuality = 0.80
        self.preserveImageDimensions = true
        self.stripImageMetadata = false
        self.warnLossyTransparency = true
        self.batchFailBehavior = .continueOnError

        self.defaultPDFPreset = .balanced
        self.defaultPDFRasterDPI = 150.0
        self.defaultPDFToImageFormat = .png
        self.defaultImageToPDFPageSize = .matchImage
        self.confirmDestructivePageRemoval = true
        self.stripPDFMetadata = false

        self.outputLocationMode = .sameAsSource
        self.customFolderPath = ""
        self.namingPrefix = ""
        self.namingSuffix = "-processed"

        self.favoriteCommandIDs = ["image.compress", "image.convert", "pdf.merge", "archive.compress", "qr.generate"]
        self.recentCommandIDs = ["image.compress", "image.resize", "pdf.merge"]

        applyAppearance()
    }

    // MARK: - Favorites & Recents Management

    public func isFavorite(id: String) -> Bool {
        favoriteCommandIDs.contains(id)
    }

    public func toggleFavorite(id: String) {
        if favoriteCommandIDs.contains(id) {
            favoriteCommandIDs.removeAll { $0 == id }
        } else {
            favoriteCommandIDs.append(id)
        }
    }

    public func recordRecent(id: String) {
        var recents = recentCommandIDs.filter { $0 != id }
        recents.insert(id, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        recentCommandIDs = recents
    }
}
