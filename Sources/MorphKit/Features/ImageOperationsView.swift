import SwiftUI

/// Unified Image Operations Screen (Layer B Content Surface) conforming to macOS HIG:
/// Hierarchy:
/// 1. File Preview & Metadata
/// 2. Essential Options (Presets, Dimensions, Format)
/// 3. Advanced Options (Metadata stripping, Aspect ratio)
/// 4. Execution Bar with single dominant Primary Action (#C74634)
public struct ImageOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            // 1. File Information Header with Real Image Thumbnail
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: LiquidGlass.spaceMD) {
                    ImageThumbnailView(url: first.url, maxPixelSize: 140, cornerRadius: 6)
                        .frame(width: 52, height: 52)

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
                        GlassPill("+\(viewModel.droppedFiles.count - 1) more", style: .accent)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
            }

            // 2. Specific Configuration per Command
            if let cmd = viewModel.activeCommand {
                switch cmd.id {
                case "image.compress":
                    compressOptionsView
                case "image.convert":
                    convertOptionsView
                case "image.resize":
                    resizeOptionsView
                case "image.toPDF":
                    imagesToPDFOptionsView
                case "image.batch":
                    batchOptionsView
                default:
                    EmptyView()
                }
            }

            Spacer(minLength: 4)

            // 3. Execution Bar
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

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary) {
                    viewModel.goBack()
                }

                GlassButton(actionTitle, icon: "sparkles", shortcutBadge: "↩", variant: .primary) {
                    applyResizeSettingsIfApplicable()
                    Task {
                        await viewModel.runActiveCommand()
                    }
                }
                .disabled(viewModel.isProcessing)
            }
        }
        .padding(LiquidGlass.spaceLG)
    }

    private var actionTitle: String {
        switch viewModel.activeCommand?.id {
        case "image.compress": return "Compress Image"
        case "image.convert": return "Convert Image"
        case "image.resize": return "Resize Image"
        case "image.toPDF": return "Create PDF"
        case "image.batch": return "Batch Process"
        default: return "Process Now"
        }
    }

    // MARK: - Option Subviews

    private var compressOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Compression Preset")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: LiquidGlass.spaceSM) {
                ForEach(CompressionPreset.allCases) { preset in
                    let isSelected = viewModel.imageSettings.compressionPreset == preset

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

                        Text(preset.description)
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
                        viewModel.imageSettings.compressionPreset = preset
                    }
                }
            }
        }
    }

    private var convertOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Target Format")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 6) {
                ForEach(ImageFormat.allCases) { format in
                    GlassButton(
                        format.rawValue,
                        variant: viewModel.imageSettings.format == format ? .primary : .secondary,
                        size: .small
                    ) {
                        viewModel.imageSettings.format = format
                    }
                }
            }

            if let first = viewModel.droppedFiles.first, first.hasAlpha == true && !viewModel.imageSettings.format.supportsAlpha {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.orange)
                        .font(.system(size: 12))
                    Text("Source has transparency. JPEG will flatten alpha pixels to white.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.10)))
            }
        }
    }

    private var resizeOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Picker("Mode", selection: $viewModel.resizeTab) {
                Text("Exact Dimensions").tag(0)
                Text("Max Width").tag(1)
                Text("Max Height").tag(2)
                Text("Percentage").tag(3)
            }
            .pickerStyle(.segmented)

            if viewModel.resizeTab == 0 {
                HStack(spacing: 12) {
                    LabeledContent {
                        TextField("Width", text: $viewModel.exactWidth)
                            .textFieldStyle(.roundedBorder)
                    } label: {
                        Text("Width (px)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    LabeledContent {
                        TextField("Height", text: $viewModel.exactHeight)
                            .textFieldStyle(.roundedBorder)
                    } label: {
                        Text("Height (px)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                }
                Toggle("Maintain Aspect Ratio", isOn: $viewModel.imageSettings.maintainAspectRatio)
                    .font(.system(size: 12))
                    .toggleStyle(.checkbox)
            } else if viewModel.resizeTab == 1 {
                LabeledContent {
                    TextField("Max Width", text: $viewModel.maxWidth)
                        .textFieldStyle(.roundedBorder)
                } label: {
                    Text("Maximum Width (px)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            } else if viewModel.resizeTab == 2 {
                LabeledContent {
                    TextField("Max Height", text: $viewModel.maxHeight)
                        .textFieldStyle(.roundedBorder)
                } label: {
                    Text("Maximum Height (px)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            } else if viewModel.resizeTab == 3 {
                VStack(alignment: .leading, spacing: 4) {
                    LabeledContent {
                        Text("\(Int(viewModel.resizePercentage))%")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                    } label: {
                        Text("Scale Factor")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                    Slider(value: $viewModel.resizePercentage, in: 10...100, step: 5)
                }
            }
        }
    }

    private var imagesToPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Page Sizing")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            Picker("Page Size", selection: $viewModel.pdfSettings.imageToPDFPageSize) {
                ForEach(PDFPageSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)

            LabeledContent {
                TextField("combined-images.pdf", text: $viewModel.customOutputFilename)
                    .textFieldStyle(.roundedBorder)
            } label: {
                Text("Output Filename:")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var batchOptionsView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            Text("Batch Operation")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)

            Picker("Compression Preset", selection: $viewModel.imageSettings.compressionPreset) {
                ForEach(CompressionPreset.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            Text("All \(viewModel.droppedFiles.count) images will be processed sequentially to preserve system memory.")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
                .monospacedDigit()
        }
    }

    private func applyResizeSettingsIfApplicable() {
        if viewModel.activeCommand?.id == "image.resize" {
            switch viewModel.resizeTab {
            case 0:
                let w = Int(viewModel.exactWidth) ?? 1920
                let h = Int(viewModel.exactHeight) ?? 1080
                viewModel.imageSettings.resizeMode = .exact(width: w, height: h)
            case 1:
                let mw = Int(viewModel.maxWidth) ?? 1920
                viewModel.imageSettings.resizeMode = .maxWidth(mw)
            case 2:
                let mh = Int(viewModel.maxHeight) ?? 1080
                viewModel.imageSettings.resizeMode = .maxHeight(mh)
            case 3:
                viewModel.imageSettings.resizeMode = .percentage(Int(viewModel.resizePercentage))
            default:
                break
            }
        }
    }
}
