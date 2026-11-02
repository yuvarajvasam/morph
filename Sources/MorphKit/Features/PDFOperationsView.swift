import SwiftUI

/// Unified PDF Operations Screen (Layer B Content Surface) conforming to macOS HIG:
/// Hierarchy:
/// 1. Document Preview & Metadata
/// 2. Essential Options (Compression Presets, Page Selection, Merge Order, Split Modes, Rotation)
/// 3. Execution Bar with single dominant Primary Action (#C74634)
public struct PDFOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            // 1. File Information Header with Real PDF Thumbnail
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: LiquidGlass.spaceMD) {
                    PDFPageThumbnailView(
                        url: first.url,
                        pageIndex: 0,
                        pageNumber: 1,
                        isSelected: false,
                        rotationAngle: viewModel.activeCommand?.id == "pdf.rotate" ? viewModel.rotationSelection : 0,
                        size: CGSize(width: 38, height: 48),
                        showPageLabel: false,
                        onTap: {
                            QuickLookManager.shared.toggle(url: first.url)
                        }
                    )

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

                    Button {
                        QuickLookManager.shared.toggle(url: first.url)
                    } label: {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                            .padding(6)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Look preview (Space)")

                    if viewModel.droppedFiles.count > 1 {
                        GlassPill("\(viewModel.droppedFiles.count) documents", style: .accent)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
            }

            // 2. Specific Configuration per Command
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

            // 3. Execution Bar / Status Indicators
            if viewModel.isProcessing || viewModel.errorMessage != nil {
                HStack(spacing: LiquidGlass.spaceMD) {
                    if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(.linear)
                                .frame(maxWidth: 140)
                            Text("Processing locally...")
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
                }
            }
        }
        .padding(LiquidGlass.spaceLG)
    }

    private var actionTitle: String {
        switch viewModel.activeCommand?.id {
        case "pdf.compress": return "Compress PDF"
        case "pdf.merge": return "Merge PDFs"
        case "pdf.split": return "Split PDF"
        case "pdf.toImage": return "Export Images"
        case "pdf.rotate": return "Rotate PDF"
        case "pdf.extractPages": return "Extract Pages"
        case "pdf.removePages", "pdf.managePages": return "Remove Pages"
        case "pdf.reorderPages": return "Reorder Pages"
        default: return "Process Now"
        }
    }

    // MARK: - Option Subviews

    private var compressPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Optimization Preset")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: LiquidGlass.spaceSM) {
                ForEach(CompressionPreset.allCases) { preset in
                    let isSelected = viewModel.pdfSettings.compressionPreset == preset

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(preset.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? LiquidGlass.brandAccent : Color.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LiquidGlass.brandAccent)
                                    .font(.system(size: 11))
                            }
                        }

                        Text(preset == .light ? "Optimizes streams while maintaining original image resolution." : "Downsamples embedded photos to \(Int(preset.pdfTargetDPI)) DPI.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? LiquidGlass.brandAccent.opacity(0.12) : Color.primary.opacity(0.04))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(isSelected ? LiquidGlass.brandAccent.opacity(0.40) : Color.primary.opacity(0.06), lineWidth: isSelected ? 1.0 : 0.5)
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.pdfSettings.compressionPreset = preset
                    }
                }
            }
        }
    }

    private var mergePDFOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Documents to Merge")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(viewModel.droppedFiles.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .monospacedDigit()
                            Text(item.filename)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.pageCount ?? 0) pages")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.04)))
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 110)

            LabeledContent {
                TextField("merged-document.pdf", text: $viewModel.customOutputFilename)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("Output Filename:")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var splitPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
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
                        .foregroundStyle(Color.secondary)
                }
            } else {
                Text("Every page will be extracted into a separate standalone PDF document.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var pdfToImageOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image Format")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                    Picker("Format", selection: $viewModel.pdfSettings.pdfToImageFormat) {
                        Text("PNG (Lossless)").tag(ImageFormat.png)
                        Text("JPEG (Compact)").tag(ImageFormat.jpeg)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Render Resolution")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
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
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            HStack {
                Text("Rotation Angle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("\(viewModel.rotationSelection)°")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(LiquidGlass.brandAccent)
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
                    HStack(spacing: 10) {
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
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var extractPagesOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            HStack {
                Text("Select Pages to Extract")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("\(viewModel.selectedPageIndices.count) selected")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(LiquidGlass.brandAccent)
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
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var removePagesOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            HStack {
                Text("Select Pages to Remove")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("\(viewModel.selectedPageIndices.count) marked for deletion")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.red)
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
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var reorderPagesOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Reorder Pages (Use arrows to reposition)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

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
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
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
