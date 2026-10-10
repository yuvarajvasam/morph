import SwiftUI
import AppKit

public enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case imageTools = "Image Tools"
    case pdfTools = "PDF Tools"
    case archiveTools = "Archive Tools"
    case qrTools = "QR & Barcodes"
    case output = "Output"
    case shortcuts = "Shortcuts"
    case about = "About"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .imageTools: return "photo.stack.fill"
        case .pdfTools: return "doc.text.fill"
        case .archiveTools: return "archivebox.fill"
        case .qrTools: return "qrcode"
        case .output: return "folder.fill"
        case .shortcuts: return "command"
        case .about: return "info.circle.fill"
        }
    }

    public var iconColor: Color {
        switch self {
        case .general: return .secondary
        case .appearance: return .purple
        case .imageTools: return .orange
        case .pdfTools: return .red
        case .archiveTools: return .blue
        case .qrTools: return .indigo
        case .output: return .cyan
        case .shortcuts: return .secondary
        case .about: return .secondary
        }
    }

    public var subtitle: String {
        switch self {
        case .general: return "System startup, menu bar integration, and notifications."
        case .appearance: return "Visual theme, interface density, and materials."
        case .imageTools: return "Default compression presets, formats, and metadata stripping."
        case .pdfTools: return "Document optimization, raster DPI, and safeguards."
        case .archiveTools: return "Compression formats, preservation, and extraction behavior."
        case .qrTools: return "Error correction levels, barcode encoding, and exports."
        case .output: return "Save destinations, custom folders, and collision handling."
        case .shortcuts: return "Global launcher hotkey and navigation reference."
        case .about: return "Architecture, offline guarantee, and version information."
        }
    }
}

@MainActor
public final class SettingsTabState: ObservableObject {
    @Published public var selectedTab: SettingsTab = .general
    @Published public var searchQuery: String = ""
    @Published public var showResetConfirm: Bool = false
    public init() {}
}

/// Raycast-style Settings Window (Screenshot 2026-10-10 at 9.20.14 PM, 9.20.33 PM, 9.20.54 PM, 9.21.03 PM, 9.21.19 PM)
public struct SettingsWindowView: View {
    @ObservedObject public var preferences = PreferencesManager.shared
    @ObservedObject public var tabState: SettingsTabState

    public init(tabState: SettingsTabState = SettingsTabState()) {
        self.tabState = tabState
    }

