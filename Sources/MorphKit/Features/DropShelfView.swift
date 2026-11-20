import SwiftUI
import AppKit

@MainActor
public final class DropShelfViewModel: ObservableObject {
    @Published public var isAddHovered = false
    @Published public var isDropBarHovered = false
    @Published public var isGridDropTargeted = false
    @Published public var hoveredItemId: UUID? = nil
    @Published public var draggedActionTarget: ShelfActionType? = nil
    @Published public var isCompactMode = false
    @Published public var isCreatingWorkspace = false
    @Published public var newWorkspaceName = ""

    public init() {}
}

public struct DropShelfView: View {
    @ObservedObject public var shelfManager: ShelfManager = .shared
    @ObservedObject public var viewModel: DropShelfViewModel

    public init(shelfManager: ShelfManager = .shared, viewModel: DropShelfViewModel = DropShelfViewModel()) {
        self.shelfManager = shelfManager
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Fixed Toolbar
            headerBar

            Divider()
                .background(Color.white.opacity(0.12))

            // 2. Main Content Area (Expanded Grid or Collapsed Bar)
            if viewModel.isCompactMode {
                collapsedShelfView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                expandedShelfView
                    .transition(.opacity)
            }

            Divider()
                .background(Color.white.opacity(0.12))

            // 3. Bottom Actions Section
            actionsSection
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(width: 440)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow, cornerRadius: 18)
                Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.85)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.22), value: viewModel.isCompactMode)
    }

    // MARK: - 1. Top Toolbar
    private var headerBar: some View {
        HStack(spacing: 0) {
            // Left Group: Add (+) | Collapse (︽)
            HStack(spacing: 0) {
                Button(action: openFilePicker) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Add files or folders to shelf")

                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1, height: 14)

                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        viewModel.isCompactMode.toggle()
                    }
                }) {
                    Image(systemName: viewModel.isCompactMode ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(viewModel.isCompactMode ? "Expand shelf" : "Collapse shelf")
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            Spacer()

            // Center: Collection / Workspace Selector Pill
            Menu {
                Section("Workspaces") {
                    ForEach(shelfManager.availableCollections, id: \.self) { collection in
                        Button(action: {
                            shelfManager.switchCollection(to: collection)
                        }) {
                            HStack {
                                Text(collection)
                                if shelfManager.activeCollection == collection {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("Reveal in Finder") {
                    if let selected = shelfManager.selectedItemId,
                       let item = shelfManager.items.first(where: { $0.id == selected }),
                       !item.isWebLink {
                        NSWorkspace.shared.activateFileViewerSelecting([item.url])
                    } else if let first = shelfManager.items.first(where: { !$0.isWebLink }) {
                        NSWorkspace.shared.activateFileViewerSelecting([first.url])
                    }
                }
                .disabled(shelfManager.items.allSatisfy { $0.isWebLink })

                Button("Clear Shelf", role: .destructive) {
                    shelfManager.clearShelf()
                }
                .disabled(shelfManager.items.isEmpty)
            } label: {
                HStack(spacing: 5) {
                    Text(shelfManager.activeCollection)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .opacity(0.8)
                }
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.09))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)

            Spacer()

            // Right Group: Launch Morph Panel (❐) & Settings (⚙)
            HStack(spacing: 6) {
                Button(action: {
                    FloatingPanelController.shared.toggle()
                }) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Toggle Morph Floating Launcher (⌥Space)")

                Button(action: {
                    SettingsWindowController.shared.show()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Settings (⌘,)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - 2. Expanded Shelf Grid
    private var expandedShelfView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 68, maximum: 74), spacing: 12)
                ],
                spacing: 14
            ) {
                // Special Action 1: Add to Grid
                addToGridCard

                // Special Action 2: Drop Bar Target
                dropBarCard

                // Dynamic Stored Items
                ForEach(shelfManager.items) { item in
                    gridItemCard(for: item)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 140, maxHeight: 310)
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: $viewModel.isGridDropTargeted) { providers in
            handleUniversalDrops(providers)
        }
    }

    // MARK: - Special Card: Add to Grid
    private var addToGridCard: some View {
        Button(action: openFilePicker) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(viewModel.isAddHovered ? 0.75 : 0.32),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(viewModel.isAddHovered ? 0.09 : 0.03))
                        )
                        .frame(width: 68, height: 68)

                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(.white.opacity(viewModel.isAddHovered ? 1.0 : 0.75))
                }

                Text("Add to Grid")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .lineLimit(1)
                    .frame(width: 68)
            }
        }
        .buttonStyle(.plain)
        .onHover { viewModel.isAddHovered = $0 }
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: $viewModel.isAddHovered) { handleUniversalDrops($0) }
    }

    // MARK: - Special Card: Drop Bar
    private var dropBarCard: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(viewModel.isDropBarHovered ? 0.85 : 0.35),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(viewModel.isDropBarHovered ? Color.cyan.opacity(0.22) : Color.white.opacity(0.03))
                    )
                    .frame(width: 68, height: 68)

                Image(systemName: "arrow.down")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(viewModel.isDropBarHovered ? .cyan : .white.opacity(0.75))
            }

            Text("Drop Bar")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(1)
                .frame(width: 68)
        }
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: $viewModel.isDropBarHovered) { handleUniversalDrops($0) }
    }

    // MARK: - Dynamic File-Type Card Rendering
    private func gridItemCard(for item: ShelfItem) -> some View {
        let isSelected = shelfManager.selectedItemId == item.id
        let isHovered = viewModel.hoveredItemId == item.id

        return VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Primary Preview Container (Consistent 68x68 footprint)
                previewContainer(for: item)
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? Color.cyan : (isHovered ? Color.white.opacity(0.45) : Color.white.opacity(0.12)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? Color.cyan.opacity(0.4) : Color.clear, radius: 6)

                // Delete 'X' badge on hover
                if isHovered {
                    Button(action: {
                        shelfManager.removeItem(id: item.id)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.92))
                            .background(Circle().fill(Color.black.opacity(0.75)))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: -4)
                    .help("Remove from shelf")
                }
            }
            .contentShape(Rectangle())
            .onDrag {
                if item.isWebLink {
                    return NSItemProvider(object: item.url as NSURL)
                } else {
                    return NSItemProvider(contentsOf: item.url) ?? NSItemProvider()
                }
            }
            .onTapGesture {
                shelfManager.selectedItemId = item.id
            }
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    if item.isWebLink {
                        NSWorkspace.shared.open(item.url)
                    } else if item.isDirectory {
                        NSWorkspace.shared.activateFileViewerSelecting([item.url])
                    } else {
                        NSWorkspace.shared.open(item.url)
                    }
                }
            )

            // Filename / Domain Title Label (Strictly bounded, middle-truncated, tooltip supported)
            Text(item.name)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.88))
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .frame(width: 68, height: 26, alignment: .top)
        }
        .help(item.tooltipText)
        .onHover { hovering in
            if hovering {
                viewModel.hoveredItemId = item.id
            } else if viewModel.hoveredItemId == item.id {
                viewModel.hoveredItemId = nil
            }
        }
    }

    // MARK: - Specialized Preview Content by Category
    @ViewBuilder
    private func previewContainer(for item: ShelfItem) -> some View {
        switch item.category {
        case .folder:
            // 1. Folders: Distinct macOS Folder Preview
            ZStack {
                Color(red: 0.12, green: 0.14, blue: 0.22).opacity(0.85)

                VStack(spacing: 2) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.98))

                    if let count = item.itemCount {
                        Text("\(count) items")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

        case .image:
            // 2. Images: Aspect-fit thumbnail that never stretches
            ZStack {
                Color.black.opacity(0.3)

                if let thumb = item.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(3)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 26))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

        case .audio:
            // 3. Audio: Light/translucent card with music note icon (matching reference a1.mp3)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(white: 0.94),
                        Color(white: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(Color(white: 0.55))
            }

        case .link:
            // 4. URLs: Compact Link Preview Card (NEVER oversized white block with raw text!)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.16, blue: 0.26),
                        Color(red: 0.07, green: 0.10, blue: 0.17)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color.cyan)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 4)

                    Text(item.name)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

        default:
            // 5. Other Files (PDF, Code, Archives, Vectors, etc.)
            ZStack {
                Color.white.opacity(0.06)

                if let thumb = item.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                } else {
                    Image(systemName: item.category.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
        }
    }

    // MARK: - 3. Collapsed Shelf View (Compact State)
    private var collapsedShelfView: some View {
        HStack(spacing: 12) {
            // Left: Floating Drop Target miniature icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: "circle.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            .help("Morph Drop Pod")

            // Center: Compact chips of held items
            if shelfManager.items.isEmpty {
                Text("Drop files here to store temporarily")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(shelfManager.items) { item in
                            HStack(spacing: 5) {
                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)

                                Text(item.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                }
            }

            Spacer()

            // Right: Expand button
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    viewModel.isCompactMode = false
                }
            }) {
                HStack(spacing: 4) {
                    Text("\(shelfManager.items.count)")
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Expand to full grid")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(height: 58)
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: $viewModel.isGridDropTargeted) { providers in
            handleUniversalDrops(providers)
        }
    }

    // MARK: - 4. Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Actions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .textCase(.uppercase)

                Spacer()

                if shelfManager.isProcessing {
                    HStack(spacing: 5) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                        Text(shelfManager.statusMessage ?? "Processing...")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                } else if let msg = shelfManager.statusMessage {
                    Text(msg)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green.opacity(0.9))
                }
            }

            if shelfManager.items.isEmpty {
                // Empty state badge exactly matching reference screenshot
                HStack {
                    Text("Empty")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    Spacer()
                }
            } else {
                // Interactive Action Pills (Drop Target + Tap to Execute)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ShelfActionType.allCases) { action in
                            actionPill(for: action)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Action Pill Drop Target
    private func actionPill(for action: ShelfActionType) -> some View {
        let isTargeted = viewModel.draggedActionTarget == action
        let tint = action.tintColor

        return HStack(spacing: 5) {
            Image(systemName: action.iconName)
                .font(.system(size: 11, weight: .semibold))
            Text(action.rawValue)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isTargeted ? .white : Color(red: tint.red, green: tint.green, blue: tint.blue))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isTargeted ? Color(red: tint.red, green: tint.green, blue: tint.blue) : Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isTargeted ? Color.white : Color(red: tint.red, green: tint.green, blue: tint.blue).opacity(0.3),
                    lineWidth: 1
                )
        )
        .scaleEffect(isTargeted ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTargeted)
        .onTapGesture {
            if let targetItem = selectedItemOrFirst {
                Task {
                    await shelfManager.executeAction(action, on: targetItem)
                }
            }
        }
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: Binding(
            get: { viewModel.draggedActionTarget == action },
            set: { targeted in
                viewModel.draggedActionTarget = targeted ? action : nil
            }
        )) { providers in
            handleActionDrop(action: action, providers: providers)
        }
    }

    private var selectedItemOrFirst: ShelfItem? {
        if let selId = shelfManager.selectedItemId,
           let item = shelfManager.items.first(where: { $0.id == selId }) {
            return item
        }
        return shelfManager.items.first
    }

    // MARK: - Helpers & Drop Handling
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            shelfManager.addItems(urls: panel.urls)
        }
    }

    private func handleUniversalDrops(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            // 1. File or Folder URL
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    var droppedURL: URL? = nil
                    if let data = item as? Data {
                        droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let url = item as? URL {
                        droppedURL = url
                    }
                    if let url = droppedURL {
                        DispatchQueue.main.async {
                            shelfManager.addItem(url: url)
                        }
                    }
                }
                handled = true
            }
            // 2. Web URL
            else if provider.hasItemConformingToTypeIdentifier("public.url") {
                provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, _ in
                    var droppedURL: URL? = nil
                    if let data = item as? Data {
                        droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let url = item as? URL {
                        droppedURL = url
                    }
                    if let url = droppedURL {
                        DispatchQueue.main.async {
                            shelfManager.addItem(url: url)
                        }
                    }
                }
                handled = true
            }
            // 3. Plain Text (may contain web link e.g. "https://...")
            else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { item, _ in
                    if let text = item as? String {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                            DispatchQueue.main.async {
                                shelfManager.addLink(urlString: trimmed)
                            }
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }

    private func handleActionDrop(action: ShelfActionType, providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    var droppedURL: URL? = nil
                    if let data = item as? Data {
                        droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let u = item as? URL {
                        droppedURL = u
                    }

                    if let url = droppedURL {
                        DispatchQueue.main.async {
                            let targetItem = shelfManager.items.first(where: { $0.url.path == url.path }) ?? ShelfItem(url: url)
                            Task {
                                await shelfManager.executeAction(action, on: targetItem)
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
