import SwiftUI

public struct ImageOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // File Information Card with Real Image Thumbnail
            if let first = viewModel.droppedFiles.first {
                GlassCard {
                    HStack(spacing: 12) {
                        // Real Asynchronous Image Thumbnail
                        ImageThumbnailView(url: first.url, maxPixelSize: 140, cornerRadius: 8)
                            .frame(width: 58, height: 58)

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
                            GlassPill("+\(viewModel.droppedFiles.count - 1) more", style: .accent)
                        }
                    }
                    .padding(10)
                }
            }

            // Specific Configuration per command
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
                    applyResizeSettingsIfApplicable()
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

    private var compressOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compression Preset")
                .font(.figmaCallout(emphasized: true))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(CompressionPreset.allCases) { preset in
                    GlassCard(isSelected: viewModel.imageSettings.compressionPreset == preset) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(preset.rawValue)
                                    .font(.figmaHeadline)
                                Spacer()
                                if viewModel.imageSettings.compressionPreset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .symbolEffect(.bounce, value: viewModel.imageSettings.compressionPreset)
                                        .font(.system(size: 12))
                                }
                            }

                            Text(preset.description)
                                .font(.figmaSubheadline())
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                    }
                    .onTapGesture {
                        viewModel.imageSettings.compressionPreset = preset
                    }
                }
            }
        }
    }

    private var convertOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Format")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(ImageFormat.allCases) { format in
                    GlassButton(
                        format.rawValue,
                        variant: viewModel.imageSettings.format == format ? .primary : .secondary
                    ) {
                        viewModel.imageSettings.format = format
                    }
                }
            }

            if let first = viewModel.droppedFiles.first, first.hasAlpha == true && !viewModel.imageSettings.format.supportsAlpha {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                    Text("Warning: \(viewModel.imageSettings.format.rawValue) does not support transparency. Alpha pixels will be flattened to white.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.12)))
            }
        }
    }

    private var resizeOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent {
                        TextField("Height", text: $viewModel.exactHeight)
                            .textFieldStyle(.roundedBorder)
                    } label: {
                        Text("Height (px)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.resizeTab == 2 {
                LabeledContent {
                    TextField("Max Height", text: $viewModel.maxHeight)
                        .textFieldStyle(.roundedBorder)
                } label: {
                    Text("Maximum Height (px)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.resizeTab == 3 {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent {
                        Text("\(Int(viewModel.resizePercentage))%")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                    } label: {
                        Text("Scale Factor")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.resizePercentage, in: 10...100, step: 5)
                }
            }
        }
    }

    private var imagesToPDFOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Page Sizing")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

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
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var batchOptionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Batch Operation")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Picker("Compression Preset", selection: $viewModel.imageSettings.compressionPreset) {
                ForEach(CompressionPreset.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)

            Text("All \(viewModel.droppedFiles.count) images will be processed sequentially to preserve system memory.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
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
