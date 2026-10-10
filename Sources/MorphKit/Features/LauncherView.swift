import SwiftUI
import UniformTypeIdentifiers

public struct LauncherView: View {
    @ObservedObject public var viewModel: LauncherViewModel
    @FocusState private var isSearchFocused: Bool

    public init(viewModel: LauncherViewModel = LauncherViewModel()) {
        self.viewModel = viewModel
    }

    private var isToolOrResultOpen: Bool {
        viewModel.activeCommand != nil || viewModel.currentResult != nil || viewModel.isShowingSettings
    }

    public var body: some View {
        VStack(spacing: 10) {
            // TOP AREA: Search Capsule OR Tool Navigation Capsule
            if isToolOrResultOpen {
                toolNavigationCapsuleView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                searchCapsuleView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                // Category Quick Discovery Pills (when in search / browse mode)
                categoryDiscoveryPillsView
            }

            // MAIN CONTENT SURFACE
            resultsSurfaceView
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isToolOrResultOpen)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.selectedCategory)
        .padding(14)
        .frame(width: viewModel.preferences.launcherSize.dimensions.width)
        .frame(minHeight: viewModel.preferences.launcherSize.dimensions.height - 40, maxHeight: viewModel.preferences.launcherSize.dimensions.height)
        .liquidGlassWindow()
        .onChange(of: isToolOrResultOpen) { _, isOpen in
            if !isOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isSearchFocused = true
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isTargetedForDrop) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay {
            if viewModel.isTargetedForDrop {
                RoundedRectangle(cornerRadius: LiquidGlass.windowRadius, style: .continuous)
                    .stroke(LiquidGlass.bridgeTint, lineWidth: 2)
                    .background(LiquidGlass.bridgeTint.opacity(0.12))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(LiquidGlass.bridgeTint)
                            Text("Drop files to inspect & process with Morph")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
            }
        }
        .overlay {
            // Raycast Contextual Action Panel (⌘K)
            if viewModel.isShowingActionPanel {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                viewModel.isShowingActionPanel = false
                            }
                        }

