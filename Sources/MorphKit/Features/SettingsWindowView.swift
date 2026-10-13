import SwiftUI
import AppKit

public enum SettingsTab: String, CaseIterable, Identifiable {
    // Core Preferences (Matching Reference Image Sidebar)
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case navigation = "Keyboard"
    case security = "Offline Sync"
    case advanced = "Advanced"
    case about = "About"

    // Engine & Tool Extensions
    case imageTools = "Image Tools"
    case pdfTools = "PDF Tools"
    case archiveTools = "Archive Tools"
    case qrBarcode = "QR & Barcode"
    case output = "Output Destination"

    public var id: String { rawValue }

    public var isToolExtension: Bool {
        switch self {
        case .imageTools, .pdfTools, .archiveTools, .qrBarcode, .output:
            return true
        default:
            return false
        }
    }

    public var systemIcon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "macwindow"
        case .shortcuts: return "command"
        case .navigation: return "keyboard"
        case .security: return "lock.shield"
        case .advanced: return "wrench.and.screwdriver"
        case .about: return "info.circle"
        case .imageTools: return "photo.stack.fill"
        case .pdfTools: return "doc.richtext.fill"
        case .archiveTools: return "archivebox.fill"
        case .qrBarcode: return "qrcode"
        case .output: return "folder.fill"
        }
    }

    public var extensionColor: Color {
        switch self {
        case .imageTools: return Color(red: 255/255, green: 105/255, blue: 60/255)
        case .pdfTools: return Color(red: 255/255, green: 69/255, blue: 58/255)
        case .archiveTools: return Color(red: 48/255, green: 176/255, blue: 199/255)
        case .qrBarcode: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case .output: return Color(red: 255/255, green: 214/255, blue: 10/255)
        default: return Color.white.opacity(0.80)
        }
    }

    public var badgeText: String? {
        switch self {
        case .security: return "100%"
        default: return nil
        }
    }

    public var subtitle: String {
        switch self {
        case .general: return "System startup, menu bar integration, and feedback."
        case .appearance: return "Visual theme, interface size & dimensions, and window modes."
        case .shortcuts: return "Global hotkeys and keyboard cheatsheet."
        case .navigation: return "Keyboard focus, Vim navigation, and Quick Look."
        case .security: return "Offline local processing architecture & privacy."
        case .advanced: return "Worker threads, cache storage, and debugging."
        case .about: return "Architecture, offline guarantee, and version information."
        case .imageTools: return "Default optimization presets, formats, and privacy."
        case .pdfTools: return "Document compression, raster DPI, and page safeguards."
        case .archiveTools: return "Compression formats, auto-extract, and date preservation."
        case .qrBarcode: return "Error correction levels and vector export DPI."
        case .output: return "Save destinations, custom folders, and collision handling."
        }
    }
}

@MainActor
public final class SettingsTabState: ObservableObject {
    @Published public var selectedTab: SettingsTab = .general
    @Published public var showResetConfirm: Bool = false
    @Published public var sidebarSearch: String = ""
    public init() {}
}

public enum SettingsLayoutMode: Sendable {
    case sidebar
    case tabs
}

public struct SettingsWindowView: View {
    @ObservedObject public var preferences = PreferencesManager.shared
    @ObservedObject public var tabState: SettingsTabState
    public var layoutMode: SettingsLayoutMode

    public init(tabState: SettingsTabState = SettingsTabState(), layoutMode: SettingsLayoutMode = .sidebar) {
        self.tabState = tabState
        self.layoutMode = layoutMode
    }

