import SwiftUI
import AppKit

public struct ActionItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let systemIcon: String
    public let shortcut: String?
    public let section: String
    public let isDestructive: Bool
    public let perform: () -> Void

    public init(
        title: String,
        systemIcon: String,
        shortcut: String? = nil,
        section: String = "Actions",
        isDestructive: Bool = false,
        perform: @escaping () -> Void
    ) {
        self.title = title
        self.systemIcon = systemIcon
        self.shortcut = shortcut
        self.section = section
        self.isDestructive = isDestructive
        self.perform = perform
    }
}

/// Raycast-style Action Panel anchored at bottom-right (image.webp, image-4.png, image-6.png)
public struct ActionPanelView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let onDismiss: () -> Void

    @FocusState private var isActionSearchFocused: Bool

    public init(viewModel: LauncherViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var allActions: [ActionItem] {
        var items: [ActionItem] = []

        // Primary Action
        if let activeCmd = viewModel.activeCommand {
            items.append(ActionItem(
                title: "Run \(activeCmd.title)",
                systemIcon: "play.fill",
                shortcut: "↩",
                section: "Primary Action",
                perform: {
                    onDismiss()
                    Task { await viewModel.executeCurrentOperation() }
                }
            ))
        } else if let selectedCmd = viewModel.selectedCommandForActions {
            items.append(ActionItem(
                title: "Open \(selectedCmd.title)",
                systemIcon: "arrow.forward.circle.fill",
                shortcut: "↩",
                section: "Primary Action",
                perform: {
                    onDismiss()
                    viewModel.selectCommand(selectedCmd)
                }
            ))

            let isFav = viewModel.preferences.isFavorite(id: selectedCmd.id)
            items.append(ActionItem(
                title: isFav ? "Remove from Favorites" : "Pin to Favorites",
                systemIcon: isFav ? "star.slash" : "star.fill",
                shortcut: "⌘D",
                section: "Tool Actions",
                perform: {
                    viewModel.preferences.toggleFavorite(id: selectedCmd.id)
                    onDismiss()
                }
            ))
        }

        // File Actions (when files are present)
        if let first = viewModel.droppedFiles.first {
            items.append(ActionItem(
                title: "Quick Look Preview",
                systemIcon: "eye",
                shortcut: "Space",
                section: "File Actions",
                perform: {
                    onDismiss()
                    QuickLookManager.shared.toggle(url: first.url)
                }
            ))

            items.append(ActionItem(
                title: "Reveal in Finder",
                systemIcon: "folder",
                shortcut: "⌘R",
                section: "File Actions",
                perform: {
                    onDismiss()
                    NSWorkspace.shared.activateFileViewerSelecting([first.url])
                }
            ))

            items.append(ActionItem(
                title: "Copy File Path",
                systemIcon: "link",
                shortcut: "⌥⌘C",
                section: "File Actions",
                perform: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(first.url.path, forType: .string)
                    viewModel.copyStatusMessage = "Path Copied"
                    onDismiss()
                }
            ))

            items.append(ActionItem(
                title: "Open With Default App",
                systemIcon: "arrow.up.forward.app",
                shortcut: "⌘O",
                section: "File Actions",
                perform: {
                    onDismiss()
                    NSWorkspace.shared.open(first.url)
                }
            ))

            items.append(ActionItem(
                title: "Remove Dropped File",
                systemIcon: "xmark.circle",
                shortcut: "⌘⌫",
                section: "File Actions",
                isDestructive: true,
                perform: {
                    viewModel.droppedFiles = []
                    onDismiss()
                }
            ))
        }

        // General
        items.append(ActionItem(
            title: "Open Settings",
            systemIcon: "gearshape",
            shortcut: "⌘,",
            section: "Application",
            perform: {
                onDismiss()
                SettingsWindowController.shared.show()
            }
        ))

        items.append(ActionItem(
            title: "Clear All / Back to Root",
            systemIcon: "arrow.counterclockwise",
            shortcut: "⎋",
            section: "Application",
            isDestructive: true,
            perform: {
                viewModel.clearAll()
                onDismiss()
            }
        ))

        return items
    }

    private var filteredActions: [ActionItem] {
        if viewModel.actionSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return allActions
        }
        let q = viewModel.actionSearchQuery.lowercased()
        return allActions.filter {
            $0.title.lowercased().contains(q) || $0.section.lowercased().contains(q)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Actions List with Grouped Sections
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    let actions = filteredActions
                    let grouped = Dictionary(grouping: actions, by: { $0.section })
                    let sections = ["Primary Action", "Tool Actions", "File Actions", "Application"].filter { grouped[$0] != nil }

                    ForEach(sections, id: \.self) { sectionName in
                        if let sectionItems = grouped[sectionName] {
                            Text(sectionName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
                                .padding(.bottom, 2)

                            ForEach(sectionItems) { item in
                                let index = actions.firstIndex(where: { $0.id == item.id }) ?? 0
                                actionRow(index: index, item: item)
                            }
                        }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 280)

            Divider().overlay(.quaternary)

            // Bottom Search Field (as seen in image.webp, image-4.png, image-6.png)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField("Search for actions...", text: $viewModel.actionSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isActionSearchFocused)

                if !viewModel.actionSearchQuery.isEmpty {
                    Button {
                        viewModel.actionSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .frame(width: 320)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.38), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isActionSearchFocused = true
            }
        }
    }

    private func actionRow(index: Int, item: ActionItem) -> some View {
        let isSelected = (index == viewModel.selectedActionIndex)

        return HStack(spacing: 8) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.isDestructive ? Color.red : (isSelected ? Color.white : Color.accentColor))
                .frame(width: 16)

            Text(item.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(item.isDestructive ? Color.red : (isSelected ? Color.white : Color.primary))

            Spacer()

            if let shortcut = item.shortcut {
                Text(shortcut)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.06)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(item.isDestructive ? Color.red.opacity(0.85) : Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedActionIndex = index
            item.perform()
        }
    }
}
