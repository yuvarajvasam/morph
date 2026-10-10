import SwiftUI
import AppKit

public enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case imageTools = "Image Tools"
    case pdfTools = "PDF Tools"
    case output = "Output"
    case shortcuts = "Shortcuts"
    case about = "About"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .imageTools: return "photo.stack"
        case .pdfTools: return "doc.richtext"
        case .output: return "folder"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }

    public var subtitle: String {
        switch self {
        case .general: return "System startup, menu bar integration, and feedback."
        case .appearance: return "Visual theme, launcher dimensions, and motion."
        case .imageTools: return "Default optimization presets, formats, and privacy."
        case .pdfTools: return "Document compression, raster DPI, and page safeguards."
        case .output: return "Save destinations, custom folders, and collision handling."
        case .shortcuts: return "Global hotkeys and keyboard navigation reference."
        case .about: return "Architecture, offline guarantee, and version information."
        }
    }
}

@MainActor
public final class SettingsTabState: ObservableObject {
    @Published public var selectedTab: SettingsTab = .general
    @Published public var showResetConfirm: Bool = false
    public init() {}
}

public struct SettingsWindowView: View {
    @ObservedObject public var preferences = PreferencesManager.shared
    @ObservedObject public var tabState: SettingsTabState

    public init(tabState: SettingsTabState = SettingsTabState()) {
        self.tabState = tabState
    }

    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: Binding(
                get: { tabState.selectedTab },
                set: { tabState.selectedTab = $0 }
            )) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(tab.rawValue)
                            .font(.figmaBody(emphasized: tabState.selectedTab == tab))
                    } icon: {
                        Image(systemName: tab.systemIcon)
                            .foregroundStyle(tabState.selectedTab == tab ? LiquidGlass.bridgeTint : Color.secondary)
                    }
                }
                .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 11))
                    Text("100% Offline & Private")
                        .font(.figmaCaption1(emphasized: true))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
        } detail: {
            Form {
                switch tabState.selectedTab {
                case .general:
                    generalSection
                case .appearance:
                    appearanceSection
                case .imageTools:
                    imageToolsSection
                case .pdfTools:
                    pdfToolsSection
                case .output:
                    outputSection
                case .shortcuts:
                    shortcutsSection
                case .about:
                    aboutSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle(tabState.selectedTab.rawValue)
            .navigationSubtitle(tabState.selectedTab.subtitle)
        }
        .frame(minWidth: 740, minHeight: 520)
        .alert("Reset All Settings?", isPresented: $tabState.showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Defaults", role: .destructive) {
                preferences.resetToDefaults()
            }
        } message: {
            Text("This will restore all Morph preferences to their factory defaults. Your files will not be affected.")
        }
    }

    // MARK: - Section 1: General

    @ViewBuilder
    private var generalSection: some View {
        Section("System Integration") {
            Toggle(isOn: $preferences.launchAtLogin) {
                Text("Launch at Login")
                Text("Start Morph automatically in the background when you log in to macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: Binding(
                get: { preferences.showInMenuBar },
                set: { newValue in
                    preferences.showInMenuBar = newValue
                    StatusBarController.shared.updateVisibility(newValue)
                }
            )) {
                Text("Show in Menu Bar")
                Text("Display the Morph status item for one-click access and quick actions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Launcher Behavior") {
            LabeledContent {
                HStack(spacing: 6) {
                    Text("⌥ Space")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
                    Button("Reset") {
                        preferences.globalShortcut = "⌥ Space"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } label: {
                Text("Global Launcher Shortcut")
                Text("Hotkey that summons the floating command launcher from any application.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $preferences.autoDismissOnBlur) {
                Text("Auto-Dismiss on Loss of Focus")
                Text("Automatically close the floating launcher window when you click away.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Feedback & Notifications") {
            Toggle(isOn: $preferences.playSounds) {
                Text("Play Completion Sound")
                Text("Plays an Apple Glass chime whenever an image or PDF conversion finishes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $preferences.showNotifications) {
                Text("System Notification Banners")
                Text("Post a native notification alert when batch operations or multi-file exports complete.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Section 2: Appearance

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Theme & Visual Style") {
            LabeledContent {
                Picker("", selection: $preferences.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            } label: {
                Text("Appearance Mode")
                Text("Controls whether Morph adapts to macOS system appearance or enforces a specific theme.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Launcher Geometry") {
            LabeledContent {
                Picker("", selection: Binding(
                    get: { preferences.launcherSize },
                    set: { newSize in
                        preferences.launcherSize = newSize
                        FloatingPanelController.shared.applySize(newSize)
                    }
                )) {
                    ForEach(LauncherSizePreset.allCases) { preset in
                        Text("\(preset.rawValue) (\(Int(preset.dimensions.width))×\(Int(preset.dimensions.height)))").tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
            } label: {
                Text("Floating Launcher Dimensions")
                Text("Adjust the size profile of the Spotlight-inspired command center.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Accessibility & Contrast") {
            LabeledContent {
                Picker("", selection: $preferences.animationPreference) {
                    ForEach(AnimationPreference.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Motion & Transitions")
                Text("Substitute instant transitions for spring animations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LabeledContent {
                Picker("", selection: $preferences.transparencyPreference) {
                    ForEach(TransparencyPreference.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Translucency & Liquid Glass")
                Text("Use opaque solid surfaces instead of translucent materials to maximize legibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Section 3: Image Tools

    @ViewBuilder
    private var imageToolsSection: some View {
        Section("Default Optimization Preset") {
            LabeledContent {
                Picker("", selection: $preferences.defaultImagePreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            } label: {
                Text("Image Compression Preset")
                Text(preferences.defaultImagePreset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Default Format & Quality") {
            LabeledContent {
                Picker("", selection: $preferences.defaultImageFormat) {
                    ForEach(ImageOutputFormatOption.allCases) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Default Target Format")
                Text("Default container when converting non-standard graphics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LabeledContent {
                HStack {
                    Slider(value: $preferences.defaultImageQuality, in: 0.10...1.0, step: 0.05)
                        .frame(width: 160)
                    Text("\(Int(preferences.defaultImageQuality * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            } label: {
                Text("Default Lossy Quality Factor")
                Text("Applies to JPEG, WebP, and HEIC encoders. PNG conversions always preserve lossless pixel fidelity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Dimensions & Transparency") {
            Toggle(isOn: $preferences.preserveImageDimensions) {
                Text("Preserve Original Dimensions by Default")
                Text("Do not downscale pixels unless explicitly specified in the Resize tool.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $preferences.warnLossyTransparency) {
                Text("Warn Before Stripping Alpha Transparency")
                Text("Alert when converting transparent PNG or WebP images to JPEG, which fills transparency with white.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Privacy & Metadata") {
            Toggle(isOn: $preferences.stripImageMetadata) {
                Text("Strip EXIF & Camera Metadata for Privacy")
                Text("Removes camera make/model, exposure details, and GPS location coordinates from all saved outputs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LabeledContent {
                Picker("", selection: $preferences.batchFailBehavior) {
                    ForEach(BatchFailBehavior.allCases) { b in
                        Text(b.rawValue).tag(b)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 220)
            } label: {
                Text("Batch Failure Handling")
                Text("Behavior when a damaged or unsupported file is encountered during batch processing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Section 4: PDF Tools

    @ViewBuilder
    private var pdfToolsSection: some View {
        Section("Default PDF Optimization") {
            LabeledContent {
                Picker("", selection: $preferences.defaultPDFPreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            } label: {
                Text("PDF Compression Preset")
                Text(preferences.defaultPDFPreset == .light
                     ? "Optimizes document streams while preserving original image resolutions."
                     : "Downsamples embedded photos to \(Int(preferences.defaultPDFPreset.pdfTargetDPI)) DPI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("PDF to Image & Raster Defaults") {
            LabeledContent {
                Picker("", selection: $preferences.defaultPDFToImageFormat) {
                    ForEach(ImageFormat.allCases) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Default Export Format")
                Text("Default file format when converting PDF pages to raster images.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LabeledContent {
                Picker("", selection: $preferences.defaultPDFRasterDPI) {
                    Text("72 DPI (Web)").tag(CGFloat(72.0))
                    Text("150 DPI (Standard)").tag(CGFloat(150.0))
                    Text("300 DPI (Print)").tag(CGFloat(300.0))
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Target Rasterization Resolution")
                Text("Render density for page-to-image extraction.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Image to PDF Defaults") {
            LabeledContent {
                Picker("", selection: $preferences.defaultImageToPDFPageSize) {
                    ForEach(PDFPageSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            } label: {
                Text("Default Page Geometry")
                Text("Determines document dimensions when compiling pictures into a PDF.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Safety & Privacy") {
            Toggle(isOn: $preferences.confirmDestructivePageRemoval) {
                Text("Confirm Destructive Page Removal")
                Text("Require confirmation before committing deletion of pages from a document.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $preferences.stripPDFMetadata) {
                Text("Strip PDF Document Metadata")
                Text("Clears author, title, producer, and application tags from created PDF files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Section 5: Output

    @ViewBuilder
    private var outputSection: some View {
        Section("Save Destination") {
            Picker("Save Location", selection: $preferences.outputLocationMode) {
                ForEach(OutputLocationMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.inline)

            if preferences.outputLocationMode == .customFolder {
                LabeledContent("Target Folder") {
                    HStack {
                        Text(preferences.customFolderPath.isEmpty ? "None Selected" : preferences.customFolderPath)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(preferences.customFolderPath.isEmpty ? .secondary : .primary)
                        Button("Choose...") {
                            chooseCustomOutputFolder()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }

        Section("Naming & Collision Safeguards") {
            TextField("Filename Suffix", text: $preferences.namingSuffix)
            TextField("Filename Prefix (Optional)", text: $preferences.namingPrefix)

            LabeledContent {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(LiquidGlass.bridgeTint)
            } label: {
                Text("Non-Destructive Writing")
                Text("Original source files are never overwritten. Duplicate filenames are automatically appended with (1), (2), etc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chooseCustomOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Select Output Folder for Morph"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            preferences.customFolderPath = selectedURL.path
        }
    }

    // MARK: - Section 6: Shortcuts

    @ViewBuilder
    private var shortcutsSection: some View {
        Section("Global Application Hotkeys") {
            shortcutRow("⌥ Space", label: "Toggle Morph floating command launcher")
            shortcutRow("⌘ O", label: "Open file picker / Open generated result in default app")
            shortcutRow("⌘ S", label: "Save output file to custom location (Save As...)")
            shortcutRow("⌘ C", label: "Copy generated output file or image to clipboard")
            shortcutRow("⌘ R", label: "Reveal generated file in Finder")
            shortcutRow("Space", label: "Quick Look preview selected or output file")
            shortcutRow("⌘ ,", label: "Open dedicated Settings window")
            shortcutRow("↩", label: "Execute command or select highlighted option")
            shortcutRow("⎋", label: "Go back or dismiss launcher / close preview")
            shortcutRow("⌘ Q", label: "Quit Morph application")
        }
    }

    private func shortcutRow(_ key: String, label: String) -> some View {
        LabeledContent {
            Text(key)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
        } label: {
            Text(label)
                .font(.system(size: 13))
        }
    }

    // MARK: - Section 7: About

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LiquidGlass.bridgeTint)
                    .symbolEffect(.bounce, value: tabState.selectedTab)

                Text("Morph")
                    .font(.system(size: 20, weight: .bold))

                Text("Version 1.0.0 (Build 2026.1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section("Privacy Guarantee") {
            Label {
                Text("100% Offline, Local & Private\nAll image and PDF operations execute on your Mac's CPU/GPU via native ImageIO, CoreGraphics, and PDFKit. Zero network connections, zero telemetry, zero cloud dependencies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
            }
        }

        Section("Capabilities") {
            Label("Image Engine: Lossy/Lossless Compression, Format Conversion (JPEG, PNG, HEIC, WebP), Bicubic Resize, Images to PDF, Multi-Image Batch.", systemImage: "photo.stack")
                .font(.caption)
                .foregroundStyle(.secondary)

            Label("PDF Engine: Stream Optimization, Multi-Document Merge, Range Split, PDF to Image, Page Rotation (90°/180°/270°), Page Extract, Reorder, Remove.", systemImage: "doc.richtext")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section {
            Button("Reset All Settings to Defaults", role: .destructive) {
                tabState.showResetConfirm = true
            }
            .frame(maxWidth: .infinity)
        }
    }
}