    public var body: some View {
        HStack(spacing: 0) {
            // LEFT SIDEBAR PANE (~236pt, Matches Reference Image)
            sidebarPane
                .frame(width: 236)
                .background(Color(red: 16/255, green: 17/255, blue: 20/255).opacity(0.85))

            // RIGHT DETAIL SETTINGS CONTENT
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 22/255, green: 23/255, blue: 27/255).opacity(0.92))
        }
        .frame(width: 860, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        }
        .alert("Reset All Settings?", isPresented: $tabState.showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Defaults", role: .destructive) {
                preferences.resetToDefaults()
            }
        } message: {
            Text("This will restore all Morph preferences to their factory defaults. Your files and outputs will not be affected.")
        }
    }

    // MARK: - Left Sidebar Pane

    private var sidebarPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Window Traffic Light Controls (Top-Left, Native-style)
            HStack(spacing: 8) {
                Button {
                    SettingsWindowController.shared.hide()
                } label: {
                    Circle()
                        .fill(Color(red: 255/255, green: 95/255, blue: 87/255))
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)

                Button {
                    NSApp.keyWindow?.miniaturize(nil)
                } label: {
                    Circle()
                        .fill(Color(red: 254/255, green: 188/255, blue: 46/255))
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)

                // Zoom Button (Green - Disabled, window is fixed-size and cannot be maximized)
                Circle()
                    .fill(Color(red: 40/255, green: 200/255, blue: 64/255).opacity(0.40))
                    .frame(width: 12, height: 12)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Search settings... Field (Matching Reference Image)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.40))

                TextField("Search settings...", text: $tabState.sidebarSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.06)))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
            .padding(.horizontal, 14)

            // User / Account Card (Matching Reference Image)
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 25/255, green: 35/255, blue: 48/255), Color.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        }

                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LiquidGlass.brandAccent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(NSFullUserName().isEmpty ? "Yuvaraj Vasam" : NSFullUserName())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text("Account")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.40))
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)

            // Sidebar Tabs ScrollView (Grouped by Core Settings and Tool Extensions)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 1) {
                    // Group 1: Core App Preferences
                    ForEach(filteredCoreTabs) { tab in
                        sidebarItem(tab: tab)
                    }

                    // Subtle Group Spacing (No harsh dividing line)
                    Color.clear
                        .frame(height: 8)

                    // Group 2: Engines & Tools
                    ForEach(filteredToolTabs) { tab in
                        sidebarItem(tab: tab)
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            // Bottom Offline Privacy Guarantee
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Text("100% Offline • Local Engine")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    private var filteredCoreTabs: [SettingsTab] {
        let core = SettingsTab.allCases.filter { !$0.isToolExtension }
        guard !tabState.sidebarSearch.isEmpty else { return core }
        return core.filter {
            $0.rawValue.localizedCaseInsensitiveContains(tabState.sidebarSearch) ||
            $0.subtitle.localizedCaseInsensitiveContains(tabState.sidebarSearch)
        }
    }

    private var filteredToolTabs: [SettingsTab] {
        let tools = SettingsTab.allCases.filter { $0.isToolExtension }
        guard !tabState.sidebarSearch.isEmpty else { return tools }
        return tools.filter {
            $0.rawValue.localizedCaseInsensitiveContains(tabState.sidebarSearch) ||
            $0.subtitle.localizedCaseInsensitiveContains(tabState.sidebarSearch)
        }
    }

    private func sidebarItem(tab: SettingsTab) -> some View {
        let isSelected = (tabState.selectedTab == tab)

        return Button {
            withAnimation(LiquidGlass.quickSpring) {
                tabState.selectedTab = tab
            }
        } label: {
            HStack(spacing: 9) {
                if tab.isToolExtension {
                    // Colored icon container matching Raycast extension items
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(tab.extensionColor)
                            .frame(width: 18, height: 18)
                        Image(systemName: tab.systemIcon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                } else {
                    Image(systemName: tab.systemIcon)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.65))
                        .frame(width: 18)
                }

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.75))

                Spacer()

                if let badge = tab.badgeText {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.blue.opacity(0.35)))
                        .foregroundStyle(Color.cyan)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Right Detail Content Pane

    private var detailPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Navigation History (< and > buttons matching reference image)
            HStack(spacing: 12) {
                HStack(spacing: 2) {
                    Button {
                        navigateTab(forward: false)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .frame(width: 26, height: 24)
                    }
                    .buttonStyle(.plain)

                    Button {
                        navigateTab(forward: true)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .frame(width: 26, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 10)


            // Detail Content ScrollView
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch tabState.selectedTab {
                    case .general:
                        generalDetailView
                    case .appearance:
                        appearanceDetailView
                    case .shortcuts:
                        shortcutsDetailView
                    case .navigation:
                        navigationDetailView
                    case .security:
                        securityDetailView
                    case .advanced:
                        advancedDetailView
                    case .about:
                        aboutDetailView
                    case .imageTools:
                        imageToolsDetailView
                    case .pdfTools:
                        pdfToolsDetailView
                    case .archiveTools:
                        archiveToolsDetailView
                    case .qrBarcode:
                        qrBarcodeDetailView
                    case .output:
                        outputDetailView
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
            }
        }
    }

    private func navigateTab(forward: Bool) {
        let all = SettingsTab.allCases
        guard let idx = all.firstIndex(of: tabState.selectedTab) else { return }
        let nextIdx = forward ? min(all.count - 1, idx + 1) : max(0, idx - 1)
        withAnimation(LiquidGlass.quickSpring) {
            tabState.selectedTab = all[nextIdx]
        }
    }

    // MARK: - Section 1: General (Matches Reference Image Exactly)

    private var generalDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // System startup rows
            settingRow(title: "Open at Login") {
                Toggle("", isOn: $preferences.launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Show In Menu Bar") {
                Toggle("", isOn: Binding(
                    get: { preferences.showInMenuBar },
                    set: { newValue in
                        preferences.showInMenuBar = newValue
                        StatusBarController.shared.updateVisibility(newValue)
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Morph Hotkey", subtitle: "System-wide shortcut to activate Morph.") {
                HStack(spacing: 8) {
                    Button("Replace Spotlight") {
                        preferences.globalShortcut = "⌘ Space"
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(Color.white.opacity(0.85))

                    HStack(spacing: 4) {
                        Button {
                            preferences.globalShortcut = preferences.globalShortcut.contains("⌘") ? "⌥ Space" : "⌘ Space"
                        } label: {
                            KeycapBadge(preferences.globalShortcut.contains("⌘") ? "⌘" : "⌥", fontSize: 12, minDimension: 22)
                        }
                        .buttonStyle(.plain)

                        Button {
                            preferences.globalShortcut = preferences.globalShortcut.contains("⌘") ? "⌘ Space" : "⌥ Space"
                        } label: {
                            KeycapBadge("Space", fontSize: 11, minDimension: 22)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        preferences.globalShortcut = "⌥ Space"
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Reset hotkey to default (⌥ Space)")
                }
            }

            // Appearance Sub-section within General (matching reference image!)
            sectionHeader("Appearance")

            settingRow(title: "Follow System Appearance") {
                Toggle("", isOn: Binding(
                    get: { preferences.appearanceMode == .system },
                    set: { isSystem in
                        preferences.appearanceMode = isSystem ? .system : .dark
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Theme") {
                Menu {
                    Button("Morph Dark (Obsidian)") { preferences.appearanceMode = .dark }
                    Button("Follow System") { preferences.appearanceMode = .system }
                    Button("Light Glass") { preferences.appearanceMode = .light }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11))
                        Text(preferences.appearanceMode == .dark ? "Morph Dark" : preferences.appearanceMode.rawValue)
                            .font(.system(size: 12))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(Color.white)
                }
                .menuStyle(.borderlessButton)
            }

            settingRow(title: "Theme Studio", subtitle: "Edit or customize themes for Morph") {
                Button("Customize") {
                    tabState.selectedTab = .appearance
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.08)))
                .foregroundStyle(Color.white.opacity(0.85))
            }

            interfaceSizeAndDimensionsRow

            // Window Mode Visual Cards (Exact match to reference image)
            VStack(alignment: .leading, spacing: 8) {
                Text("Window Mode")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white)

                Text("Choose your preferred mode when opening Morph")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))

                HStack(spacing: 16) {
                    // Visual Card 1: Compact Mode (Blue fluid wave)
                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            preferences.viewMode = .list
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 30/255, green: 40/255, blue: 110/255),
                                                Color(red: 20/255, green: 30/255, blue: 70/255),
                                                Color(red: 10/255, green: 15/255, blue: 40/255)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 168, height: 96)
                                    .overlay {
                                        // Miniature Compact Search Bar in Center
                                        Capsule()
                                            .fill(Color.black.opacity(0.65))
                                            .frame(width: 90, height: 14)
                                            .overlay {
                                                Capsule()
                                                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                                                Circle()
                                                    .fill(Color.white.opacity(0.40))
                                                    .frame(width: 4, height: 4)
                                            }
                                    }

                                if preferences.viewMode == .list {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.90), lineWidth: 1.5)
                                }
                            }

                            Text("Compact")
                                .font(.system(size: 11, weight: preferences.viewMode == .list ? .semibold : .regular))
                                .foregroundStyle(preferences.viewMode == .list ? Color.white : Color.white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(preferences.viewMode == .list ? 0.16 : 0.05)))
                        }
                    }
                    .buttonStyle(.plain)

                    // Visual Card 2: Expanded Mode (Dark slate smoky window)
                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            preferences.viewMode = .grid
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 45/255, green: 48/255, blue: 54/255),
                                                Color(red: 28/255, green: 30/255, blue: 34/255),
                                                Color(red: 18/255, green: 20/255, blue: 22/255)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 168, height: 96)
                                    .overlay {
                                        // Miniature Expanded Window Frame with Tiles
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.black.opacity(0.55))
                                            .frame(width: 120, height: 68)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                                                VStack(spacing: 4) {
                                                    Capsule()
                                                        .fill(Color.white.opacity(0.25))
                                                        .frame(width: 60, height: 4)
                                                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(8), spacing: 3), count: 4), spacing: 3) {
                                                        ForEach(0..<8) { _ in
                                                            RoundedRectangle(cornerRadius: 1.5)
                                                                .fill(Color.white.opacity(0.30))
                                                                .frame(width: 8, height: 8)
                                                        }
                                                    }
                                                }
                                            }
                                    }

                                if preferences.viewMode == .grid {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.90), lineWidth: 1.5)
                                }
                            }

                            Text("Expanded")
                                .font(.system(size: 11, weight: preferences.viewMode == .grid ? .semibold : .regular))
                                .foregroundStyle(preferences.viewMode == .grid ? Color.white : Color.white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(preferences.viewMode == .grid ? 0.16 : 0.05)))
                        }
                    }
                    .buttonStyle(.plain)

                    // Visual Card 3: Columns Mode (Multi-column browser)
                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            preferences.viewMode = .columns
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 35/255, green: 40/255, blue: 50/255),
                                                Color(red: 22/255, green: 26/255, blue: 32/255),
                                                Color(red: 14/255, green: 16/255, blue: 20/255)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 168, height: 96)
                                    .overlay {
                                        // Miniature 3-column frame
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.black.opacity(0.55))
                                            .frame(width: 120, height: 68)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                                                HStack(spacing: 0) {
                                                    // Col 1
                                                    VStack(spacing: 3) {
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.40)).frame(width: 24, height: 4)
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.25)).frame(width: 24, height: 4)
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.25)).frame(width: 24, height: 4)
                                                    }
                                                    .frame(maxWidth: .infinity)

                                                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)

                                                    // Col 2
                                                    VStack(spacing: 3) {
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.30)).frame(width: 28, height: 4)
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.50)).frame(width: 28, height: 4)
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.30)).frame(width: 28, height: 4)
                                                    }
                                                    .frame(maxWidth: .infinity)

                                                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1)

                                                    // Col 3
                                                    VStack(spacing: 3) {
                                                        RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.40)).frame(width: 14, height: 14)
                                                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.20)).frame(width: 22, height: 3)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                }
                                                .padding(4)
                                            }
                                    }

                                if preferences.viewMode == .columns {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.90), lineWidth: 1.5)
                                }
                            }

                            Text("Columns")
                                .font(.system(size: 11, weight: preferences.viewMode == .columns ? .semibold : .regular))
                                .foregroundStyle(preferences.viewMode == .columns ? Color.white : Color.white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(preferences.viewMode == .columns ? 0.16 : 0.05)))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.top, 6)
        }
    }

    private var interfaceSizeAndDimensionsRow: some View {
        settingRow(title: "Interface Size & Launcher Dimensions", subtitle: "Unified scale and window dimensions for the floating launcher.") {
            HStack(spacing: 6) {
                ForEach(LauncherSizePreset.allCases) { preset in
                    let isSelected = (preferences.launcherSize == preset)
                    let dims = preset.dimensions
                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            preferences.launcherSize = preset
                            FloatingPanelController.shared.applySize(preset)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Aa")
                                .font(.system(size: preset == .compact ? 11 : (preset == .comfortable ? 13 : 15), weight: isSelected ? .bold : .medium))
                            Text(preset.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                            Text("\(Int(dims.width))×\(Int(dims.height))")
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.white.opacity(0.70) : Color.white.opacity(0.40))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(isSelected ? 0.16 : 0.05))
                                .overlay {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(LiquidGlass.brandAccent.opacity(0.50), lineWidth: 1)
                                    }
                                }
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.70))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Section 2: Appearance Detail View

    private var appearanceDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Window & Theme Customization")

            settingRow(title: "Follow System Appearance", subtitle: "Adapt dynamically to macOS Light or Dark appearance.") {
                Toggle("", isOn: Binding(
                    get: { preferences.appearanceMode == .system },
                    set: { isSystem in preferences.appearanceMode = isSystem ? .system : .dark }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Active Color Theme", subtitle: "Deep obsidian slate with Liquid Glass specular highlights.") {
                Picker("", selection: $preferences.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)
            }

            interfaceSizeAndDimensionsRow

            settingRow(title: "Specular Edge Highlight", subtitle: "1.0pt subtle continuous outer glow on window frames.") {
                Toggle("", isOn: $preferences.showSpecularHighlight)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }
        }
    }

    // MARK: - Section 3: Shortcuts Matrix

    private var shortcutsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Keyboard Shortcuts")

            VStack(spacing: 4) {
                shortcutRow(keys: "⌥ Space", action: "Toggle Morph Command Launcher", scope: "System-Wide")
                shortcutRow(keys: "↑ / ↓", action: "Navigate Tools and History", scope: "Launcher")
                shortcutRow(keys: "← / →", action: "Navigate Grid Tiles", scope: "Grid Mode")
                shortcutRow(keys: "↩", action: "Execute Tool or Select Operation", scope: "Everywhere")
                shortcutRow(keys: "Space", action: "Quick Look Preview", scope: "Result & Drop")
                shortcutRow(keys: "⌘K", action: "Contextual Action Palette", scope: "Everywhere")
                shortcutRow(keys: "⌘O", action: "Browse Files / Open Result", scope: "Everywhere")
                shortcutRow(keys: "⌘,", action: "Morph Preferences Window", scope: "Everywhere")
                shortcutRow(keys: "⎋", action: "Go Back / Dismiss Launcher", scope: "Everywhere")
            }
        }
    }

    private func shortcutRow(keys: String, action: String, scope: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 12))
                .foregroundStyle(Color.white)

            Spacer()

            Text(scope)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.40))

            ShortcutKeycapView(keys, spacing: 3, fontSize: 10, minDimension: 18)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Section 4: Keyboard Navigation

    private var navigationDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Keyboard Navigation Behavior")

            settingRow(title: "Spacebar Quick Look", subtitle: "Preview selected input images and PDFs in Quick Look overlay.") {
                Toggle("", isOn: $preferences.spacebarQuickLookEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Double-Escape Clearance", subtitle: "Press Escape once to go back, twice to close Morph.") {
                Toggle("", isOn: $preferences.doubleEscapeClearanceEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }
        }
    }

    // MARK: - Section 5: Security & Offline Sync

    private var securityDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Offline Architecture")

            settingRow(title: "Local Execution Guarantee", subtitle: "All operations execute on local Apple Silicon / Intel cores. Zero telemetry.") {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.green)
                    .font(.system(size: 16))
            }

            settingRow(title: "Strip Camera EXIF & GPS", subtitle: "Remove location data and hardware identifiers automatically.") {
                Toggle("", isOn: $preferences.stripImageMetadata)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Warn Lossy Transparency", subtitle: "Alert when converting transparent PNGs to JPEG.") {
                Toggle("", isOn: $preferences.warnLossyTransparency)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }
        }
    }

    // MARK: - Section 6: Advanced

    private var advancedDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Advanced Engine Parameters")

            settingRow(title: "Auto-Dismiss on Loss of Focus", subtitle: "Close the launcher automatically when clicking outside.") {
                Toggle("", isOn: $preferences.autoDismissOnBlur)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Play Completion Sounds", subtitle: "Play authentic glass chime on task finish.") {
                Toggle("", isOn: $preferences.playSounds)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }

            settingRow(title: "Clear Intermediate Cache", subtitle: "Clean up all scratch files and staging buffers.") {
                Button("Clean Cache") {
                    FileSafetyService.shared.cleanupTemporaryFiles()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08)))
                .foregroundStyle(Color.white)
            }

            Spacer().frame(height: 4)

            Button("Reset All Preferences to Defaults...") {
                tabState.showResetConfirm = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.red.opacity(0.85))
        }
    }

    // MARK: - Section 7: About

    private var aboutDetailView: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader("About Morph")

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LiquidGlass.brandAccentGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Morph 1.0")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("Native macOS Liquid Glass Utility")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
            }

            settingRow(title: "Offline & Privacy Architecture", subtitle: "Zero remote APIs, zero analytics, zero external network requests.") {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.green)
                    .font(.system(size: 16))
            }

            settingRow(title: "Core Engines", subtitle: "Apple ImageIO, CoreGraphics, PDFKit, AppKit, and SwiftUI.") {
                Text("Native Swift 6")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.60))
            }
        }
    }

    // MARK: - Extension 1: Image Tools

    private var imageToolsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Image Engine Defaults")

            settingRow(title: "Default Optimization Preset", subtitle: "Standard compression level for image operations.") {
                Picker("", selection: $preferences.defaultImagePreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)
            }

            settingRow(title: "Default Output Format", subtitle: "Format chosen when converting without specific override.") {
                Picker("", selection: $preferences.defaultImageFormat) {
                    ForEach(ImageOutputFormatOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
            }
        }
    }

    // MARK: - Extension 2: PDF Tools

    private var pdfToolsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("PDF Engine Defaults")

            settingRow(title: "Default PDF Compression", subtitle: "Raster downsampling and PDF stream compression strength.") {
                Picker("", selection: $preferences.defaultPDFPreset) {
                    ForEach(CompressionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)
            }

            settingRow(title: "Raster Rendering Resolution", subtitle: "DPI for converting PDF pages to PNG/JPEG images.") {
                Picker("", selection: $preferences.defaultPDFRasterDPI) {
                    Text("72 DPI (Screen)").tag(CGFloat(72.0))
                    Text("144 DPI (Balanced)").tag(CGFloat(144.0))
                    Text("200 DPI (Print)").tag(CGFloat(200.0))
                    Text("300 DPI (High-Res)").tag(CGFloat(300.0))
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
            }
        }
    }

    // MARK: - Extension 3: Archive Tools

    private var archiveToolsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Archive Engine Defaults")

            settingRow(title: "Default Format", subtitle: "Standard format when compressing folder or multi-file archives.") {
                Picker("", selection: $preferences.defaultArchiveFormat) {
                    ForEach(ArchiveFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)
            }

            settingRow(title: "Reveal in Finder on Extract", subtitle: "Automatically highlight newly extracted directories.") {
                Toggle("", isOn: $preferences.revealInFinderOnExtract)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(LiquidGlass.brandAccent)
            }
        }
    }

    // MARK: - Extension 4: QR & Barcode

    private var qrBarcodeDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("QR & Barcode Engine Defaults")

            settingRow(title: "Error Correction Level", subtitle: "Redundancy percentage to allow scanning of damaged codes.") {
                Picker("", selection: $preferences.defaultQRErrorCorrection) {
                    ForEach(QRErrorCorrection.allCases) { ec in
                        Text(ec.rawValue).tag(ec)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
            }

            settingRow(title: "High-DPI Output Scaling", subtitle: "Resolution multiplier for crisp vector export.") {
                Picker("", selection: $preferences.defaultQRPixelSize) {
                    Text("2x (512×512 pt)").tag(CGFloat(512.0))
                    Text("4x (1024×1024 pt)").tag(CGFloat(1024.0))
                    Text("8x (2048×2048 pt)").tag(CGFloat(2048.0))
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
            }
        }
    }

    // MARK: - Extension 5: Output Destination

    private var outputDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Destination & Collision Policy")

            settingRow(title: "Output Location", subtitle: "Where transformed files are saved by default.") {
                Picker("", selection: $preferences.outputLocationMode) {
                    ForEach(OutputLocationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }

            if preferences.outputLocationMode == .customFolder {
                settingRow(title: "Custom Folder Path", subtitle: preferences.customFolderPath.isEmpty ? "No folder chosen yet" : preferences.customFolderPath) {
                    Button("Select Folder...") {
                        selectCustomFolder()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08)))
                    .foregroundStyle(Color.white)
                }
            }

            settingRow(title: "Safe Collision Prevention", subtitle: "Never overwrites original files; automatically appends (1), (2).") {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.system(size: 16))
            }
        }
    }

    // MARK: - Shared UI Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.top, 6)
    }

    private func settingRow<Control: View>(title: String, subtitle: String? = nil, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }

            Spacer()

            control()
        }
        .padding(.vertical, 8)
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Folder"
        if panel.runModal() == .OK, let url = panel.url {
            preferences.customFolderPath = url.path
        }
    }
}
