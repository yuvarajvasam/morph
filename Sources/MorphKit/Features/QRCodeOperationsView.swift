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
        VStack(alignment: .leading, spacing: LiquidGlass.spaceMD) {
            if isScan {
                scannerView
            } else if isBarcode {
                barcodeGeneratorView
            } else {
                qrGeneratorView
            }

            Spacer(minLength: 4)

            // Status Indicators
            if viewModel.isProcessing || viewModel.errorMessage != nil {
                HStack(spacing: LiquidGlass.spaceMD) {
                    if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Exporting vector / image...")
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
        .onAppear {
            updateLivePreview()
            if isScan, let first = viewModel.droppedFiles.first {
                runScan(url: first.url)
            }
        }
    }

    // MARK: - QR Generator View

    private var qrGeneratorView: some View {
        HStack(alignment: .top, spacing: LiquidGlass.spaceLG) {
            // Left Controls
            VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
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
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Website URL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("https://example.com", text: $viewModel.qrTextContent)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .text:
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Text Payload")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextEditor(text: $viewModel.qrTextContent)
                                .font(.system(size: 12))
                                .frame(height: 52)
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .wifi:
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Network SSID")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("Network Name", text: $viewModel.qrWifiSSID)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrWifiSSID) { _, _ in updateLivePreview() }

                            Text("Password")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            SecureField("Wi-Fi Password", text: $viewModel.qrWifiPassword)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrWifiPassword) { _, _ in updateLivePreview() }
                        }

                    case .email:
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Email Address")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("name@domain.com", text: $viewModel.qrTextContent)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .phone:
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Phone Number")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("+1 555 123 4567", text: $viewModel.qrTextContent)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }

                    case .vcard:
                        VStack(alignment: .leading, spacing: 3) {
                            Text("vCard Data")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("Name and Contact Details", text: $viewModel.qrTextContent)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                                .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
                        }
                    }
                }

                // Options Row: Error correction and export format
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Error Correction")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                        Picker("", selection: $viewModel.qrErrorCorrection) {
                            ForEach(QRErrorCorrection.allCases) { ec in
                                Text(ec.rawValue).tag(ec)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: viewModel.qrErrorCorrection) { _, _ in updateLivePreview() }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Export Format")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary)
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
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 136, height: 136)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)

                    if let preview = viewModel.qrLivePreviewImage {
                        Image(nsImage: preview)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    } else {
                        ProgressView()
                    }
                }

                Text("Live Vector Preview")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 144)
        }
    }

    // MARK: - Barcode Generator View

    private var barcodeGeneratorView: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Code 128 Payload (ASCII)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                TextField("Enter barcode text or serial number...", text: $viewModel.barcodeContent)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: viewModel.barcodeContent) { _, _ in updateLivePreview() }
            }

            // Preview
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .frame(height: 84)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                        }

                    if let preview = viewModel.qrLivePreviewImage {
                        Image(nsImage: preview)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 68)
                            .padding(.horizontal, 16)
                    } else {
                        Text("Enter ASCII text to render barcode")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Text(viewModel.barcodeContent)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }

            // Export format
            HStack(spacing: 12) {
                Text("Export Format:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)

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
        VStack(alignment: .leading, spacing: LiquidGlass.spaceSM) {
            if let first = viewModel.droppedFiles.first {
                HStack(spacing: LiquidGlass.spaceMD) {
                    ImageThumbnailView(url: first.url, maxPixelSize: 100, cornerRadius: 6)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(first.filename)
                            .font(.system(size: 13, weight: .semibold))
                        Text("Scanning local image with CoreImage / Vision...")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    if viewModel.isScanningQR {
                        ProgressView().controlSize(.small)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))

                if let result = viewModel.qrScanResultText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Decoded Payload:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary)

                        Text(result)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
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
                        .padding(.top, 2)
                    }
                } else if !viewModel.isScanningQR {
                    Text("No QR code or barcode found in this image.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 4)
                }
            } else {
                Text("Drag and drop an image with a QR code or barcode to scan.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
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
