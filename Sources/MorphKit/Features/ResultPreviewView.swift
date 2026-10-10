import SwiftUI
import AppKit

/// Raycast-style Detail View for Operation Results (matching image-16.png, image-12.png)
public struct ResultPreviewView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let result: ConversionResult

    public init(viewModel: LauncherViewModel, result: ConversionResult) {
        self.viewModel = viewModel
        self.result = result
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Split Detail Area (image-16.png layout)
            HStack(alignment: .top, spacing: 0) {
                // LEFT PANE: Visual Preview & Result Content
                VStack(alignment: .leading, spacing: 12) {
                    // Header Bar inside detail
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 16, weight: .semibold))
                        Text(result.primaryOutputURL?.lastPathComponent ?? "Processed File")
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        if let copyMsg = viewModel.copyStatusMessage {
                            GlassPill(copyMsg, icon: "checkmark", style: .success)
                        }
                    }

                    // Content preview
                    if let primaryURL = result.primaryOutputURL, isImage(url: primaryURL) {
                        GlassComparisonView(
                            originalURL: result.originalURL,
                            processedURL: primaryURL,
                            originalDimensions: result.originalDimensions,
                            processedDimensions: result.outputDimensions
                        )
                        .frame(minHeight: 180, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.8)
                        }
                        .onDrag {
                            NSItemProvider(object: primaryURL as NSURL)
                        }
                        .help("Drag slider to compare before/after, or drag image out to Desktop")
                    } else if result.outputURLs.count > 1 {
                        // Multi-file batch/split generated files list
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Generated \(result.outputURLs.count) files (drag out to Finder):")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)

                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(result.outputURLs, id: \.self) { url in
                                        HStack(spacing: 8) {
                                            Image(systemName: "doc.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.accentColor)
                                            Text(url.lastPathComponent)
                                                .font(.system(size: 11, weight: .medium))
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
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.accentColor)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.quaternary))
                                        .onDrag {
                                            NSItemProvider(object: url as NSURL)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 190)
                        }
                    } else if let primaryURL = result.primaryOutputURL {
                        // Single document/archive preview
                        HStack(spacing: 14) {
                            if primaryURL.pathExtension.lowercased() == "pdf" {
                                PDFPageThumbnailView(url: primaryURL, pageIndex: 0, pageNumber: 1, onTap: {
                                    QuickLookManager.shared.toggle(url: primaryURL)
                                })
                                .frame(width: 70, height: 95)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.orange.opacity(0.18))
                                        .frame(width: 70, height: 70)
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.orange)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(primaryURL.lastPathComponent)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(2)
                                Text("Ready to reveal in Finder, drag to Desktop, or share.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary))
                        .onDrag {
                            NSItemProvider(object: primaryURL as NSURL)
                        }
                    }

                    if let note = result.notes {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(note)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity)

                // Vertical Divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)

                // RIGHT PANE: Raycast Detail.Metadata Sidebar (image-16.png)
                DetailMetadataSection {
                    DetailMetadataLabel(label: "Original Size", value: result.formattedOriginalSize)
                    DetailMetadataLabel(label: "Output Size", value: result.formattedOutputSize)

                    DetailMetadataTagList(
                        label: "Space Saved",
                        tags: [(result.formattedSavingsText, result.isOutputLargerThanOriginal ? Color.orange : Color.green)]
                    )

                    DetailMetadataSeparator()

                    if let dims = result.outputDimensions {
                        DetailMetadataLabel(label: "Dimensions", value: "\(Int(dims.width)) × \(Int(dims.height)) px")
                    }

                    DetailMetadataLabel(label: "Format", value: result.outputFormat)
                    DetailMetadataLabel(label: "Duration", value: String(format: "%.2f s", result.durationSeconds))

                    if let primary = result.primaryOutputURL {
                        DetailMetadataSeparator()
                        DetailMetadataLink(label: "Output Location", title: primary.deletingLastPathComponent().lastPathComponent) {
                            viewModel.revealInFinder(url: primary)
                        }
                    }
                }
                .frame(width: 190)
                .background(.ultraThinMaterial)
            }

            Divider().overlay(.quaternary)

            // FLOATING ACTION BAR (Raycast Bottom Pills: Screenshot 2026-10-10 at 9.02.08 PM)
            HStack {
                // Left Pill
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                    Text("Result Summary")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(.quaternary, lineWidth: 0.8)))

                Spacer()

                // Right Pill
                HStack(spacing: 8) {
                    if let primary = result.primaryOutputURL {
                        Button {
                            viewModel.revealInFinder(url: primary)
                        } label: {
                            HStack(spacing: 4) {
                                Text("Reveal in Finder")
                                    .font(.system(size: 12, weight: .medium))
                                Text("⌘R")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(.quaternary))
                            }
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 1, height: 14)

                        Button {
                            viewModel.openFile(url: primary)
                        } label: {
                            HStack(spacing: 4) {
                                Text("Open")
                                    .font(.system(size: 12, weight: .medium))
                                Text("⌘O")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(RoundedRectangle(cornerRadius: 3).fill(.quaternary))
                            }
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 1, height: 14)
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            viewModel.isShowingActionPanel.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Actions")
                                .font(.system(size: 12, weight: .semibold))
                            Text("⌘K")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.3)))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(.quaternary, lineWidth: 0.8)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private func isImage(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "webp"].contains(ext)
    }
}
