import SwiftUI
import AppKit

public struct PDFOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Main configuration for the specific PDF operation
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let cmd = viewModel.activeCommand {
                        switch cmd.id {
                        case "pdf.merge":
                            mergePDFView
                        case "pdf.compress":
                            compressPDFView
                        case "pdf.split":
                            splitPDFView
                        case "pdf.toImage":
                            pdfToImageView
                        case "pdf.rotate":
                            rotatePDFView
                        case "pdf.extractPages":
                            extractPagesView
                        case "pdf.removePages", "pdf.managePages":
                            removePagesView
                        case "pdf.reorderPages":
                            reorderPagesView
                        default:
                            mergePDFView
                        }
                    }

                    // Output Location Section (Screen 5 Reference)
                    outputLocationSection
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 4)

            // Execution / Action Bar (Screen 5: Reset on left, Merge PDF on right)
            bottomActionBar
        }
        .padding(16)
    }

    // MARK: - Screen 5: Merge PDF Focused View

    private var mergePDFView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reorderable File List Card
            VStack(spacing: 8) {
                if viewModel.droppedFiles.isEmpty {
                    // Empty state
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(SubtleTheme.redTint)
                                .frame(width: 44, height: 44)
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 18))
                                .foregroundStyle(SubtleTheme.red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No PDF documents selected")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SubtleTheme.textPrimary)
                            Text("Choose at least 2 PDF files to merge into one")
                                .font(.system(size: 11))
                                .foregroundStyle(SubtleTheme.textSecondary)
                        }

                        Spacer()

                        GlassButton("Add Files...", icon: "plus", variant: .secondary, size: .small) {
                            viewModel.openFilePicker()
                        }
                    }
                    .padding(12)
                } else {
                    // List of files with drag handle, number, red icon, name, pages & size, delete button
                    VStack(spacing: 4) {
                        ForEach(Array(viewModel.droppedFiles.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 11))
                                    .foregroundStyle(SubtleTheme.textTertiary)

                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(SubtleTheme.textSecondary)
                                    .frame(width: 14)

                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(SubtleTheme.red)

                                Text(item.filename)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(SubtleTheme.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(item.pageCount ?? 1) pages • \(item.formattedFileSize)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(SubtleTheme.textSecondary)
                                    .monospacedDigit()

                                Button {
                                    viewModel.removeFile(at: index)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(SubtleTheme.textSecondary)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(SubtleTheme.surfaceHover)
                            }
                        }
                    }

                    // Bottom list row: Add Files on left, Clear All on right
                    HStack {
                        Button {
                            viewModel.openFilePicker()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Add Files")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(SubtleTheme.accentLight)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            withAnimation(LiquidGlass.quickSpring) {
                                viewModel.droppedFiles = []
                            }
                        } label: {
                            Text("Clear All")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(SubtleTheme.red.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SubtleTheme.cardBackgroundSubtle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                    }
            }

            // Output File Name (Screen 5 Reference)
            VStack(alignment: .leading, spacing: 6) {
                Text("Output File Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SubtleTheme.textSecondary)

                HStack {
                    TextField("Merged Document", text: $viewModel.pdfMergeOutputFilename)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.textPrimary)
                    Text(".pdf")
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

    // MARK: - Output Location Section (Screen 5 Reference)

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
                .help("Select custom destination folder")
            }
        }
    }

    // MARK: - Other PDF Subviews

    private var compressPDFView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PDF Compression Preset")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(CompressionPreset.allCases) { preset in
                    GlassButton(
                        preset.rawValue,
                        variant: viewModel.pdfSettings.compressionPreset == preset ? .primary : .secondary,
                        size: .regular
                    ) {
                        viewModel.pdfSettings.compressionPreset = preset
                    }
                }
            }
        }
    }

    private var splitPDFView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Mode", selection: $viewModel.splitModeTab) {
                Text("All Pages").tag(0)
                Text("Page Range").tag(1)
            }
            .pickerStyle(.segmented)

            if viewModel.splitModeTab == 1 {
                TextField("e.g. 1-3, 5", text: $viewModel.splitRangeText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var pdfToImageView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Render Format & Resolution")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach([ImageFormat.png, ImageFormat.jpeg], id: \.self) { fmt in
                    GlassButton(
                        fmt.rawValue,
                        variant: viewModel.pdfSettings.pdfToImageFormat == fmt ? .primary : .secondary,
                        size: .small
                    ) {
                        viewModel.pdfSettings.pdfToImageFormat = fmt
                    }
                }
            }
        }
    }

    private var rotatePDFView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rotate Document Pages")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach([90, 180, 270], id: \.self) { deg in
                    GlassButton(
                        "\(deg)°",
                        icon: "rotate.right",
                        variant: viewModel.rotationSelection == deg ? .primary : .secondary,
                        size: .regular
                    ) {
                        viewModel.rotationSelection = deg
                    }
                }
            }
        }
    }

    private var extractPagesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extract Selected Pages")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
            Text("Pulls selected pages into an isolated standalone PDF document.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textTertiary)
        }
    }

    private var removePagesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delete Pages")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
            Text("Removes unwanted pages from the current PDF.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textTertiary)
        }
    }

    private var reorderPagesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reorder Pages")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
            Text("Rearrange page order and export new sequence.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textTertiary)
        }
    }

    // MARK: - Bottom Action Bar (Screen 5 Reference)

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
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text(actionButtonTitle)
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

    private var actionButtonTitle: String {
        switch viewModel.activeCommand?.id {
        case "pdf.merge": return "Merge PDF"
        case "pdf.compress": return "Compress PDF"
        case "pdf.split": return "Split PDF"
        case "pdf.toImage": return "Export Images"
        case "pdf.rotate": return "Rotate Pages"
        case "pdf.extractPages": return "Extract"
        case "pdf.removePages": return "Remove Pages"
        case "pdf.reorderPages": return "Reorder"
        default: return "Process"
        }
    }
}
