import SwiftUI
import AppKit

public struct QRCodeOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    private var isBarcode: Bool {
        viewModel.activeCommand?.id == "barcode.generate"
    }

    private var isScan: Bool {
        viewModel.activeCommand?.id == "qr.scan"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if isScan {
                scannerView
            } else if isBarcode {
                barcodeGeneratorView
            } else {
                qrGeneratorView
            }

            Spacer(minLength: 4)

            // Bottom Action Bar
            HStack {
                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LiquidGlass.bridgeTint)
                            .symbolEffect(.pulse)
                        Text("Exporting vector / image...")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }

                Spacer()

                GlassButton("Cancel", shortcutBadge: "⎋", variant: .secondary) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.goBack()
                    }
                }

                if !isScan {
                    GlassButton(
                        "Export \(viewModel.qrExportAsPDF ? "PDF" : "PNG")",
                        icon: "arrow.down.doc.fill",
                        shortcutBadge: "↩",
                        variant: .primary
                    ) {
                        Task {
                            await viewModel.executeCurrentOperation()
                        }
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
        }
        .padding(14)
        .onAppear {
            updateLivePreview()
            if isScan, let first = viewModel.droppedFiles.first {
                runScan(url: first.url)
            }
        }
    }

    // MARK: - QR Generator View

    private var qrGeneratorView: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left Controls
            VStack(alignment: .leading, spacing: 10) {
                // Type Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(QRContentType.allCases) { type in
                            GlassButton(
                                type.rawValue,
                                icon: type.icon,
                                variant: viewModel.qrContentType == type ? .primary : .secondary,
                                size: .small
                            ) {
                                viewModel.qrContentType = type
                                updateLivePreview()
                            }
                        }
                    }
                }

                // Dynamic Input
                Group {
                    switch viewModel.qrContentType {
                    case .url:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Website URL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("https://example.com", text: $viewModel.qrTextContent)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .text:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text Payload")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextEditor(text: $viewModel.qrTextContent)
                                .font(.system(size: 12))
                                .frame(height: 56)
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .wifi:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Network SSID")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("Network Name", text: $viewModel.qrWifiSSID)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrWifiSSID) { _, _ in updateLivePreview() }

                            Text("Password")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            SecureField("Wi-Fi Password", text: $viewModel.qrWifiPassword)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrWifiPassword) { _, _ in updateLivePreview() }
                        }

                    case .email:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("name@domain.com", text: $viewModel.qrTextContent)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .phone:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phone Number")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("+1 555 123 4567", text: $viewModel.qrTextContent)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .vcard:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("vCard Data")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("Name and Contact Details", text: $viewModel.qrTextContent)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }
                    }
                }

                // Options Row: Error correction and export format
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error Correction")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $viewModel.qrErrorCorrection) {
                            ForEach(QRErrorCorrection.allCases) { ec in
                                Text(ec.rawValue).tag(ec)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: viewModel.qrErrorCorrection) { _, _ in updateLivePreview() }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Export Format")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $viewModel.qrExportAsPDF) {
                            Text("PNG Bitmap").tag(false)
                            Text("PDF Vector").tag(true)
                        }
                        .labelsHidden()
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Right: Live QR Preview
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                    if let preview = viewModel.qrLivePreviewImage {
                        Image(nsImage: preview)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 124, height: 124)
                    } else {
                        ProgressView()
                    }
                }

                Text("Live Preview")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 150)
        }
    }

    // MARK: - Barcode Generator View

    private var barcodeGeneratorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Code 128 Payload (ASCII)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Enter barcode text or serial number...", text: $viewModel.barcodeContent)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                    .onChange(of: viewModel.barcodeContent) { _, _ in updateLivePreview() }
            }

            // Preview
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)

                    if let preview = viewModel.qrLivePreviewImage {
                        Image(nsImage: preview)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 74)
                            .padding(.horizontal, 16)
                    } else {
                        Text("Enter ASCII text to render barcode")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(viewModel.barcodeContent)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Export format
            HStack(spacing: 12) {
                Text("Export Format:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Picker("", selection: $viewModel.qrExportAsPDF) {
                    Text("PNG Image").tag(false)
                    Text("PDF Document").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
    }

    // MARK: - Scanner View

    private var scannerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: 12) {
                    ImageThumbnailView(url: first.url, maxPixelSize: 100, cornerRadius: 6)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(first.filename)
                            .font(.system(size: 13, weight: .semibold))
                        Text("Scanning local image with CoreImage / Vision...")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.isScanningQR {
                        ProgressView().controlSize(.small)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

                if let result = viewModel.qrScanResultText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Decoded Payload:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text(result)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                            .textSelection(.enabled)

                        HStack(spacing: 8) {
                            GlassButton("Copy Payload", icon: "doc.on.doc", variant: .primary, size: .small) {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(result, forType: .string)
                            }

                            if let url = URL(string: result), url.scheme == "http" || url.scheme == "https" {
                                GlassButton("Open in Browser", icon: "safari", variant: .secondary, size: .small) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                } else if !viewModel.isScanningQR {
                    Text("No QR code or barcode found in this image.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            } else {
                Text("Drop an image with a QR code or barcode to scan.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func updateLivePreview() {
        Task.detached(priority: .userInitiated) {
            let payload: String
            if await self.isBarcode {
                payload = await self.viewModel.barcodeContent
                guard !payload.isEmpty, let cg = try? QRCodeEngine.shared.generateBarcode(message: payload) else {
                    await MainActor.run { self.viewModel.qrLivePreviewImage = nil }
                    return
                }
                let ns = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
                await MainActor.run { self.viewModel.qrLivePreviewImage = ns }
            } else {
                payload = await self.viewModel.formattedQRPayload
                guard !payload.isEmpty, let cg = try? QRCodeEngine.shared.generateQRCode(
                    message: payload,
                    errorCorrection: await self.viewModel.qrErrorCorrection,
                    pixelSize: 256
                ) else {
                    await MainActor.run { self.viewModel.qrLivePreviewImage = nil }
                    return
                }
                let ns = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
                await MainActor.run { self.viewModel.qrLivePreviewImage = ns }
            }
        }
    }

    private func runScan(url: URL) {
        viewModel.isScanningQR = true
        Task {
            do {
                let payloads = try await QRCodeEngine.shared.scanCode(url: url)
                await MainActor.run {
                    self.viewModel.isScanningQR = false
                    self.viewModel.qrScanResultText = payloads.first
                }
            } catch {
                await MainActor.run {
                    self.viewModel.isScanningQR = false
                    self.viewModel.qrScanResultText = nil
                }
            }
        }
    }
}
