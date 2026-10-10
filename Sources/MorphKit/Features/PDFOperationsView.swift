import SwiftUI

public struct PDFOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // File Information Card with Real Thumbnail
            if let first = viewModel.droppedFiles.first {
                GlassCard {
                    HStack(spacing: 12) {
                        // Real First Page PDF Thumbnail
                        PDFPageThumbnailView(
                            url: first.url,
                            pageIndex: 0,
                            pageNumber: 1,
                            isSelected: false,
                            rotationAngle: viewModel.activeCommand?.id == "pdf.rotate" ? viewModel.rotationSelection : 0,
                            onTap: {
                                QuickLookManager.shared.toggle(url: first.url)
                            }
                        )
                        .frame(width: 50, height: 65)

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

                        Button {
                            QuickLookManager.shared.toggle(url: first.url)
                        } label: {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(6)
                                .background(Circle().fill(.quaternary))
                        }
                        .buttonStyle(.plain)
                        .help("Quick Look preview (Space)")

                        if viewModel.droppedFiles.count > 1 {
                            GlassPill("\(viewModel.droppedFiles.count) documents", style: .accent)
                        }
                    }
                    .padding(10)
                }
            }

            // Specific Configuration per command
            if let cmd = viewModel.activeCommand {
                switch cmd.id {
                case "pdf.compress":
                    compressPDFOptionsView
                case "pdf.merge":
                    mergePDFOptionsView
                case "pdf.split":
                    splitPDFOptionsView
                case "pdf.toImage":
                    pdfToImageOptionsView
                case "pdf.rotate":
                    rotatePDFOptionsView
                case "pdf.extractPages":
                    extractPagesOptionsView
                case "pdf.removePages", "pdf.managePages":
                    removePagesOptionsView
                case "pdf.reorderPages":
                    reorderPagesOptionsView
                default:
                    EmptyView()
                }
            }

            Spacer(minLength: 4)

            // Execution Bar
            HStack {
                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.pulse)
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 160)
                        Text("Processing locally...")
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
                    viewModel.goBack()
                }

                GlassButton("Process Now", icon: "sparkles", shortcutBadge: "↩", variant: .primary) {
                    applyPDFSettings()
                    Task {
                        await viewModel.runActiveCommand()
                    }
                }
                .disabled(viewModel.isProcessing)
            }
        }
        .padding(18)
    }

    // MARK: - Option Subviews

    private var compressPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Optimization Preset")
                .font(.figmaCallout(emphasized: true))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(CompressionPreset.allCases) { preset in
                    GlassCard(isSelected: viewModel.pdfSettings.compressionPreset == preset) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(preset.rawValue)
                                    .font(.figmaHeadline)
                                Spacer()
                                if viewModel.pdfSettings.compressionPreset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .symbolEffect(.bounce, value: viewModel.pdfSettings.compressionPreset)
                                        .font(.system(size: 12))
                                }
                            }

                            Text(preset == .light ? "Optimizes document streams while maintaining original image resolution." : "Downsamples embedded photos to \(Int(preset.pdfTargetDPI)) DPI.")
                                .font(.figmaSubheadline())
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .monospacedDigit()
                        }
                        .padding(12)
                    }
                    .onTapGesture {
                        viewModel.pdfSettings.compressionPreset = preset
                    }
                }
            }
        }
    }

    private var mergePDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Documents to Merge")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(viewModel.droppedFiles.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(item.filename)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.pageCount ?? 0) pages")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 110)

            LabeledContent {
                TextField("merged-document.pdf", text: $viewModel.customOutputFilename)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("Output Filename:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var splitPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $viewModel.splitModeTab) {
                Text("Split Every Page").tag(0)
                Text("Extract Range").tag(1)
            }
            .pickerStyle(.segmented)

            if viewModel.splitModeTab == 1 {
                LabeledContent {
                    TextField("1-3, 5", text: $viewModel.splitRangeText)
                        .textFieldStyle(.roundedBorder)
                } label: {
                    Text("Page Range (e.g. 1-3, 5):")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Every page will be extracted into a separate standalone PDF document.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var pdfToImageOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image Format")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Picker("Format", selection: $viewModel.pdfSettings.pdfToImageFormat) {
                        Text("PNG (Lossless)").tag(ImageFormat.png)
                        Text("JPEG (Compact)").tag(ImageFormat.jpeg)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Render Resolution")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Picker("Resolution", selection: $viewModel.dpiSelection) {
                        Text("72 DPI (Screen)").tag(CGFloat(72.0))
                        Text("150 DPI (Print)").tag(CGFloat(150.0))
                        Text("300 DPI (High)").tag(CGFloat(300.0))
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var rotatePDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rotation Angle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.rotationSelection)°")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
            }

            Picker("Angle", selection: $viewModel.rotationSelection) {
                Text("90° Clockwise").tag(90)
                Text("180° Flip").tag(180)
                Text("270° Counter-Clockwise").tag(270)
            }
            .pickerStyle(.segmented)

            // Visual Page Thumbnails with Live Rotation
            if let first = viewModel.droppedFiles.first, let count = first.pageCount {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(1...count, id: \.self) { pageNum in
                            PDFPageThumbnailView(
                                url: first.url,
                                pageIndex: pageNum - 1,
                                pageNumber: pageNum,
                                rotationAngle: viewModel.rotationSelection,
                                onTap: {}
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var extractPagesOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Pages to Extract")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.selectedPageIndices.count) selected")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
            }

            if let first = viewModel.droppedFiles.first, let count = first.pageCount {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(1...count, id: \.self) { pageNum in
                            let index = pageNum - 1
                            let isSelected = viewModel.selectedPageIndices.contains(index)

                            PDFPageThumbnailView(
                                url: first.url,
                                pageIndex: index,
                                pageNumber: pageNum,
                                isSelected: isSelected,
                                onTap: {
                                    if isSelected {
                                        viewModel.selectedPageIndices.remove(index)
                                    } else {
                                        viewModel.selectedPageIndices.insert(index)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var removePagesOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Pages to Remove")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.selectedPageIndices.count) marked for deletion")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.red)
            }

            if let first = viewModel.droppedFiles.first, let count = first.pageCount {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(1...count, id: \.self) { pageNum in
                            let index = pageNum - 1
                            let isMarked = viewModel.selectedPageIndices.contains(index)

                            PDFPageThumbnailView(
                                url: first.url,
                                pageIndex: index,
                                pageNumber: pageNum,
                                isMarkedForRemoval: isMarked,
                                onTap: {
                                    if isMarked {
                                        viewModel.selectedPageIndices.remove(index)
                                    } else {
                                        viewModel.selectedPageIndices.insert(index)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var reorderPagesOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reorder Pages (Use arrows to reposition)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            if let first = viewModel.droppedFiles.first {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.pageReorderList.enumerated()), id: \.offset) { position, originalPageIdx in
                            VStack(spacing: 4) {
                                PDFPageThumbnailView(
                                    url: first.url,
                                    pageIndex: originalPageIdx,
                                    pageNumber: originalPageIdx + 1,
                                    badgeText: "Pos \(position + 1)",
                                    onTap: {}
                                )

                                HStack(spacing: 8) {
                                    Button {
                                        if position > 0 {
                                            viewModel.movePage(from: position, to: position - 1)
                                        }
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .disabled(position == 0)
                                    .buttonStyle(.plain)

                                    Button {
                                        if position < viewModel.pageReorderList.count - 1 {
                                            viewModel.movePage(from: position, to: position + 1)
                                        }
                                    } label: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .disabled(position >= viewModel.pageReorderList.count - 1)
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func applyPDFSettings() {
        if viewModel.splitModeTab == 0 {
            viewModel.pdfSettings.splitMode = .allPages
        } else {
            viewModel.pdfSettings.splitMode = .pageRange(viewModel.splitRangeText)
        }
        viewModel.pdfSettings.rotationAngle = viewModel.rotationSelection
        viewModel.pdfSettings.pdfToImageDPI = viewModel.dpiSelection
    }
}
