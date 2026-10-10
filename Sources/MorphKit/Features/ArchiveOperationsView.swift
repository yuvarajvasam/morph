import SwiftUI
import AppKit

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
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if isExtractionOrInspect {
                        extractionInspectView
                    } else {
                        // Screen 6: Create Archive View
                        createArchiveView
                    }

                    // Output Location Section (Screen 6 Reference)
                    outputLocationSection
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 4)

            // Execution / Action Bar (Screen 6: Reset on left, Create Archive on right)
            bottomActionBar
        }
        .padding(16)
    }

    // MARK: - Screen 6: Create Archive View

    private var createArchiveView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Drop files or folders here
            VStack(spacing: 8) {
                if viewModel.droppedFiles.isEmpty {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(SubtleTheme.blue)
                        .padding(.top, 6)

                    Text("Drop files or folders here")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SubtleTheme.textPrimary)

                    Button {
                        viewModel.openFilePicker()
                    } label: {
                        Text("or choose files...")
                            .font(.system(size: 11))
                            .foregroundStyle(SubtleTheme.accentLight)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(SubtleTheme.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.droppedFiles.count) file\(viewModel.droppedFiles.count > 1 ? "s" : "") to archive")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Text(viewModel.droppedFiles.map { $0.filename }.joined(separator: ", "))
                                .font(.system(size: 10))
                                .foregroundStyle(SubtleTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            viewModel.droppedFiles = []
                        } label: {
                            Text("Clear")
                                .font(.system(size: 11))
                                .foregroundStyle(SubtleTheme.red.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SubtleTheme.cardBackgroundSubtle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                    }
            }

            // Dropdowns row: Archive Format & Compression Level (Screen 6 Reference)
            HStack(spacing: 12) {
                // Archive Format
                VStack(alignment: .leading, spacing: 6) {
                    Text("Archive Format")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SubtleTheme.textSecondary)

                    Menu {
                        Button("ZIP") { viewModel.archiveFormat = .zip }
                        Button("TAR") { viewModel.archiveFormat = .tar }
                        Button("TAR.GZ") { viewModel.archiveFormat = .tarGz }
                    } label: {
                        HStack {
                            Text(viewModel.archiveFormat.displayName)
                                .font(.system(size: 12))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(SubtleTheme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.cardBackgroundSubtle)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                                }
                        }
                    }
                    .menuStyle(.borderlessButton)
                }

                // Compression Level
                VStack(alignment: .leading, spacing: 6) {
                    Text("Compression Level")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SubtleTheme.textSecondary)

                    Menu {
                        Button("Fast") { viewModel.archiveCompressionLevel = "Fast" }
                        Button("Normal") { viewModel.archiveCompressionLevel = "Normal" }
                        Button("Maximum") { viewModel.archiveCompressionLevel = "Maximum" }
                    } label: {
                        HStack {
                            Text(viewModel.archiveCompressionLevel)
                                .font(.system(size: 12))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(SubtleTheme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.cardBackgroundSubtle)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                                }
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            // Split into multiple volumes checkbox (Screen 6 Reference)
            Toggle("Split into multiple volumes (optional)", isOn: $viewModel.splitArchiveVolumes)
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textSecondary)
                .toggleStyle(.checkbox)

            // Output File Name (Screen 6 Reference)
            VStack(alignment: .leading, spacing: 6) {
                Text("Output File Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SubtleTheme.textSecondary)

                HStack {
                    TextField("Archive", text: $viewModel.archiveOutputFilename)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.textPrimary)
                    Text(".\(viewModel.archiveFormat.rawValue)")
                        .font(.system(size: 11))
                        .foregroundStyle(SubtleTheme.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubtleTheme.cardBackgroundSubtle)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                        }
                }
            }
        }
    }

    // MARK: - Output Location Section (Screen 6 Reference)

    private var outputLocationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Output Location")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.blue)
                    Text(viewModel.outputLocationName)
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(SubtleTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubtleTheme.cardBackgroundSubtle)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                        }
                }

                Button {
                    viewModel.chooseOutputFolder()
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(SubtleTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SubtleTheme.cardBackgroundSubtle)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                                }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Extraction / Inspect Subview

    private var extractionInspectView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: 10) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SubtleTheme.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(first.filename)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SubtleTheme.textPrimary)
                        Text(first.formattedFileSize)
                            .font(.system(size: 11))
                            .foregroundStyle(SubtleTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SubtleTheme.cardBackgroundSubtle)
                }
            } else {
                Text("Select an archive to inspect or extract")
                    .font(.system(size: 12))
                    .foregroundStyle(SubtleTheme.textSecondary)
            }
        }
    }

    // MARK: - Bottom Action Bar (Screen 6 Reference)

    private var bottomActionBar: some View {
        HStack {
            Button {
                viewModel.resetCurrentTool()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                    Text("Reset")
                        .font(.system(size: 12))
                }
                .foregroundStyle(SubtleTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubtleTheme.cardBackgroundSubtle)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                        }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Processing...")
                    .font(.system(size: 12))
                    .foregroundStyle(SubtleTheme.textSecondary)
            }

            Button {
                Task {
                    await viewModel.runActiveCommand()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 12))
                    Text(isExtractionOrInspect ? "Extract" : "Create Archive")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SubtleTheme.accentGradient)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessing || viewModel.droppedFiles.isEmpty)
        }
        .padding(.top, 4)
    }
}
