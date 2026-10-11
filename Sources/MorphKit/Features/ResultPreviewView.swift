import SwiftUI

/// Unified Result Preview Screen (Layer B Content Surface) conforming to macOS HIG:
/// - Real metrics & savings reporting
/// - Interactive before/after split slider for image comparisons
/// - Drag-and-drop out to Desktop / Finder
/// - Clear outcome actions (Reveal in Finder ⌘R, Open ⌘O, Share, Save As)
public struct ResultPreviewView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let result: ConversionResult

    public init(viewModel: LauncherViewModel, result: ConversionResult) {
        self.viewModel = viewModel
        self.result = result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                        .font(.system(size: 15))
                    Text("Operation Complete")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                if let copyMsg = viewModel.copyStatusMessage {
                    GlassPill(copyMsg, icon: "checkmark", style: .success)
                        .transition(.opacity)
                } else if result.isOutputLargerThanOriginal {
                    GlassPill(result.formattedSavingsText, icon: "info.circle", style: .warning)
                } else if result.bytesSaved > 0 {
                    GlassPill(result.formattedSavingsText, icon: "arrow.down", style: .success)
                }
            }

            // Stats Summary Card
            HStack(spacing: LiquidGlass.spaceLG) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Original")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text(result.formattedOriginalSize)
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .font(.system(size: 11))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Output")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text(result.formattedOutputSize)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(result.isOutputLargerThanOriginal ? Color.orange : Color.green)
                        .monospacedDigit()
                }

                Spacer()

                if let outDims = result.outputDimensions {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Dimensions")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                        Text("\(Int(outDims.width)) × \(Int(outDims.height))")
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Format")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text(result.outputFormat)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))

            // Notes if any
            if let note = result.notes {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 11))
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 2)
            }

            // Interactive Preview for Images
            if let primaryURL = result.primaryOutputURL, isImage(url: primaryURL) {
                GlassComparisonView(
                    originalURL: result.originalURL,
                    processedURL: primaryURL,
                    originalDimensions: result.originalDimensions,
                    processedDimensions: result.outputDimensions
                )
                .frame(height: 180)
                .onDrag {
                    NSItemProvider(object: primaryURL as NSURL)
                }
                .help("Drag to compare before/after, or drag out to Finder/Desktop")
            } else if result.outputURLs.count > 1 {
                // List of created files for batch / split / PDF to Image
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Generated \(result.outputURLs.count) files:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                        Spacer()
                        Text("Drag any file out to Desktop")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }

                    ScrollView {
                        VStack(spacing: 3) {
                            ForEach(result.outputURLs, id: \.self) { url in
                                HStack {
                                    Image(systemName: "doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.secondary)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        QuickLookManager.shared.toggle(url: url)
                                    } label: {
                                        Image(systemName: "eye")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Quick Look preview (Space)")

                                    Button("Open") {
                                        viewModel.openFile(url: url)
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(LiquidGlass.brandAccent)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.primary.opacity(0.04)))
                                .onDrag {
                                    NSItemProvider(object: url as NSURL)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 130)
                }
            } else if let primaryURL = result.primaryOutputURL {
                // Single PDF or non-image result file card with drag-out
                HStack(spacing: 12) {
                    PDFPageThumbnailView(
                        url: primaryURL,
                        pageIndex: 0,
                        pageNumber: 1,
                        onTap: {
                            QuickLookManager.shared.toggle(url: primaryURL)
                        }
                    )
                    .frame(width: 44, height: 58)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(primaryURL.lastPathComponent)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text("Ready to drag to Desktop, reveal in Finder, or save")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Button {
                        QuickLookManager.shared.toggle(url: primaryURL)
                    } label: {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                            .padding(6)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Look preview (Space)")
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
                .onDrag {
                    NSItemProvider(object: primaryURL as NSURL)
                }
            }

            Spacer(minLength: 4)

            // Actions Bar with native ShareLink, Finder, and Launcher actions
            HStack(spacing: 8) {
                GlassButton("Done", icon: "checkmark", shortcutBadge: "⎋", variant: .secondary) {
                    viewModel.clearAll()
                }

                GlassButton("Another", icon: "plus", variant: .secondary) {
                    viewModel.convertAnother()
                }

                Spacer()

                if let primaryURL = result.primaryOutputURL {
                    ShareLink(item: primaryURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                            Text("Share")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Share processed file via AirDrop, Mail, or Messages")

                    GlassButton("Save As…", icon: "arrow.down.doc", variant: .secondary) {
                        viewModel.saveOutputAs(url: primaryURL)
                    }

                    GlassButton("Finder", icon: "folder", shortcutBadge: "⌘R", variant: .secondary) {
                        viewModel.revealInFinder(url: primaryURL)
                    }

                    GlassButton("Open", icon: "arrow.up.right", shortcutBadge: "⌘O", variant: .primary) {
                        viewModel.openFile(url: primaryURL)
                    }
                }
            }
        }
        .padding(LiquidGlass.spaceLG)
    }

    private func isImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "webp"].contains(ext)
    }
}
