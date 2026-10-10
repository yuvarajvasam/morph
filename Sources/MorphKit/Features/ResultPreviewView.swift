import SwiftUI

public struct ResultPreviewView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let result: ConversionResult

    public init(viewModel: LauncherViewModel, result: ConversionResult) {
        self.viewModel = viewModel
        self.result = result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 16))
                        .symbolEffect(.bounce, value: result.outputURLs.count)
                    Text("Operation Complete")
                        .font(.figmaTitle3(emphasized: true))
                }

                Spacer()

                if let copyMsg = viewModel.copyStatusMessage {
                    GlassPill(copyMsg, icon: "checkmark", style: .success)
                        .transition(.opacity.combined(with: .scale))
                } else if result.isOutputLargerThanOriginal {
                    GlassPill(result.formattedSavingsText, icon: "info.circle", style: .warning)
                } else if result.bytesSaved > 0 {
                    GlassPill(result.formattedSavingsText, icon: "arrow.down", style: .success)
                }
            }

            // Stats Card with Modern Typography & Layout
            GlassCard {
                HStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original")
                            .font(.figmaCaption1(emphasized: true))
                            .foregroundStyle(.secondary)
                        Text(result.formattedOriginalSize)
                            .font(.figmaHeadline)
                            .monospacedDigit()
                    }

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output")
                            .font(.figmaCaption1(emphasized: true))
                            .foregroundStyle(.secondary)
                        Text(result.formattedOutputSize)
                            .font(.figmaHeadline)
                            .foregroundStyle(result.isOutputLargerThanOriginal ? Color.orange : Color.green)
                            .monospacedDigit()
                    }

                    Spacer()

                    if let outDims = result.outputDimensions {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Dimensions")
                                .font(.figmaCaption1(emphasized: true))
                                .foregroundStyle(.secondary)
                            Text("\(Int(outDims.width)) × \(Int(outDims.height))")
                                .font(.figmaHeadline)
                                .monospacedDigit()
                        }
                    }

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Format")
                            .font(.figmaCaption1(emphasized: true))
                            .foregroundStyle(.secondary)
                        Text(result.outputFormat)
                            .font(.figmaHeadline)
                    }
                }
                .padding(14)
            }

            // Notes if any
            if let note = result.notes {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
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
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Generated \(result.outputURLs.count) files:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Spacer()
                        Text("Drag any file out to Desktop")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(result.outputURLs, id: \.self) { url in
                                HStack {
                                    Image(systemName: "doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        QuickLookManager.shared.toggle(url: url)
                                    } label: {
                                        Image(systemName: "eye")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Quick Look preview (Space)")

                                    Button("Open") {
                                        viewModel.openFile(url: url)
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.accentColor)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.quaternary))
                                .onDrag {
                                    NSItemProvider(object: url as NSURL)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxHeight: 130)
                }
            } else if let primaryURL = result.primaryOutputURL {
                // Single PDF or non-image result file card with drag-out
                GlassCard {
                    HStack(spacing: 12) {
                        PDFPageThumbnailView(
                            url: primaryURL,
                            pageIndex: 0,
                            pageNumber: 1,
                            onTap: {
                                QuickLookManager.shared.toggle(url: primaryURL)
                            }
                        )
                        .frame(width: 50, height: 65)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(primaryURL.lastPathComponent)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text("Ready to drag to Desktop, reveal in Finder, or save")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            QuickLookManager.shared.toggle(url: primaryURL)
                        } label: {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(6)
                                .background(Circle().fill(.quaternary))
                        }
                        .buttonStyle(.plain)
                        .help("Quick Look preview (Space)")
                    }
                    .padding(12)
                }
                .onDrag {
                    NSItemProvider(object: primaryURL as NSURL)
                }
            }

            Spacer(minLength: 4)

            // Actions Bar with native ShareLink, Finder, and Launcher actions
            HStack(spacing: 8) {
                GlassButton("Launcher", icon: "arrow.left", shortcutBadge: "⎋", variant: .secondary) {
                    viewModel.clearAll()
                }

                GlassButton("Convert Another", icon: "plus.circle", variant: .secondary) {
                    viewModel.convertAnother()
                }

                Spacer()

                if let primaryURL = result.primaryOutputURL {
                    // Modern SwiftUI ShareLink for native macOS share sheet
                    ShareLink(item: primaryURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                            Text("Share")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Share processed file via AirDrop, Mail, or Messages")

                    GlassButton("Save As...", icon: "arrow.down.doc", variant: .secondary) {
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
        .padding(18)
    }

    private func isImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "webp"].contains(ext)
    }
}
