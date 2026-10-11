import SwiftUI

public struct ArchiveOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    private var isExtractionOrInspect: Bool {
        viewModel.activeCommand?.id == "archive.extract" || viewModel.activeCommand?.id == "archive.inspect"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            // Header / Dropped Files Card
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: LiquidGlass.spaceMD) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.orange.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: isExtractionOrInspect ? "tray.and.arrow.up.fill" : "archivebox.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(first.filename)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        Text(first.summaryDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                    }

                    Spacer()

                    if viewModel.droppedFiles.count > 1 {
                        GlassPill("+\(viewModel.droppedFiles.count - 1) more files", style: .accent)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
            }

            // Options configuration
            if isExtractionOrInspect {
                extractionOptionsView
            } else {
                compressionOptionsView
            }

            Spacer(minLength: 4)

            // Execution Bar
            HStack(spacing: LiquidGlass.spaceMD) {
                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 140)
                        Text(isExtractionOrInspect ? "Extracting archive..." : "Creating archive...")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.red)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.red)
                            .lineLimit(2)
                    }
                }

                Spacer()

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary) {
                    withAnimation(LiquidGlass.standardSpring) {
                        viewModel.goBack()
                    }
                }

                GlassButton(
                    isExtractionOrInspect ? "Extract Archive" : "Create Archive",
                    icon: isExtractionOrInspect ? "tray.and.arrow.up" : "archivebox",
                    shortcutBadge: "↩",
                    variant: .primary
                ) {
                    Task {
                        await viewModel.executeCurrentOperation()
                    }
                }
                .disabled(viewModel.droppedFiles.isEmpty || viewModel.isProcessing)
            }
        }
        .padding(LiquidGlass.spaceLG)
        .onAppear {
            if isExtractionOrInspect, let first = viewModel.droppedFiles.first {
                loadArchiveEntries(url: first.url)
            }
        }
    }

    // MARK: - Compression Options

    private var compressionOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Archive Format")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 6) {
                ForEach(ArchiveFormat.allCases) { format in
                    GlassButton(
                        format.rawValue,
                        variant: viewModel.archiveFormat == format ? .primary : .secondary,
                        size: .regular
                    ) {
                        viewModel.archiveFormat = format
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Archive Name")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 6) {
                    TextField("Archive Name", text: $viewModel.customOutputFilename)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))

                    Text(".\(viewModel.archiveFormat.fileExtension)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.top, 4)

            if viewModel.droppedFiles.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 11))
                    Text("\(viewModel.droppedFiles.count) items will be compressed together preserving structure.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Extraction Options

    private var extractionOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            HStack {
                Text("Archive Contents")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                Spacer()

                if !viewModel.archiveEntries.isEmpty {
                    Text("\(viewModel.archiveEntries.count) items inside")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .monospacedDigit()
                }
            }

            if viewModel.isLoadingArchiveEntries {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Reading archive directory...")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
            } else if viewModel.archiveEntries.isEmpty {
                Text("Unable to inspect entries or empty archive.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 70)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(viewModel.archiveEntries, id: \.self) { entry in
                            HStack(spacing: 6) {
                                Image(systemName: entry.hasSuffix("/") ? "folder" : "doc")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.secondary)
                                Text(entry)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxHeight: 130)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
            }
        }
    }

    private func loadArchiveEntries(url: URL) {
        viewModel.isLoadingArchiveEntries = true
        Task.detached(priority: .userInitiated) {
            let entries = (try? ArchiveEngine.shared.inspect(url: url).entries) ?? []
            await MainActor.run {
                viewModel.archiveEntries = entries
                viewModel.isLoadingArchiveEntries = false
            }
        }
    }
}
