import SwiftUI
import AppKit

public struct ImageOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Selected File Information Card (Screen 4 reference)
            fileSelectionCard

            // Specific Configuration per command
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let cmd = viewModel.activeCommand {
                        switch cmd.id {
                        case "image.compress":
                            compressOptionsView
                        case "image.convert", "image.formatConverter":
                            convertOptionsView
                        case "image.resize":
                            resizeOptionsView
                        case "image.crop":
                            cropOptionsView
                        case "image.rotate":
                            rotateOptionsView
                        case "image.watermark":
                            watermarkOptionsView
                        case "image.removeBg":
                            removeBgOptionsView
                        case "image.heicToJpg":
                            heicToJpgOptionsView
                        case "image.toPDF":
                            imagesToPDFOptionsView
                        case "image.batch":
                            batchOptionsView
                        default:
                            compressOptionsView
                        }
                    }

                    // Output Location Section (Screen 4 reference)
                    outputLocationSection
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 4)

            // Execution / Action Bar (Screen 4 reference: Reset on left, Action on right)
            bottomActionBar
        }
        .padding(16)
    }

    // MARK: - Selected File Preview Card

    @ViewBuilder
    private var fileSelectionCard: some View {
        if let first = viewModel.droppedFiles.first {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Thumbnail
                    ImageThumbnailView(url: first.url, maxPixelSize: 120, cornerRadius: 6)
                        .frame(width: 52, height: 52)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(SubtleTheme.cardBorder, lineWidth: 0.5)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(viewModel.droppedFiles.count) file\(viewModel.droppedFiles.count > 1 ? "s" : "") selected")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SubtleTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text(first.filename)
                                .lineLimit(1)
                            Text("•")
                            Text(first.formattedFileSize)
                            if let dims = first.imageDimensions {
                                Text("•")
                                Text("\(Int(dims.width)) × \(Int(dims.height))")
                            }
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(SubtleTheme.textSecondary)
                        .monospacedDigit()
                    }

                    Spacer()

                    Button {
                        QuickLookManager.shared.toggle(url: first.url)
                    } label: {
                        Image(systemName: "eye")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SubtleTheme.textSecondary)
                            .padding(6)
                            .background(Circle().fill(SubtleTheme.pillBackground))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Look preview (Space)")
                }

                // Action links: Add More Files / Clear All
                HStack {
                    Button {
                        viewModel.openFilePicker()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add More Files")
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
                .padding(.top, 2)
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
        } else {
            // Empty State Dropzone inside tool
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SubtleTheme.blueTint)
                        .frame(width: 44, height: 44)
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundStyle(SubtleTheme.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("No image selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SubtleTheme.textPrimary)
                    Text("Drop an image or choose one to begin")
                        .font(.system(size: 11))
                        .foregroundStyle(SubtleTheme.textSecondary)
                }

                Spacer()

                GlassButton("Choose File...", icon: "folder", variant: .secondary, size: .small) {
                    viewModel.openFilePicker()
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
        }
    }

    // MARK: - Compression Options (Screen 4 Reference)

    private var compressOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preset Label & 4 Segments
            Text("Compression Preset")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                presetCard(title: "Light", subtitle: "Small size", preset: .light)
                presetCard(title: "Balanced", subtitle: "Good quality", preset: .balanced)
                presetCard(title: "Maximum", subtitle: "Smallest size", preset: .maximum)
                customPresetCard(title: "Custom", subtitle: "Set manually")
            }

            // Output Format Dropdown
            Text("Output Format")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            Menu {
                Button("Keep Original (JPG)") {
                    viewModel.imageOutputFormatSelection = "Keep Original (JPG)"
                }
                Button("JPEG (.jpg)") {
                    viewModel.imageOutputFormatSelection = "JPEG (.jpg)"
                    viewModel.imageSettings.format = .jpeg
                }
                Button("PNG (.png)") {
                    viewModel.imageOutputFormatSelection = "PNG (.png)"
                    viewModel.imageSettings.format = .png
                }
                Button("HEIC (.heic)") {
                    viewModel.imageOutputFormatSelection = "HEIC (.heic)"
                    viewModel.imageSettings.format = .heic
                }
                Button("WebP (.webp)") {
                    viewModel.imageOutputFormatSelection = "WebP (.webp)"
                    viewModel.imageSettings.format = .webp
                }
            } label: {
                HStack {
                    Text(viewModel.imageOutputFormatSelection)
                        .font(.system(size: 12, weight: .regular))
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

    private func presetCard(title: String, subtitle: String, preset: CompressionPreset) -> some View {
        let isSelected = (viewModel.imageSettings.compressionPreset == preset)
        return Button {
            withAnimation(LiquidGlass.quickSpring) {
                viewModel.imageSettings.compressionPreset = preset
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : SubtleTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : SubtleTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SubtleTheme.accentGradient)
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SubtleTheme.cardBackgroundSubtle)
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func customPresetCard(title: String, subtitle: String) -> some View {
        Button {
            // custom preset selection
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SubtleTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(SubtleTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(SubtleTheme.cardBackgroundSubtle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Output Location Section (Screen 4 Reference)

    private var outputLocationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Output Location")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                // Folder Location Selector
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

                // Browse Folder Icon Button
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
                .help("Select custom output destination")
            }
        }
    }

    // MARK: - Additional Image Options

    private var convertOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Format")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(ImageFormat.allCases) { format in
                    GlassButton(
                        format.rawValue,
                        variant: viewModel.imageSettings.format == format ? .primary : .secondary,
                        size: .regular
                    ) {
                        viewModel.imageSettings.format = format
                    }
                }
            }
        }
    }

    private var resizeOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Mode", selection: $viewModel.resizeTab) {
                Text("Exact").tag(0)
                Text("Max Width").tag(1)
                Text("Max Height").tag(2)
                Text("Scale %").tag(3)
            }
            .pickerStyle(.segmented)

            if viewModel.resizeTab == 0 {
                HStack(spacing: 10) {
                    TextField("Width", text: $viewModel.exactWidth)
                        .textFieldStyle(.roundedBorder)
                    TextField("Height", text: $viewModel.exactHeight)
                        .textFieldStyle(.roundedBorder)
                }
            } else if viewModel.resizeTab == 3 {
                HStack {
                    Slider(value: $viewModel.resizePercentage, in: 10...100, step: 5)
                    Text("\(Int(viewModel.resizePercentage))%")
                        .font(.system(size: 12))
                        .monospacedDigit()
                }
            }
        }
    }

    private var cropOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aspect Ratio Preset")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(["1:1 Square", "4:3 Standard", "16:9 Widescreen", "3:2 Classic"], id: \.self) { ratio in
                    GlassButton(
                        ratio,
                        variant: viewModel.cropAspectRatio == ratio ? .primary : .secondary,
                        size: .small
                    ) {
                        viewModel.cropAspectRatio = ratio
                    }
                }
            }
        }
    }

    private var rotateOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rotation Angle")
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

    private var watermarkOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Watermark Text")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            TextField("Confidential", text: $viewModel.watermarkText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Opacity: \(Int(viewModel.watermarkOpacity * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(SubtleTheme.textSecondary)
                Slider(value: $viewModel.watermarkOpacity, in: 0.1...1.0, step: 0.05)
            }
        }
    }

    private var removeBgOptionsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Remove Background")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
            Text("Extracts subjects with a clean edge and produces a transparent PNG file.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textTertiary)
        }
    }

    private var heicToJpgOptionsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Convert Apple HEIC to standard JPEG")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
            Text("Fast 1-click lossless/high-quality transcode for cross-platform compatibility.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textTertiary)
        }
    }

    private var imagesToPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Combine Images into Multi-Page PDF")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)

            Picker("Page Size", selection: $viewModel.pdfSettings.imageToPDFPageSize) {
                ForEach(PDFPageSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var batchOptionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Batch Processing (\(viewModel.droppedFiles.count) files)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SubtleTheme.textPrimary)
            Text("Applies the current configuration to all loaded files sequentially.")
                .font(.system(size: 11))
                .foregroundStyle(SubtleTheme.textSecondary)
        }
    }

    // MARK: - Bottom Action Bar (Screen 4 Reference)

    private var bottomActionBar: some View {
        HStack {
            // Reset Button on Left
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

            // Primary Compress / Action Button on Right
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
        case "image.compress": return "Compress"
        case "image.resize": return "Resize"
        case "image.crop": return "Crop"
        case "image.rotate": return "Rotate"
        case "image.watermark": return "Watermark"
        case "image.removeBg": return "Remove Background"
        case "image.heicToJpg": return "Convert to JPG"
        case "image.toPDF": return "Make PDF"
        default: return "Process"
        }
    }
}