                    ActionPanelView(viewModel: viewModel) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            viewModel.isShowingActionPanel = false
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .overlay(alignment: .top) {
            // Transient Toast status (e.g. "Path Copied")
            if let msg = viewModel.copyStatusMessage {
                GlassPill(msg, style: .accent)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation {
                                viewModel.copyStatusMessage = nil
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Top Area: Search Capsule

    private var searchCapsuleView: some View {
        HStack(spacing: 10) {
            // Subtle Morph Identity Icon
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LiquidGlass.bridgeTint.opacity(0.18))
                    .frame(width: 24, height: 24)
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidGlass.bridgeTint)
            }

            TextField(searchPlaceholder, text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.figmaBody())
                .focused($isSearchFocused)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search (⎋)")
            }

            if !viewModel.droppedFiles.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 10))
                    Text("\(viewModel.droppedFiles.count) file\(viewModel.droppedFiles.count > 1 ? "s" : "")")
                        .font(.figmaCaption1(emphasized: true))
                        .monospacedDigit()
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(LiquidGlass.bridgeTint.opacity(0.18)))
                .foregroundStyle(LiquidGlass.bridgeTint)
            }

            GlassButton("Actions", icon: "command", shortcutBadge: "⌘K", variant: .ghost, size: .small, tooltip: "Contextual actions (⌘K)") {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    viewModel.isShowingActionPanel.toggle()
                }
            }

            GlassButton("Open", icon: "folder", shortcutBadge: "⌘O", variant: .secondary, size: .small) {
                viewModel.openFilePicker()
            }

            GlassButton("", icon: "gearshape", shortcutBadge: "⌘,", variant: .ghost, size: .small, tooltip: "Settings (⌘,)") {
                SettingsWindowController.shared.show()
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: LiquidGlass.searchFieldHeight)
        .background {
            RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                        .stroke(LiquidGlass.bridgeTint.opacity(0.24), lineWidth: 0.7)
                }
                .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
        }
    }

    // MARK: - Category Quick Discovery Pills

    private var categoryDiscoveryPillsView: some View {
        HStack(spacing: 6) {
            // "All" Pill
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    viewModel.selectedCategory = nil
                    viewModel.selectedIndex = 0
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11, weight: .semibold))
                    Text("All")
                        .font(.system(size: 12, weight: viewModel.selectedCategory == nil ? .semibold : .regular))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    if viewModel.selectedCategory == nil {
                        Capsule(style: .continuous)
                            .fill(LiquidGlass.bridgeTint.opacity(0.20))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(LiquidGlass.bridgeTint.opacity(0.50), lineWidth: 1)
                            }
                    } else {
                        Capsule(style: .continuous)
                            .fill(.quaternary)
                    }
                }
                .foregroundStyle(viewModel.selectedCategory == nil ? LiquidGlass.bridgeTint : Color.secondary)
            }
            .buttonStyle(.plain)

            // Category Pills
            ForEach(ConversionCategory.allCases) { cat in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.selectedCategory = cat
                        viewModel.selectedIndex = 0
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(cat.displayName)
                            .font(.system(size: 12, weight: viewModel.selectedCategory == cat ? .semibold : .regular))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        if viewModel.selectedCategory == cat {
                            Capsule(style: .continuous)
                                .fill(LiquidGlass.bridgeTint.opacity(0.20))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(LiquidGlass.bridgeTint.opacity(0.50), lineWidth: 1)
                                }
                        } else {
                            Capsule(style: .continuous)
                                .fill(.quaternary)
                        }
                    }
                    .foregroundStyle(viewModel.selectedCategory == cat ? LiquidGlass.bridgeTint : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Top Area: Tool Navigation Capsule

    private var toolNavigationCapsuleView: some View {
        HStack(spacing: 10) {
            GlassButton("Back", icon: "chevron.left", shortcutBadge: "⎋", variant: .secondary, size: .small) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    viewModel.goBack()
                }
            }

            if let activeCmd = viewModel.activeCommand {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LiquidGlass.bridgeTint.opacity(0.18))
                            .frame(width: 24, height: 24)
                        Image(systemName: activeCmd.systemIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LiquidGlass.bridgeTint)
                    }

                    Text(activeCmd.title)
                        .font(.figmaHeadline)
                        .foregroundStyle(.primary)

                    GlassPill(activeCmd.category.displayName, style: .accent)
                }
            } else if viewModel.currentResult != nil {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.green)
                    Text("Result Preview")
                        .font(.figmaHeadline)
                        .foregroundStyle(.primary)
                }
            } else if viewModel.isShowingSettings {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LiquidGlass.bridgeTint)
                    Text("Preferences")
                        .font(.figmaHeadline)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            if viewModel.activeCommand != nil {
                GlassButton("Actions", icon: "command", shortcutBadge: "⌘K", variant: .ghost, size: .small, tooltip: "Actions (⌘K)") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        viewModel.isShowingActionPanel.toggle()
                    }
                }

                if !viewModel.droppedFiles.isEmpty {
                    GlassButton("", icon: "eye", shortcutBadge: "Space", variant: .ghost, size: .small, tooltip: "Quick Look preview (Space)") {
                        if let first = viewModel.droppedFiles.first {
                            QuickLookManager.shared.toggle(url: first.url)
                        }
                    }

                    GlassButton("Change", icon: "folder", shortcutBadge: "⌘O", variant: .ghost, size: .small, tooltip: "Change file (⌘O)") {
                        viewModel.openFilePicker()
                    }
                } else if viewModel.activeCommand?.id != "qr.generate" && viewModel.activeCommand?.id != "barcode.generate" {
                    GlassButton("Open File...", icon: "folder", shortcutBadge: "⌘O", variant: .secondary, size: .small) {
                        viewModel.openFilePicker()
                    }
                }
            } else if viewModel.currentResult != nil {
                GlassButton("New Action", icon: "plus", shortcutBadge: "⌘N", variant: .primary, size: .small) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.clearAll()
                    }
                }
            }

            GlassButton("", icon: "gearshape", shortcutBadge: "⌘,", variant: .ghost, size: .small, tooltip: "Settings (⌘,)") {
                SettingsWindowController.shared.show()
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: LiquidGlass.searchFieldHeight)
        .background {
            RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                        .stroke(LiquidGlass.bridgeTint.opacity(0.24), lineWidth: 0.7)
                }
                .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
        }
    }

    private var searchPlaceholder: String {
        if !viewModel.droppedFiles.isEmpty {
            return "Filter actions for \(viewModel.droppedFiles.first?.filename ?? "file")..."
        }
        if let cat = viewModel.selectedCategory {
            return "Search in \(cat.displayName)..."
        }
        return "Search Morph or drop a file..."
    }

    // MARK: - Bottom Area: Results Surface

    @ViewBuilder
    private var resultsSurfaceView: some View {
        GlassCard(cornerRadius: 14) {
            VStack(spacing: 0) {
                if viewModel.isShowingSettings {
                    SettingsView(preferences: viewModel.preferences) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.isShowingSettings = false
                        }
                    }
                } else if let result = viewModel.currentResult {
                    ResultPreviewView(viewModel: viewModel, result: result)
                } else if let activeCmd = viewModel.activeCommand {
                    if activeCmd.category == .qrBarcode && (activeCmd.id == "qr.generate" || activeCmd.id == "barcode.generate") {
                        QRCodeOperationsView(viewModel: viewModel)
                    } else if !viewModel.droppedFiles.isEmpty {
                        switch activeCmd.category {
                        case .image:
                            ImageOperationsView(viewModel: viewModel)
                        case .pdf:
                            PDFOperationsView(viewModel: viewModel)
                        case .archive:
                            ArchiveOperationsView(viewModel: viewModel)
                        case .qrBarcode:
                            QRCodeOperationsView(viewModel: viewModel)
                        }
                    } else {
                        toolEmptyDropTargetView(command: activeCmd)
                    }
                } else if !viewModel.droppedFiles.isEmpty && viewModel.activeCommand == nil {
                    fileDroppedContextualView
                } else {
                    commandListView
                }

                // Persistent Footer (only when in launcher search/browse mode)
                if !isToolOrResultOpen {
                    Divider().overlay(.quaternary)
                    footerShortcutBar
                }
            }
        }
    }

    // MARK: - Tool Empty Drop Target View

    private func toolEmptyDropTargetView(command: ConversionCommand) -> some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 68, height: 68)
                Image(systemName: command.systemIcon)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(LiquidGlass.bridgeTint)
            }

            VStack(spacing: 6) {
                Text("Select a file for \(command.title)")
                    .font(.figmaTitle3(emphasized: true))
                    .foregroundStyle(.primary)

                Text(dropPromptDescription(for: command))
                    .font(.figmaCallout())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: 12) {
                GlassButton("Choose File...", icon: "folder", shortcutBadge: "⌘O", variant: .primary, size: .regular) {
                    viewModel.openFilePicker()
                }

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary, size: .regular) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.goBack()
                    }
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func dropPromptDescription(for command: ConversionCommand) -> String {
        switch command.category {
        case .image:
            return "Drop PNG, JPEG, WebP, or HEIC images here, or browse files"
        case .pdf:
            return "Drop PDF documents here, or browse files"
        case .archive:
            return "Drop an archive or files to compress / extract"
        case .qrBarcode:
            return "Drop an image containing a QR code or barcode to scan"
        }
    }

    // MARK: - File Dropped Contextual View

    private var fileDroppedContextualView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // File Information Header
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: 12) {
                    if first.category == .image {
                        ImageThumbnailView(url: first.url, maxPixelSize: 100, cornerRadius: 6)
                            .frame(width: 44, height: 44)
                    } else if first.category == .pdf {
                        PDFPageThumbnailView(url: first.url, pageIndex: 0, pageNumber: 1, onTap: {
                            QuickLookManager.shared.toggle(url: first.url)
                        })
                        .frame(width: 36, height: 46)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "archivebox.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(first.filename)
                                .font(.figmaHeadline)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                viewModel.droppedFiles = []
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Remove dropped file (⌘⌫)")
                        }

                        Text(first.summaryDescription)
                            .font(.figmaSubheadline())
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.quaternary))
                .padding(.horizontal, 12)
                .padding(.top, 10)
            }

            Text("Suggested actions for this file:")
                .font(.figmaSubheadline(emphasized: true))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            // Suggested Operations List
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                        commandRow(index: index, command: command)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    // MARK: - Command List View (Raycast Command Discovery)

    private var commandListView: some View {
        VStack(spacing: 0) {
            let commands = viewModel.filteredCommands

            if commands.isEmpty {
                ContentUnavailableView {
                    Label("No Matching Operations", systemImage: "magnifyingglass")
                        .font(.figmaTitle3(emphasized: true))
                } description: {
                    Text("No operations matched \"\(viewModel.searchQuery)\".\nTry searching for 'compress', 'resize', 'convert', 'pdf', 'zip', or 'qr'")
                        .font(.figmaCallout())
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            // When search is empty and no category is filtered, show Favorites & Recents sections!
                            if viewModel.searchQuery.isEmpty && viewModel.selectedCategory == nil && viewModel.droppedFiles.isEmpty {
                                // FAVORITES SECTION
                                if !viewModel.favoriteCommands.isEmpty {
                                    sectionHeader(title: "FAVORITES", icon: "star.fill", color: .yellow)
                                    ForEach(Array(viewModel.favoriteCommands.enumerated()), id: \.element.id) { index, cmd in
                                        commandRow(index: index, command: cmd)
                                    }
                                }

                                // RECENT TOOLS SECTION
                                if !viewModel.recentCommands.isEmpty {
                                    sectionHeader(title: "RECENT TOOLS", icon: "clock.arrow.circlepath", color: .secondary)
                                    ForEach(Array(viewModel.recentCommands.prefix(4).enumerated()), id: \.element.id) { index, cmd in
                                        let favCount = viewModel.favoriteCommands.count
                                        commandRow(index: favCount + index, command: cmd)
                                    }
                                }

                                // ALL TOOLS SECTION
                                sectionHeader(title: "ALL TOOLS", icon: "square.grid.2x2", color: .secondary)
                                ForEach(Array(commands.enumerated()), id: \.element.id) { index, cmd in
                                    commandRow(index: index, command: cmd)
                                }
                            } else {
                                // Filtered list (search query or category filter)
                                ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                                    commandRow(index: index, command: command)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.selectedIndex) { _, newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    private func commandRow(index: Int, command: ConversionCommand) -> some View {
        let isSelected = (index == viewModel.selectedIndex)
        let isFavorite = viewModel.preferences.isFavorite(id: command.id)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(LiquidGlass.bridgeAccentGradient) : AnyShapeStyle(.quaternary))
                    .frame(width: 32, height: 32)

                Image(systemName: command.systemIcon)
                    .symbolRenderingMode(isSelected ? .monochrome : .hierarchical)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(LiquidGlass.bridgeTint))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(command.title)
                        .font(.figmaHeadline)
                        .foregroundStyle(.primary)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }

                    Spacer()
                    GlassPill(command.category.displayName, style: isSelected ? .accent : .standard)
                }

                Text(command.subtitle)
                    .font(.figmaSubheadline())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if isSelected {
                Text("↩")
                    .font(.figmaCaption1(emphasized: true))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.quaternary))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LiquidGlass.bridgeTint.opacity(0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(LiquidGlass.bridgeTint.opacity(0.40), lineWidth: 1.0)
                    }
            }
        }
        .contentShape(Rectangle())
        .id(index)
        .onTapGesture {
            viewModel.selectedIndex = index
            viewModel.selectCommand(command)
        }
    }

    // MARK: - Footer Shortcut Bar

    private var footerShortcutBar: some View {
        HStack(spacing: 12) {
            shortcutBadge("↑↓", label: "Navigate")
            shortcutBadge("↩", label: "Select")
            shortcutBadge("Space", label: "Preview")
            shortcutBadge("⌘K", label: "Actions")
            shortcutBadge("⌘D", label: "Favorite")
            shortcutBadge("⌘O", label: "Browse")

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
                Text("100% Offline & Private")
                    .font(.figmaCaption1(emphasized: true))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func shortcutBadge(_ key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.figmaCaption2(emphasized: true))
                .monospacedDigit()
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.quaternary))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.figmaCaption1())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Drag & Drop Handler

    private final class DropCollector: @unchecked Sendable {
        var urls: [URL] = []
        private let lock = NSLock()
        func add(_ url: URL) {
            lock.lock()
            urls.append(url)
            lock.unlock()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        let collector = DropCollector()
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    collector.add(url)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if !collector.urls.isEmpty {
                viewModel.handleDroppedURLs(collector.urls)
            }
        }
    }
}
