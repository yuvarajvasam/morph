import SwiftUI
import UniformTypeIdentifiers
import AppKit

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
            // MARK: - TOP BAR
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

                // Category Filter Pills (Screens 1, 2, 3, 8)
                categoryDiscoveryPillsView
            }

            // MARK: - MAIN CONTENT SURFACE
            resultsSurfaceView
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isToolOrResultOpen)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.selectedCategory)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.viewMode)
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
                    .stroke(SubtleTheme.accentBlue, lineWidth: 2)
                    .background(SubtleTheme.accentBlue.opacity(0.12))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(SubtleTheme.accentBlue)
                            Text("Drop files to inspect & process with Morph")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(SubtleTheme.textPrimary)
                        }
                    }
            }
        }
        .overlay(alignment: .top) {
            if let msg = viewModel.copyStatusMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SubtleTheme.accentGreen)
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SubtleTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(SubtleTheme.bgCard)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                        )
                )
                .padding(.top, 50)
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

    // MARK: - Top Area: Search Capsule (Screens 1, 2, 3, 8)

    private var searchCapsuleView: some View {
        HStack(spacing: 8) {
            // View Mode Toggle Button [::] (Screen 1, 2, 3)
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    viewModel.toggleViewMode()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SubtleTheme.accentBlue)
                        .frame(width: 28, height: 28)
                    Image(systemName: viewModeIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(.plain)
            .help("Toggle view mode: Launcher / Grid / List (⌘V)")

            // Search Bar Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(SubtleTheme.textSecondary)

                TextField("Search tools or drop a file...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(SubtleTheme.textPrimary)
                    .focused($isSearchFocused)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(SubtleTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear search (⎋)")
                }
            }

            // Trailing "..." Menu
            Menu {
                Button("Preferences... (⌘,)") {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        viewModel.isShowingSettings = true
                    }
                }
                Divider()
                Button("Launcher View") {
                    withAnimation { viewModel.viewMode = .launcher }
                }
                Button("Grid View") {
                    withAnimation { viewModel.viewMode = .grid }
                }
                Button("List View") {
                    withAnimation { viewModel.viewMode = .list }
                }
                Divider()
                Button("Choose Files... (⌘O)") {
                    viewModel.openFilePicker()
                }
                if !viewModel.droppedFiles.isEmpty {
                    Button("Clear Dropped Files") {
                        viewModel.clearAll()
                    }
                }
                Divider()
                Button("Quit Morph (⌘Q)") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SubtleTheme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(SubtleTheme.bgCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                            )
                    )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SubtleTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var viewModeIcon: String {
        switch viewModel.viewMode {
        case .launcher: return "circle.grid.2x2.fill"
        case .grid: return "square.grid.3x3.fill"
        case .list: return "list.bullet"
        }
    }

    // MARK: - Category Discovery Pills (Screens 1, 2, 3, 8)

    private var categoryDiscoveryPillsView: some View {
        HStack(spacing: 6) {
            // "All" Pill
            let allMatchCount = viewModel.searchMatchCount(for: nil)
            let isSearching = !viewModel.searchQuery.isEmpty
            let isAllSelected = (viewModel.selectedCategory == nil)

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    viewModel.selectedCategory = nil
                    viewModel.selectedIndex = 0
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(isSearching ? "All \(allMatchCount)" : "All")
                        .font(.system(size: 12, weight: isAllSelected ? .semibold : .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    if isAllSelected {
                        Capsule(style: .continuous)
                            .fill(SubtleTheme.accentBlue)
                    } else {
                        Capsule(style: .continuous)
                            .fill(SubtleTheme.bgCard)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                            )
                    }
                }
                .foregroundStyle(isAllSelected ? Color.white : SubtleTheme.textSecondary)
            }
            .buttonStyle(.plain)

            // Category Pills (Images, PDFs, Archives, QR & Barcodes)
            ForEach(ConversionCategory.allCases) { cat in
                let isCatSelected = (viewModel.selectedCategory == cat)
                let catMatchCount = viewModel.searchMatchCount(for: cat)

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.selectedCategory = isCatSelected ? nil : cat
                        viewModel.selectedIndex = 0
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(isSearching ? "\(cat.displayName) \(catMatchCount)" : cat.displayName)
                            .font(.system(size: 12, weight: isCatSelected ? .semibold : .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        if isCatSelected {
                            Capsule(style: .continuous)
                                .fill(SubtleTheme.accentBlue)
                        } else {
                            Capsule(style: .continuous)
                                .fill(SubtleTheme.bgCard)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                )
                        }
                    }
                    .foregroundStyle(isCatSelected ? Color.white : SubtleTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Top Area: Tool Navigation Capsule (Screens 4, 5, 6, 7, 9)

    private var toolNavigationCapsuleView: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    viewModel.goBack()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(SubtleTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SubtleTheme.bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .help("Back (⎋)")

            if let activeCmd = viewModel.activeCommand {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(activeCmd.subtleColor)
                            .frame(width: 24, height: 24)
                        Image(systemName: activeCmd.systemIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text(activeCmd.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SubtleTheme.textPrimary)
                }
            } else if viewModel.isShowingSettings {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SubtleTheme.accentBlue)
                            .frame(width: 24, height: 24)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text("Settings")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SubtleTheme.textPrimary)
                }
            } else if viewModel.currentResult != nil {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(SubtleTheme.accentGreen)
                    Text("Result Preview")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SubtleTheme.textPrimary)
                }
            }

            Spacer()

            // Trailing "..." Menu
            Menu {
                if viewModel.isShowingSettings {
                    Button("Close Settings (⎋)") {
                        withAnimation { viewModel.isShowingSettings = false }
                    }
                } else {
                    Button("Settings (⌘,)") {
                        withAnimation { viewModel.isShowingSettings = true }
                    }
                    Button("Reset Tool") {
                        viewModel.resetCurrentTool()
                    }
                    Button("Clear Dropped Files") {
                        viewModel.clearAll()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SubtleTheme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(SubtleTheme.bgCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                            )
                    )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SubtleTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Main Content Surface Routing

    @ViewBuilder
    private var resultsSurfaceView: some View {
        GlassCard(cornerRadius: 14) {
            Group {
                if viewModel.isShowingSettings {
                    // Screen 9: Settings
                    SettingsView(preferences: viewModel.preferences) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.isShowingSettings = false
                        }
                    }
                } else if let result = viewModel.currentResult {
                    ResultPreviewView(viewModel: viewModel, result: result)
                } else if let activeCmd = viewModel.activeCommand {
                    // Screens 4, 5, 6, 7: Tool Workflows
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
                } else if !viewModel.searchQuery.isEmpty {
                    // Screen 8: Search Results
                    searchResultsView
                } else {
                    // Screens 1, 2, 3: Launcher / Grid / List
                    switch viewModel.viewMode {
                    case .launcher:
                        launcherDefaultView
                    case .grid:
                        toolsGridView
                    case .list:
                        toolsListView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Screen 1: Launcher (Default)

    private var launcherDefaultView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // "Most Used" row header
            HStack {
                Text("Most Used")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SubtleTheme.textPrimary)

                Spacer()

                Button("See All") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        viewModel.viewMode = .grid
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.accentBlue)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // 5 Most Used Cards (Screen 1)
            HStack(spacing: 10) {
                ForEach(ConversionRegistry.shared.mostUsedCommands) { cmd in
                    Button {
                        viewModel.selectCommand(cmd)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(cmd.subtleColor)
                                    .frame(width: 40, height: 40)
                                Image(systemName: cmd.systemIcon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.white)
                            }

                            Text(cmd.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(SubtleTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 28)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(SubtleTheme.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Mode Switcher Pills: [ Drop Files ] vs [ Browse Tools ]
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        withAnimation {
                            viewModel.activeLauncherTab = .dropFiles
                        }
                    } label: {
                        Text("Drop Files")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(viewModel.activeLauncherTab == .dropFiles ? SubtleTheme.accentBlue : Color.clear)
                            )
                            .foregroundStyle(viewModel.activeLauncherTab == .dropFiles ? Color.white : SubtleTheme.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation {
                            viewModel.viewMode = .grid
                        }
                    } label: {
                        Text("Browse Tools")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.clear)
                            )
                            .foregroundStyle(SubtleTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(3)
                .background(
                    Capsule(style: .continuous)
                        .fill(SubtleTheme.bgCard)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                        )
                )
                Spacer()
            }
            .padding(.top, 2)

            // Large File Drop Area (Screen 1)
            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(SubtleTheme.textSecondary.opacity(0.8))

                VStack(spacing: 4) {
                    Text("Drop files here")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SubtleTheme.textPrimary)

                    Text("Images, PDFs, Archives and more")
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.textSecondary)
                }

                Button {
                    viewModel.openFilePicker()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 12, weight: .medium))
                        Text("Choose Files...")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SubtleTheme.accentBlue)
                    )
                    .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SubtleTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .padding(14)
    }

    // MARK: - Screen 2: Tools - Grid View

    private var toolsGridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let targetCat = viewModel.selectedCategory ?? .image
                categorySectionHeader(category: targetCat)

                let commands = ConversionRegistry.shared.commands(for: targetCat)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(commands) { cmd in
                        Button {
                            viewModel.selectCommand(cmd)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(cmd.subtleColor)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: cmd.systemIcon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.white)
                                }

                                Text(cmd.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SubtleTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 82)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(SubtleTheme.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Accordion rows for other categories
                VStack(spacing: 6) {
                    ForEach(ConversionCategory.allCases.filter { $0 != targetCat }) { otherCat in
                        categoryAccordionRow(category: otherCat)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
    }

    // MARK: - Screen 3: Tools - List View

    private var toolsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let targetCat = viewModel.selectedCategory ?? .image
                categorySectionHeader(category: targetCat)

                let commands = ConversionRegistry.shared.commands(for: targetCat)
                VStack(spacing: 5) {
                    ForEach(Array(commands.enumerated()), id: \.element.id) { index, cmd in
                        let isSelected = (index == viewModel.selectedIndex)
                        Button {
                            viewModel.selectedIndex = index
                            viewModel.selectCommand(cmd)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(cmd.subtleColor)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: cmd.systemIcon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.white)
                                }

                                Text(cmd.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SubtleTheme.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(SubtleTheme.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? SubtleTheme.accentBlue.opacity(0.18) : SubtleTheme.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(isSelected ? SubtleTheme.accentBlue.opacity(0.4) : SubtleTheme.borderSubtle, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Accordion rows for other categories
                VStack(spacing: 6) {
                    ForEach(ConversionCategory.allCases.filter { $0 != targetCat }) { otherCat in
                        categoryAccordionRow(category: otherCat)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
    }

    // MARK: - Screen 8: Search Results

    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let matches = viewModel.filteredCommands

                if matches.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(SubtleTheme.textSecondary)
                        Text("No matching tools found for \"\(viewModel.searchQuery)\"")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SubtleTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    // Direct matches list with ↵ badge on selected
                    VStack(spacing: 6) {
                        ForEach(Array(matches.enumerated()), id: \.element.id) { index, cmd in
                            let isSelected = (index == viewModel.selectedIndex)
                            Button {
                                viewModel.selectedIndex = index
                                viewModel.selectCommand(cmd)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(cmd.subtleColor)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: cmd.systemIcon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.white)
                                    }

                                    Text(cmd.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(SubtleTheme.textPrimary)

                                    Spacer()

                                    if isSelected {
                                        Text("↵")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(SubtleTheme.accentBlue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                    .fill(SubtleTheme.accentBlue.opacity(0.18))
                                            )
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? SubtleTheme.accentBlue.opacity(0.18) : SubtleTheme.bgCard)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(isSelected ? SubtleTheme.accentBlue.opacity(0.4) : SubtleTheme.borderSubtle, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Related Tools Section (Screen 8)
                    let related = viewModel.relatedCommandsForSearch
                    if !related.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related Tools")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(SubtleTheme.textSecondary)
                                .padding(.top, 6)

                            VStack(spacing: 6) {
                                ForEach(related) { cmd in
                                    Button {
                                        viewModel.selectCommand(cmd)
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .fill(cmd.subtleColor)
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: cmd.systemIcon)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(Color.white)
                                            }

                                            Text(cmd.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(SubtleTheme.textPrimary)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(SubtleTheme.bgCard)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    // MARK: - Category Header & Accordion Helpers

    private func categorySectionHeader(category: ConversionCategory) -> some View {
        HStack(spacing: 6) {
            Text(category.displayName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SubtleTheme.textPrimary)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SubtleTheme.textSecondary)
            Spacer()
        }
    }

    private func categoryAccordionRow(category: ConversionCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack {
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SubtleTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SubtleTheme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(SubtleTheme.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SubtleTheme.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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

