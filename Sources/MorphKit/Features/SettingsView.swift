import SwiftUI
import AppKit

public enum SettingsSidebarTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    case fileHandling = "File Handling"
    case notifications = "Notifications"
    case about = "About"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .shortcuts: return "command"
        case .fileHandling: return "folder.fill"
        case .notifications: return "bell.fill"
        case .about: return "info.circle.fill"
        }
    }
}

@MainActor
public final class SettingsViewState: ObservableObject {
    @Published public var selectedTab: SettingsSidebarTab = .general
    @Published public var checkingUpdates: Bool = false
    @Published public var updateMessage: String? = nil
    public init() {}
}

public struct SettingsView: View {
    @ObservedObject var preferences: PreferencesManager
    var onDismiss: () -> Void

    @StateObject private var state = SettingsViewState()

    public init(preferences: PreferencesManager = PreferencesManager.shared, onDismiss: @escaping () -> Void) {
        self.preferences = preferences
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar (Screen 9)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SettingsSidebarTab.allCases) { tab in
                    let isSelected = (state.selectedTab == tab)
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            state.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 18)
                                .foregroundStyle(isSelected ? Color.white : SubtleTheme.textSecondary)

                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? Color.white : SubtleTheme.textPrimary)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SubtleTheme.accentBlue)
                            } else {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.001))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(12)
            .frame(width: 170)
            .background(SubtleTheme.bgCard.opacity(0.4))

            // Subtle vertical separator
            Rectangle()
                .fill(SubtleTheme.borderSubtle)
                .frame(width: 1)

            // MARK: - Right Detail Content Pane
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch state.selectedTab {
                    case .general:
                        generalSettingsPane
                    case .appearance:
                        appearanceSettingsPane
                    case .shortcuts:
                        shortcutsSettingsPane
                    case .fileHandling:
                        fileHandlingSettingsPane
                    case .notifications:
                        notificationsSettingsPane
                    case .about:
                        aboutSettingsPane
                    }
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - General Settings (Exact Screen 9)

    private var generalSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(spacing: 0) {
                // 1. Launch at Login
                settingRow(
                    title: "Launch at Login",
                    description: "Start Morph automatically when you log in."
                ) {
                    Toggle("", isOn: $preferences.launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }

                separator

                // 2. Default View
                settingRow(
                    title: "Default View",
                    description: "Choose the default view for the launcher."
                ) {
                    Menu {
                        Button("Grid") { preferences.defaultViewMode = "Grid" }
                        Button("Launcher") { preferences.defaultViewMode = "Launcher" }
                        Button("List") { preferences.defaultViewMode = "List" }
                    } label: {
                        HStack(spacing: 6) {
                            Text(preferences.defaultViewMode)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundStyle(SubtleTheme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                separator

                // 3. Default Category
                settingRow(
                    title: "Default Category",
                    description: "Open this category when Morph starts."
                ) {
                    Menu {
                        Button("All") { preferences.defaultCategory = "All" }
                        Button("Images") { preferences.defaultCategory = "Images" }
                        Button("PDFs") { preferences.defaultCategory = "PDFs" }
                        Button("Archives") { preferences.defaultCategory = "Archives" }
                        Button("QR & Barcodes") { preferences.defaultCategory = "QR & Barcodes" }
                    } label: {
                        HStack(spacing: 6) {
                            Text(preferences.defaultCategory)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundStyle(SubtleTheme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                separator

                // 4. Auto Dismiss
                settingRow(
                    title: "Auto Dismiss",
                    description: "Close Morph when opening a tool."
                ) {
                    Toggle("", isOn: $preferences.autoDismissOnOpenTool)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }

                separator

                // 5. Play Completion Sound
                settingRow(
                    title: "Play Completion Sound",
                    description: "Play a sound when operations complete."
                ) {
                    Toggle("", isOn: $preferences.playSounds)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }

                separator

                // 6. Check for Updates
                settingRow(
                    title: "Check for Updates",
                    description: state.updateMessage ?? "Current version 1.0.0"
                ) {
                    Button {
                        state.checkingUpdates = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            state.checkingUpdates = false
                            state.updateMessage = "Morph is up to date (1.0.0)"
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if state.checkingUpdates {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 12, height: 12)
                            }
                            Text(state.checkingUpdates ? "Checking..." : "Check Now")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(SubtleTheme.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(state.checkingUpdates)
                }
            }
        }
    }

    // MARK: - Appearance Settings

    private var appearanceSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(spacing: 0) {
                settingRow(
                    title: "Theme Mode",
                    description: "Choose interface appearance theme."
                ) {
                    Picker("", selection: $preferences.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                separator

                settingRow(
                    title: "Window Size Preset",
                    description: "Configure Morph launcher window dimensions."
                ) {
                    Picker("", selection: $preferences.launcherSize) {
                        ForEach(LauncherSizePreset.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                separator

                settingRow(
                    title: "Transparency",
                    description: "Window glass translucency behavior."
                ) {
                    Picker("", selection: $preferences.transparencyPreference) {
                        ForEach(TransparencyPreference.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
        }
    }

    // MARK: - Shortcuts Settings

    private var shortcutsSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(spacing: 0) {
                shortcutRow(name: "Toggle Morph Launcher", shortcut: "⌥ Space")
                separator
                shortcutRow(name: "Execute Primary Action", shortcut: "↵")
                separator
                shortcutRow(name: "Contextual Action Panel", shortcut: "⌘K")
                separator
                shortcutRow(name: "Choose / Open File", shortcut: "⌘O")
                separator
                shortcutRow(name: "Quick Look Preview", shortcut: "Space")
                separator
                shortcutRow(name: "Switch View Mode (Launcher / Grid / List)", shortcut: "⌘V")
                separator
                shortcutRow(name: "Preferences", shortcut: "⌘,")
                separator
                shortcutRow(name: "Back / Dismiss", shortcut: "⎋")
            }
        }
    }

    // MARK: - File Handling Settings

    private var fileHandlingSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Handling")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(spacing: 0) {
                settingRow(
                    title: "Auto Dismiss on Blur",
                    description: "Dismiss window when clicking another application."
                ) {
                    Toggle("", isOn: $preferences.autoDismissOnBlur)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }

                separator

                settingRow(
                    title: "Menu Bar Icon",
                    description: "Show Morph icon in system menu bar."
                ) {
                    Toggle("", isOn: $preferences.showInMenuBar)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }
            }
        }
    }

    // MARK: - Notifications Settings

    private var notificationsSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(spacing: 0) {
                settingRow(
                    title: "System Notifications",
                    description: "Show banner alerts when file processing completes."
                ) {
                    Toggle("", isOn: $preferences.showNotifications)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }

                separator

                settingRow(
                    title: "Audio Feedback",
                    description: "Play subtle chime when tasks complete or fail."
                ) {
                    Toggle("", isOn: $preferences.playSounds)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SubtleTheme.accentBlue))
                }
            }
        }
    }

    // MARK: - About Settings

    private var aboutSettingsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Morph")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(SubtleTheme.accentBlue)
                            .frame(width: 48, height: 48)
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Morph")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SubtleTheme.textPrimary)
                        Text("Version 1.0.0 (Build 100)")
                            .font(.system(size: 12))
                            .foregroundStyle(SubtleTheme.textSecondary)
                    }
                }

                Text("Morph is an offline-first native macOS utility for high-performance file conversion, image manipulation, PDF merging, archive creation, and QR generation.")
                    .font(.system(size: 12))
                    .foregroundStyle(SubtleTheme.textSecondary)
                    .lineSpacing(3)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.accentGreen)
                    Text("100% Offline & Private: No telemetry, no cloud transmission.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SubtleTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubtleTheme.accentGreen.opacity(0.12))
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SubtleTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Row Helpers

    private func settingRow<Content: View>(
        title: String,
        description: String,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SubtleTheme.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(SubtleTheme.textSecondary)
            }

            Spacer()

            trailing()
        }
        .padding(.vertical, 9)
    }

    private func shortcutRow(name: String, shortcut: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SubtleTheme.textPrimary)
            Spacer()
            Text(shortcut)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(SubtleTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(SubtleTheme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                        )
                )
        }
        .padding(.vertical, 7)
    }

    private var separator: some View {
        Rectangle()
            .fill(SubtleTheme.borderSubtle.opacity(0.6))
            .frame(height: 1)
    }
}

