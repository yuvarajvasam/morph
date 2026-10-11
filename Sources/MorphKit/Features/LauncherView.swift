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
        VStack(spacing: 0) {
            // LAYER A: INTEGRATED TOP HEADER (Search Bar or Tool Navigation)
            if isToolOrResultOpen {
                integratedToolNavigationHeader
            } else {
                integratedSearchBarHeader
            }

            Divider()
                .overlay(Color.white.opacity(0.06))

            // LAYER B: MAIN CONTENT AREA
            contentAreaView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // LAYER C: SIMPLIFIED PERSISTENT FOOTER BAR (only in discovery mode)
            if !isToolOrResultOpen {
                Divider()
                    .overlay(Color.white.opacity(0.06))
                footerShortcutBar
            }
        }
        .frame(width: viewModel.preferences.launcherSize.dimensions.width,
               height: viewModel.preferences.launcherSize.dimensions.height)
        .liquidGlassSurface(radius: 28)
        .animation(LiquidGlass.standardSpring, value: isToolOrResultOpen)
        .animation(LiquidGlass.quickSpring, value: viewModel.selectedCategory)
        .animation(LiquidGlass.quickSpring, value: viewModel.preferences.viewMode)
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
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(LiquidGlass.brandAccent, lineWidth: 2.5)
                    .background(LiquidGlass.brandAccent.opacity(0.12))
                    .overlay {
                        VStack(spacing: LiquidGlass.spaceSM) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(LiquidGlass.brandAccent)
                            Text("Drop files to inspect & process with Morph")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .overlay {
            // Raycast Contextual Action Panel (⌘K)
            if viewModel.isShowingActionPanel {
                ZStack {
                    Color.black.opacity(0.40)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(LiquidGlass.quickSpring) {
                                viewModel.isShowingActionPanel = false
                            }
                        }

                    ActionPanelView(viewModel: viewModel) {
                        withAnimation(LiquidGlass.quickSpring) {
                            viewModel.isShowingActionPanel = false
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .overlay(alignment: .top) {
            // Transient Toast status (e.g. "Path Copied")
            if let msg = viewModel.copyStatusMessage {
                GlassPill(msg, style: .accent)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(LiquidGlass.quickSpring) {
                                viewModel.copyStatusMessage = nil
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Integrated Search Bar Header (Clean & Simplified)

    private var integratedSearchBarHeader: some View {
        HStack(spacing: 12) {
            // Left Glyph: Curated Stylized Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 24, height: 24)

                Image(systemName: "circle.grid.2x2.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.75))
            }

            // Search Text Field
            TextField(searchPlaceholder, text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white)
                .focused($isSearchFocused)

            // Clear Button
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
                .buttonStyle(.plain)
                .help("Clear search (⎋)")
            }

            // Dropped File Badge
            if !viewModel.droppedFiles.isEmpty {
                GlassPill("\(viewModel.droppedFiles.count) file\(viewModel.droppedFiles.count > 1 ? "s" : "")", icon: "paperclip", style: .accent)
            }

            // Ellipsis Menu (...)
            Menu {
                Section("View content as") {
                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            viewModel.preferences.viewMode = .grid
                        }
                    } label: {
                        HStack {
                            Text("Grid")
                            if viewModel.preferences.viewMode == .grid {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button {
                        withAnimation(LiquidGlass.quickSpring) {
                            viewModel.preferences.viewMode = .list
                        }
                    } label: {
                        HStack {
                            Text("List")
                            if viewModel.preferences.viewMode == .list {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    withAnimation(LiquidGlass.quickSpring) {
                        viewModel.isShowingActionPanel = true
                    }
                } label: {
                    Label("Actions Palette (⌘K)", systemImage: "command")
                }

                Button {
                    viewModel.openFilePicker()
                } label: {
                    Label("Open Files... (⌘O)", systemImage: "folder")
                }

                Button {
                    SettingsWindowController.shared.show()
                } label: {
                    Label("Preferences... (⌘,)", systemImage: "gearshape")
                }

                if !viewModel.droppedFiles.isEmpty || viewModel.activeCommand != nil || !viewModel.searchQuery.isEmpty {
                    Divider()
                    Button(role: .destructive) {
                        withAnimation(LiquidGlass.standardSpring) {
                            viewModel.clearAll()
                        }
                    } label: {
                        Label("Clear All (⎋)", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("View options (Grid/List) & settings")
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
    }

    // MARK: - Integrated Tool Navigation Header (Simplified & Uncluttered)

    private var integratedToolNavigationHeader: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(LiquidGlass.standardSpring) {
                    viewModel.goBack()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.90))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)

            if let activeCmd = viewModel.activeCommand {
                HStack(spacing: 8) {
                    ToolSquircleIcon(command: activeCmd, size: 24, cornerRadius: 6)

                    Text(activeCmd.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            } else if viewModel.currentResult != nil {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green)
                    Text("Result Preview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            } else if viewModel.isShowingSettings {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(LiquidGlass.brandAccent)
                    Text("Preferences")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }

            Spacer()

            if viewModel.activeCommand != nil {
                GlassButton("Actions", icon: "command", shortcutBadge: "⌘K", variant: .ghost, size: .small, tooltip: "Actions (⌘K)") {
                    withAnimation(LiquidGlass.quickSpring) {
                        viewModel.isShowingActionPanel.toggle()
                    }
                }

                if !viewModel.droppedFiles.isEmpty {
                    GlassButton("Change", icon: "folder", shortcutBadge: "⌘O", variant: .ghost, size: .small, tooltip: "Change file (⌘O)") {
                        viewModel.openFilePicker()
                    }
                }
            } else if viewModel.currentResult != nil {
                GlassButton("New", icon: "plus", shortcutBadge: "⌘N", variant: .primary, size: .small) {
                    withAnimation(LiquidGlass.standardSpring) {
                        viewModel.clearAll()
                    }
                }
            }

            // Ellipsis Menu
            Menu {
                Button {
                    SettingsWindowController.shared.show()
                } label: {
                    Label("Preferences... (⌘,)", systemImage: "gearshape")
                }

                Divider()

                Button(role: .destructive) {
                    withAnimation(LiquidGlass.standardSpring) {
                        viewModel.clearAll()
                    }
                } label: {
                    Label("Close Tool (⎋)", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
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

    // MARK: - Category Filter Chips Row

    private var categoryChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All Tools" Chip
                categoryChip(
                    title: "All Tools",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    withAnimation(LiquidGlass.quickSpring) {
                        viewModel.selectedCategory = nil
                        viewModel.selectedIndex = 0
                    }
                }

                // Category Chips
                ForEach(ConversionCategory.allCases) { cat in
                    categoryChip(
                        title: cat.displayName,
                        icon: cat.icon,
                        isSelected: viewModel.selectedCategory == cat
                    ) {
                        withAnimation(LiquidGlass.quickSpring) {
                            viewModel.selectedCategory = cat
                            viewModel.selectedIndex = 0
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func categoryChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.75)
                        }
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        }
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.70))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area Router

    @ViewBuilder
    private var contentAreaView: some View {
        if viewModel.isShowingSettings {
            SettingsView(preferences: viewModel.preferences) {
                withAnimation(LiquidGlass.standardSpring) {
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
            // Launcher Main Discovery: List Mode or Grid Mode
            if viewModel.preferences.viewMode == .grid {
                gridModeDiscoveryView
            } else {
                listModeDiscoveryView
            }
        }
    }

    // MARK: - List Mode Discovery View (Top Shelf + List Rows, No "Suggestions" Label)

    private var listModeDiscoveryView: some View {
        VStack(spacing: 0) {
            // Category Filter Chips
            categoryChipsView
                .padding(.top, 10)
                .padding(.bottom, 8)

            let commands = viewModel.filteredCommands

            if commands.isEmpty {
                emptyUnavailableView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            // Top Shelf (Favorite / Top 5 squircle apps) when in default browse mode
                            if viewModel.searchQuery.isEmpty && viewModel.selectedCategory == nil && viewModel.droppedFiles.isEmpty {
                                topShelfView
                                    .padding(.top, 2)
                                    .padding(.bottom, 6)

                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                                    .padding(.horizontal, 16)
                            }

                            // Vertical list of tools
                            LazyVStack(spacing: 2) {
                                ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                                    listCommandRow(index: index, command: command)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.selectedIndex) { _, newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Top Shelf Row (5 large squircle icons)

    private var topShelfView: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.topShelfCommands) { cmd in
                Button {
                    viewModel.selectCommand(cmd)
                } label: {
                    VStack(spacing: 6) {
                        ToolSquircleIcon(command: cmd, size: 48, cornerRadius: 12)

                        Text(cmd.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.90))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 96)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - List Row Item

    private func listCommandRow(index: Int, command: ConversionCommand) -> some View {
        let isSelected = (index == viewModel.selectedIndex)
        let isFavorite = viewModel.preferences.isFavorite(id: command.id)

        return HStack(spacing: 12) {
            // Compact Squircle icon matching app style
            ToolSquircleIcon(command: command, size: 30, cornerRadius: 7.5)

            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 6) {
                    Text(command.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(Color.white)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.yellow)
                    }
                }

                Text(command.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.50))
                    .lineLimit(1)
            }

            Spacer()

            Text(command.category.displayName)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.40))

            if isSelected {
                Text("↩")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 3.5, style: .continuous).fill(Color.white.opacity(0.12)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            }
        }
        .contentShape(Rectangle())
        .id(index)
        .onTapGesture {
            viewModel.selectedIndex = index
            viewModel.selectCommand(command)
        }
    }

    // MARK: - Grid Mode Discovery View

    private var gridModeDiscoveryView: some View {
        VStack(spacing: 0) {
            // Category Filter Chips
            categoryChipsView
                .padding(.top, 10)
                .padding(.bottom, 8)

            let commands = viewModel.filteredCommands

            if commands.isEmpty {
                emptyUnavailableView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 68, maximum: 92), spacing: 8), count: 7), spacing: 14) {
                            ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                                gridCommandCell(index: index, command: command)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.selectedIndex) { _, newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private func gridCommandCell(index: Int, command: ConversionCommand) -> some View {
        let isSelected = (index == viewModel.selectedIndex)

        return Button {
            viewModel.selectedIndex = index
            viewModel.selectCommand(command)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    ToolSquircleIcon(command: command, size: 50, cornerRadius: 12.5)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 2)
                            .shadow(color: LiquidGlass.brandAccent.opacity(0.6), radius: 6)
                    }
                }

                Text(command.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(index)
    }

    private var emptyUnavailableView: some View {
        ContentUnavailableView {
            Label("No Matching Operations", systemImage: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
        } description: {
            Text("No operations matched \"\(viewModel.searchQuery)\".\nTry searching for 'compress', 'resize', 'convert', 'pdf', 'zip', or 'qr'")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.60))
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Tool Empty Drop Target View

    private func toolEmptyDropTargetView(command: ConversionCommand) -> some View {
        VStack(spacing: LiquidGlass.spaceLG) {
            Spacer()

            ToolSquircleIcon(command: command, size: 64, cornerRadius: 16)

            VStack(spacing: 4) {
                Text("Select a file for \(command.title)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)

                Text(dropPromptDescription(for: command))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: LiquidGlass.spaceMD) {
                GlassButton("Choose File...", icon: "folder", shortcutBadge: "⌘O", variant: .primary, size: .regular) {
                    viewModel.openFilePicker()
                }

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary, size: .regular) {
                    withAnimation(LiquidGlass.standardSpring) {
                        viewModel.goBack()
                    }
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LiquidGlass.spaceXL)
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
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            // File Information Header
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: 12) {
                    if first.category == .image {
                        ImageThumbnailView(url: first.url, maxPixelSize: 100, cornerRadius: 8)
                            .frame(width: 44, height: 44)
                    } else if first.category == .pdf {
                        PDFPageThumbnailView(url: first.url, pageIndex: 0, pageNumber: 1, onTap: {
                            QuickLookManager.shared.toggle(url: first.url)
                        })
                        .frame(width: 36, height: 46)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.16))
                                .frame(width: 44, height: 44)
                            Image(systemName: "archivebox.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.orange)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(first.filename)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                viewModel.droppedFiles = []
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(Color.white.opacity(0.60))
                            }
                            .buttonStyle(.plain)
                            .help("Remove dropped file (⌘⌫)")
                        }

                        Text(first.summaryDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.60))
                            .monospacedDigit()
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }

            Text("Suggested actions for this file:")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.65))
                .padding(.horizontal, 18)

            // Suggested Operations List or Grid
            if viewModel.preferences.viewMode == .grid {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 68, maximum: 92), spacing: 8), count: 7), spacing: 14) {
                        ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                            gridCommandCell(index: index, command: command)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                            listCommandRow(index: index, command: command)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - Simplified Footer Shortcut Bar (Matching Clean macOS Design)

    private var footerShortcutBar: some View {
        HStack(spacing: 14) {
            shortcutBadge("↑↓", label: "Navigate")
            shortcutBadge("↩", label: "Select")
            shortcutBadge("⌘K", label: "Actions")

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Text("100% Offline & Private")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func shortcutBadge(_ key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3.5, style: .continuous).fill(Color.white.opacity(0.10)))
                .foregroundStyle(Color.white.opacity(0.80))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.55))
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