    private var filteredTabs: [SettingsTab] {
        if tabState.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return SettingsTab.allCases
        }
        let q = tabState.searchQuery.lowercased()
        return SettingsTab.allCases.filter {
            $0.rawValue.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            // LEFT SIDEBAR (Screenshot 2026-10-10 at 9.20.14 PM)
            VStack(alignment: .leading, spacing: 10) {
                // Search settings... capsule
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("Search settings...", text: $tabState.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !tabState.searchQuery.isEmpty {
                        Button {
                            tabState.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))
                .padding(.horizontal, 10)
                .padding(.top, 14)

                // Identity Header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Morph")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("v1.0.0 • Local Utilities")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)

                Divider().overlay(.quaternary)
                    .padding(.horizontal, 10)

                // Sidebar Navigation List
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        let tabs = filteredTabs

                        // Core Section
                        let coreTabs: [SettingsTab] = [.general, .appearance, .shortcuts, .output, .about].filter { tabs.contains($0) }
                        if !coreTabs.isEmpty {
                            sidebarSectionHeader("CORE")
                            ForEach(coreTabs) { tab in
                                sidebarRow(tab)
                            }
                        }

                        // Extensions Section
                        let extTabs: [SettingsTab] = [.imageTools, .pdfTools, .archiveTools, .qrTools].filter { tabs.contains($0) }
                        if !extTabs.isEmpty {
                            sidebarSectionHeader("EXTENSIONS")
                                .padding(.top, 8)
                            ForEach(extTabs) { tab in
                                sidebarRow(tab)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }

                Spacer()

                // Bottom Offline Security Badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 11))
                    Text("100% Offline & Private")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(width: 220)
            .background(.ultraThinMaterial)

            // Vertical Border Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)

            // RIGHT CONTENT PANE
            VStack(spacing: 0) {
                // Top Nav Header with < > History Pill (Screenshot 2026-10-10 at 9.20.14 PM)
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Button {
                            navigatePrevious()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)

                        Button {
                            navigateNext()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.primary.opacity(0.06)))

                    Text(tabState.selectedTab.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("Reset to Defaults") {
                        tabState.showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

                Divider().overlay(.quaternary)

                // Main Tab Body
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch tabState.selectedTab {
                        case .general:
                            generalView
                        case .appearance:
                            appearanceView
                        case .imageTools:
                            extensionHeader(tab: .imageTools)
                            imageToolsView
                        case .pdfTools:
                            extensionHeader(tab: .pdfTools)
                            pdfToolsView
                        case .archiveTools:
                            extensionHeader(tab: .archiveTools)
                            archiveToolsView
                        case .qrTools:
                            extensionHeader(tab: .qrTools)
                            qrToolsView
                        case .output:
                            outputView
                        case .shortcuts:
                            shortcutsView
                        case .about:
                            aboutView
                        }
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
        .frame(width: 780, height: 560)
        .alert("Reset All Settings?", isPresented: $tabState.showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Defaults", role: .destructive) {
                preferences.resetToDefaults()
            }
        } message: {
            Text("This will restore all Morph preferences to their factory defaults. Your files will not be affected.")
        }
    }

    // MARK: - Sidebar Components

    private func sidebarSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
    }

    private func sidebarRow(_ tab: SettingsTab) -> some View {
        let isSelected = (tabState.selectedTab == tab)
        return Button {
            tabState.selectedTab = tab
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.systemIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : tab.iconColor)
                    .frame(width: 16)

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func navigatePrevious() {
        let all = SettingsTab.allCases
        guard let idx = all.firstIndex(of: tabState.selectedTab), idx > 0 else { return }
        tabState.selectedTab = all[idx - 1]
    }

    private func navigateNext() {
        let all = SettingsTab.allCases
        guard let idx = all.firstIndex(of: tabState.selectedTab), idx < all.count - 1 else { return }
        tabState.selectedTab = all[idx + 1]
    }

    // MARK: - Extension Header (Screenshot 2026-10-10 at 9.20.54 PM, 9.21.03 PM)

    private func extensionHeader(tab: SettingsTab) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [tab.iconColor.opacity(0.85), tab.iconColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: tab.iconColor.opacity(0.35), radius: 8, x: 0, y: 4)
                Image(systemName: tab.systemIcon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(tab.rawValue)
                .font(.system(size: 18, weight: .bold))

            Text(tab.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Reusable Settings Rows

    private func settingRow<Control: View>(title: String, subtitle: String? = nil, @ViewBuilder control: () -> Control) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                control()
            }
            .padding(.vertical, 8)

            Divider().overlay(.quaternary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.top, 6)
    }

    // MARK: - Tab 1: General (Screenshot 2026-10-10 at 9.20.14 PM)

    private var generalView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Startup & Dock")

            settingRow(title: "Open at Login", subtitle: "Start Morph automatically in the background when logging in.") {
                Toggle("", isOn: $preferences.launchAtLogin)
                    .labelsHidden()
            }

            settingRow(title: "Show in Menu Bar", subtitle: "Display the Morph menu bar item for one-click status and actions.") {
                Toggle("", isOn: Binding(
                    get: { preferences.showInMenuBar },
                    set: { preferences.showInMenuBar = $0; StatusBarController.shared.updateVisibility($0) }
                ))
                .labelsHidden()
            }

            sectionTitle("Morph Hotkey")

            settingRow(title: "Global Launcher Shortcut", subtitle: "Shortcut to summon the floating Morph command bar.") {
                HStack(spacing: 6) {
                    Text(preferences.globalShortcut)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
                    Button {
                        preferences.globalShortcut = "⌥ Space"
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Reset to ⌥ Space")
                }
            }

            settingRow(title: "Auto-Dismiss on Loss of Focus", subtitle: "Close the launcher window when you click on other applications.") {
                Toggle("", isOn: $preferences.autoDismissOnBlur)
                    .labelsHidden()
            }

            sectionTitle("Feedback & Audio")

            settingRow(title: "Play Completion Sound", subtitle: "Play a subtle Glass chime when operations complete.") {
                Toggle("", isOn: $preferences.playSounds)
                    .labelsHidden()
            }

            settingRow(title: "Notification Alerts", subtitle: "Post a macOS notification banner on operation completion.") {
                Toggle("", isOn: $preferences.showNotifications)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Tab 2: Appearance (Screenshot 2026-10-10 at 9.20.14 PM)

    private var appearanceView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Theme")

            settingRow(title: "Follow System Appearance", subtitle: "Match macOS Dark and Light mode automatically.") {
                Toggle("", isOn: Binding(
                    get: { preferences.appearanceMode == .system },
                    set: { preferences.appearanceMode = $0 ? .system : .dark }
                ))
                .labelsHidden()
            }

            settingRow(title: "Theme Mode", subtitle: "Choose an explicit appearance.") {
                Picker("", selection: $preferences.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            sectionTitle("Interface Density")

            // Segmented Aa buttons matching Screenshot 2026-10-10 at 9.20.14 PM
            settingRow(title: "Interface Size", subtitle: "Adjust density and scale of text and rows.") {
                HStack(spacing: 0) {
                    ForEach(TextSizeMode.allCases) { mode in
                        aaButton(for: mode)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 6).stroke(.quaternary, lineWidth: 1))
            }

            settingRow(title: "Launcher Size Preset", subtitle: "Window dimensions for search and results.") {
                Picker("", selection: $preferences.launcherSize) {
                    ForEach(LauncherSizePreset.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }
        }
    }

    // MARK: - Tab 3: Image Tools

    private var imageToolsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Optimization Defaults")

            settingRow(title: "Default Compression Preset", subtitle: "Balanced strikes ideal image quality vs size reduction.") {
                Picker("", selection: $preferences.defaultImagePreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            settingRow(title: "Default Output Format", subtitle: "Format used when converting or exporting images.") {
                Picker("", selection: $preferences.defaultImageFormat) {
                    ForEach(ImageOutputFormatOption.allCases) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            sectionTitle("Privacy & Safety")

            settingRow(title: "Strip Image Metadata by Default", subtitle: "Removes camera EXIF, GPS location, and personal tags.") {
                Toggle("", isOn: $preferences.stripImageMetadata)
                    .labelsHidden()
            }

            settingRow(title: "Warn on Lossy Transparency", subtitle: "Alerts when converting alpha PNG to formats like JPEG.") {
                Toggle("", isOn: $preferences.warnLossyTransparency)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Tab 4: PDF Tools

    private var pdfToolsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("PDF Compression & Rasterization")

            settingRow(title: "Default PDF Compression Preset", subtitle: "Preset used for document downsampling.") {
                Picker("", selection: $preferences.defaultPDFPreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            settingRow(title: "PDF to Image DPI", subtitle: "Resolution when converting pages to PNG images.") {
                Picker("", selection: Binding(
                    get: { Int(preferences.defaultPDFRasterDPI) },
                    set: { preferences.defaultPDFRasterDPI = CGFloat($0) }
                )) {
                    Text("72 DPI (Draft)").tag(72)
                    Text("150 DPI (Standard)").tag(150)
                    Text("300 DPI (High-Res)").tag(300)
                }
                .labelsHidden()
                .frame(width: 160)
            }

            sectionTitle("Safeguards")

            settingRow(title: "Confirm Destructive Page Removal", subtitle: "Prompt before deleting pages in Page Organizer.") {
                Toggle("", isOn: $preferences.confirmDestructivePageRemoval)
                    .labelsHidden()
            }

            settingRow(title: "Strip Document Metadata", subtitle: "Clear author, creator, and title from exported PDFs.") {
                Toggle("", isOn: $preferences.stripPDFMetadata)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Tab 5: Archive Tools

    private var archiveToolsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Archive Engine Defaults")

            settingRow(title: "Preserve Resource Forks", subtitle: "Uses /usr/bin/ditto to preserve macOS metadata and extended attributes.") {
                Text("Enabled (ditto -k)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            settingRow(title: "Path Traversal Protection", subtitle: "Blocks unsafe archive relative paths containing ../ exploits.") {
                Text("Enforced")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Tab 6: QR & Barcodes

    private var qrToolsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Generation Engine")

            settingRow(title: "Default Error Correction", subtitle: "Higher error correction preserves readability if damaged.") {
                Text("Medium (15%)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            settingRow(title: "Vision Scanner Engine", subtitle: "Apple Vision VNDetectBarcodesRequest + CIDetector fallback.") {
                Text("Native Vision")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Tab 7: Output Settings

    private var outputView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Destination Folder")

            settingRow(title: "Output Location Mode", subtitle: "Where processed files are saved by default.") {
                Picker("", selection: $preferences.outputLocationMode) {
                    ForEach(OutputLocationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }

            if preferences.outputLocationMode == .customFolder {
                settingRow(title: "Custom Folder Path", subtitle: preferences.customFolderPath.isEmpty ? "No folder selected" : preferences.customFolderPath) {
                    Button("Browse...") {
                        chooseCustomFolder()
                    }
                    .buttonStyle(.bordered)
                }
            }

            sectionTitle("Filename Suffix")

            settingRow(title: "Collision Suffix", subtitle: "Appended to processed files (e.g. photo-processed.jpg)") {
                TextField("-processed", text: $preferences.namingSuffix)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
            }
        }
    }

    // MARK: - Tab 8: Shortcuts (Screenshot 2026-10-10 at 9.21.19 PM)

    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Global Shortcuts")

            settingRow(title: "Open Morph Launcher", subtitle: "Summons Morph from any application.") {
                Text("⌥ Space")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
            }

            sectionTitle("In-Launcher Navigation")

            shortcutRefRow("↑ / ↓", description: "Navigate list items or grid selection")
            shortcutRefRow("Return (↵)", description: "Open selected tool or execute primary action")
            shortcutRefRow("Escape (⎋)", description: "Back to launcher / Dismiss action panel")
            shortcutRefRow("⌘K", description: "Toggle Raycast Contextual Action Panel")
            shortcutRefRow("⌘D", description: "Pin or unpin selected tool from Favorites")
            shortcutRefRow("⌘O", description: "Open file picker / Open output file")
            shortcutRefRow("⌘R", description: "Reveal processed file in Finder")
            shortcutRefRow("⌥⌘C", description: "Copy file path to clipboard")
            shortcutRefRow("Space", description: "Quick Look preview dropped file")
        }
    }

    private func shortcutRefRow(_ key: String, description: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                Spacer()
                Text(key)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            Divider().overlay(.quaternary)
        }
    }

    // MARK: - Tab 9: About (Screenshot 2026-10-10 at 9.20.33 PM)

    private var aboutView: some View {
        VStack(spacing: 16) {
            // App Squircle Logo + Version
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color.accentColor, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Morph")
                    .font(.system(size: 22, weight: .bold))

                Text("Version 1.0.0")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("© 2026 Morph. Fast, local-first macOS utility.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)

            // Diagnostics (Screenshot 2026-10-10 at 9.20.33 PM)
            VStack(alignment: .leading, spacing: 6) {
                Text("Diagnostics")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                    Text("All checks passed")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("ImageIO • PDFKit • Vision • Ditto")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            }

            // Updates (Screenshot 2026-10-10 at 9.20.33 PM)
            VStack(alignment: .leading, spacing: 6) {
                Text("Updates")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Morph Updates")
                            .font(.system(size: 13, weight: .semibold))
                        Text("v1.0.0 (Latest)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check now") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            }

            // Links (Screenshot 2026-10-10 at 9.20.33 PM)
            VStack(alignment: .leading, spacing: 6) {
                Text("Links")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                aboutLinkRow("Website", url: "https://morph.native.macos")
                aboutLinkRow("Offline Privacy Guarantee", url: "https://morph.native.macos/privacy")
                aboutLinkRow("Keyboard Shortcuts Guide", url: "https://morph.native.macos/shortcuts")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func aboutLinkRow(_ title: String, url: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.03)))
    }

    private func chooseCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        if panel.runModal() == .OK, let url = panel.url {
            preferences.customFolderPath = url.path
        }
    }

    private func fontSize(for mode: TextSizeMode) -> CGFloat {
        switch mode {
        case .compact: return 11
        case .standard: return 13
        case .larger: return 15
        }
    }

    private func aaButton(for mode: TextSizeMode) -> some View {
        let isSelected = (preferences.textSize == mode)
        return Button {
            preferences.textSize = mode
        } label: {
            Text("Aa")
                .font(.system(size: fontSize(for: mode), weight: isSelected ? .bold : .regular))
                .frame(width: 32, height: 26)
                .background(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
