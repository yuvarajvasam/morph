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
        VStack(alignment: .leading, spacing: 14) {
            // Header / Dropped Files Card
            if let first = viewModel.droppedFiles.first {
                GlassCard {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.18))
                                .frame(width: 48, height: 48)
                            Image(systemName: isExtractionOrInspect ? "tray.and.arrow.up.fill" : "archivebox.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(first.filename)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text(first.summaryDescription)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Spacer()

                        if viewModel.droppedFiles.count > 1 {
                            GlassPill("+\(viewModel.droppedFiles.count - 1) more files", style: .accent)
                        }
                    }
                    .padding(10)
                }
            }

            // Options configuration
            if isExtractionOrInspect {
                extractionOptionsView
            } else {
                compressionOptionsView
            }

            Spacer(minLength: 4)

            // Execution Bar
            HStack {
                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LiquidGlass.bridgeTint)
                            .symbolEffect(.pulse)
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 160)
                        Text(isExtractionOrInspect ? "Extracting archive..." : "Creating archive...")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }

                Spacer()

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.goBack()
                    }
                }

                GlassButton(
                    isExtractionOrInspect ? "Extract Now" : "Create Archive",
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
        .padding(14)
        .onAppear {
            if isExtractionOrInspect, let first = viewModel.droppedFiles.first {
                loadArchiveEntries(url: first.url)
            }
        }
    }

    // MARK: - Compression Options

    private var compressionOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Archive Format")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Archive Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    TextField("Archive Name", text: $viewModel.customOutputFilename)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))

                    Text(".\(viewModel.archiveFormat.fileExtension)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            // Multiple files summary
            if viewModel.droppedFiles.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    Text("\(viewModel.droppedFiles.count) items will be compressed together preserving structure.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Extraction Options

    private var extractionOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Archive Contents")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if !viewModel.archiveEntries.isEmpty {
                    Text("\(viewModel.archiveEntries.count) items inside")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isLoadingArchiveEntries {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Reading archive index...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else if viewModel.archiveEntries.isEmpty {
                Text("No preview entries found in this archive.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.archiveEntries.prefix(25).enumerated()), id: \.offset) { _, entry in
                            HStack(spacing: 6) {
                                Image(systemName: entry.hasSuffix("/") ? "folder" : "doc")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(entry)
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                            }
                        }
                        if viewModel.archiveEntries.count > 25 {
                            Text("... and \(viewModel.archiveEntries.count - 25) more items")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 120)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
            }
        }
    }

    private func loadArchiveEntries(url: URL) {
        viewModel.isLoadingArchiveEntries = true
        Task.detached(priority: .userInitiated) {
            let (_, _, entries) = (try? ArchiveEngine.shared.inspect(url: url)) ?? (0, 0, [])
            await MainActor.run {
                self.viewModel.archiveEntries = entries
                self.viewModel.isLoadingArchiveEntries = false
            }
        }
    }
}
