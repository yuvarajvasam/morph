import SwiftUI
import AppKit

public struct UniversalOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    private var activeCmd: ConversionCommand? {
        viewModel.activeCommand
    }

    private var missingToolInfo: (toolName: String, command: String)? {
        guard let id = activeCmd?.id else { return nil }
        if id.hasPrefix("video.") || id.hasPrefix("audio.") {
            if EngineManager.shared.findExecutable(named: "ffmpeg") == nil {
                return ("FFmpeg", "brew install ffmpeg")
            }
        } else if id == "office.toPDF" {
            if EngineManager.shared.findLibreOffice() == nil {
                return ("LibreOffice", "brew install --cask libreoffice")
            }
        } else if id == "markdown.toPDF" {
            if EngineManager.shared.findExecutable(named: "pandoc") == nil {
                return ("Pandoc", "brew install pandoc")
            }
        }
        return nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            // Header / Dropped Files Card
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: LiquidGlass.spaceMD) {
                    if let cmd = activeCmd {
                        ToolSquircleIcon(command: cmd, size: 44, cornerRadius: 10)
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
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
            }

            // Missing Tool Notification Card
            if let missing = missingToolInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.yellow)
                            .font(.system(size: 14))

                        Text("\(missing.toolName) Required for This Operation")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }

                    Text("This conversion uses \(missing.toolName). You can install it with one command via Homebrew:")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)

                    HStack {
                        Text(missing.command)
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.black.opacity(0.3)))
                            .foregroundStyle(Color.green)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(missing.command, forType: .string)
                            viewModel.copyStatusMessage = "Copied \(missing.command)"
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.yellow.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.yellow.opacity(0.25), lineWidth: 1)
                        }
                )
            }

            // Command-Specific Controls
            optionsContentView

            Spacer(minLength: 4)

            // Progress and Status
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
                            Text("Processing...")
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

    // MARK: - Options Views

    @ViewBuilder
    private var optionsContentView: some View {
        if let cmd = activeCmd {
            switch cmd.id {
        case "video.convert":
            VStack(alignment: .leading, spacing: 10) {
                Text("Target Video Format")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach(["mp4", "mov", "mkv", "webm"], id: \.self) { fmt in
                        formatPill(fmt.uppercased(), isSelected: viewModel.mediaTargetFormat == fmt) {
                            viewModel.mediaTargetFormat = fmt
                        }
                    }
                }

                Text("Quality Preset")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    ForEach(CompressionPreset.allCases) { preset in
                        formatPill(preset.rawValue, isSelected: viewModel.imageSettings.compressionPreset == preset) {
                            viewModel.imageSettings.compressionPreset = preset
                        }
                    }
                }
            }

        case "video.toGIF":
            VStack(alignment: .leading, spacing: 10) {
                Text("Frame Rate")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach([10, 15, 24, 30], id: \.self) { fps in
                        formatPill("\(fps) FPS", isSelected: viewModel.gifFPS == fps) {
                            viewModel.gifFPS = fps
                        }
                    }
                }

                Text("Width Dimension")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    ForEach([320, 480, 640], id: \.self) { w in
                        formatPill("\(w)px", isSelected: viewModel.gifWidth == w) {
                            viewModel.gifWidth = w
                        }
                    }
                }
            }

        case "video.extractAudio", "audio.convert":
            VStack(alignment: .leading, spacing: 10) {
                Text("Target Audio Format")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach(["mp3", "m4a", "wav", "aac", "flac"], id: \.self) { fmt in
                        formatPill(fmt.uppercased(), isSelected: viewModel.audioTargetFormat == fmt) {
                            viewModel.audioTargetFormat = fmt
                        }
                    }
                }
            }

        case "vector.toImage":
            VStack(alignment: .leading, spacing: 10) {
                Text("Export Scale")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach([1, 2, 4], id: \.self) { s in
                        formatPill("\(s)× Scale", isSelected: Int(viewModel.vectorScale) == s) {
                            viewModel.vectorScale = CGFloat(s)
                        }
                    }
                }

                Text("Image Format")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    ForEach([ImageFormat.png, ImageFormat.jpeg], id: \.self) { fmt in
                        formatPill(fmt.rawValue, isSelected: viewModel.vectorTargetFormat == fmt) {
                            viewModel.vectorTargetFormat = fmt
                        }
                    }
                }
            }

        case "data.convert":
            VStack(alignment: .leading, spacing: 10) {
                Text("Target Data Format")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach(["plist", "json", "csv"], id: \.self) { fmt in
                        formatPill(fmt.uppercased(), isSelected: viewModel.dataTargetFormat == fmt) {
                            viewModel.dataTargetFormat = fmt
                        }
                    }
                }
            }

        case "ocr.imageToText", "ocr.pdfToText":
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cyan)
                    Text("Powered by Apple Vision Neural Engine")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }

                Text("Text will be accurately recognized, copied to your clipboard, and saved as an extracted .txt file.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.cyan.opacity(0.08)))

        case "icon.generateICNS":
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.indigo)
                    Text("macOS Application Icon Bundle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }

                Text("Generates standard Apple .icns file with 16, 32, 64, 128, 256, 512, and 1024px resolutions.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.indigo.opacity(0.08)))

        default:
            EmptyView()
        }
    }
}

    private func formatPill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? LiquidGlass.brandAccent : Color.white.opacity(0.08))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}
