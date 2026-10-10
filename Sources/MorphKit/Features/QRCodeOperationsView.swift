import SwiftUI
import AppKit

public struct QRCodeOperationsView: View {
    @ObservedObject var viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    private var isScan: Bool {
        viewModel.activeCommand?.id == "qr.scan"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if isScan {
                        scannerView
                    } else {
                        // Screen 7: Generate QR Code View
                        qrGeneratorWorkflowView
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 4)

            // Execution / Action Bar (Screen 7: Reset on left, Generate on right)
            bottomActionBar
        }
        .padding(16)
        .onAppear {
            updateLivePreview()
        }
    }

    // MARK: - Screen 7: Generate QR Code View

    private var qrGeneratorWorkflowView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type Selector Segmented Tabs (Text, URL, Wi-Fi, Contact, Email)
            HStack(spacing: 6) {
                typeTabButton(title: "Text", type: .text)
                typeTabButton(title: "URL", type: .url)
                typeTabButton(title: "Wi-Fi", type: .wifi)
                typeTabButton(title: "Contact", type: .vcard)
                typeTabButton(title: "Email", type: .email)
            }

            // Input Content Field
            VStack(alignment: .leading, spacing: 6) {
                Text(inputContentTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SubtleTheme.textSecondary)

                if viewModel.qrContentType == .wifi {
                    HStack(spacing: 8) {
                        TextField("SSID", text: $viewModel.qrWifiSSID)
                            .textFieldStyle(.plain)
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
                        SecureField("Password", text: $viewModel.qrWifiPassword)
                            .textFieldStyle(.plain)
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
                } else {
                    TextField("https://morph.app", text: $viewModel.qrTextContent)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(SubtleTheme.textPrimary)
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
            }
            .onChange(of: viewModel.qrTextContent) { _, _ in updateLivePreview() }
            .onChange(of: viewModel.qrWifiSSID) { _, _ in updateLivePreview() }
            .onChange(of: viewModel.qrWifiPassword) { _, _ in updateLivePreview() }

            // QR Code Preview Box (Screen 7 Reference)
            VStack(alignment: .leading, spacing: 6) {
                Text("QR Code Preview")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SubtleTheme.textSecondary)

                ZStack(alignment: .topTrailing) {
                    // Preview box with centered QR code
                    VStack {
                        if let img = viewModel.qrLivePreviewImage {
                            Image(nsImage: img)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                        } else {
                            ProgressView()
                                .frame(width: 140, height: 140)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SubtleTheme.cardBackgroundSubtle)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                            }
                    }

                    // Download button at top right
                    Button {
                        viewModel.copyOutputToClipboard()
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SubtleTheme.textSecondary)
                            .padding(6)
                            .background(Circle().fill(SubtleTheme.surfaceHover))
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .help("Download / Copy QR Image")
                }
            }

            // Dropdowns row: Size & Error Correction (Screen 7 Reference)
            HStack(spacing: 12) {
                // Size Dropdown
                VStack(alignment: .leading, spacing: 6) {
                    Text("Size")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SubtleTheme.textSecondary)

                    Menu {
                        Button("256 × 256 px") { viewModel.qrPixelSize = 256; updateLivePreview() }
                        Button("512 × 512 px") { viewModel.qrPixelSize = 512; updateLivePreview() }
                        Button("1024 × 1024 px") { viewModel.qrPixelSize = 1024; updateLivePreview() }
                    } label: {
                        HStack {
                            Text("\(Int(viewModel.qrPixelSize)) × \(Int(viewModel.qrPixelSize)) px")
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
                    }
                    .menuStyle(.borderlessButton)
                }

                // Error Correction Dropdown
                VStack(alignment: .leading, spacing: 6) {
                    Text("Error Correction")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SubtleTheme.textSecondary)

                    Menu {
                        Button("Low (L)") { viewModel.qrErrorCorrection = .low; updateLivePreview() }
                        Button("Medium (M)") { viewModel.qrErrorCorrection = .medium; updateLivePreview() }
                        Button("Quartile (Q)") { viewModel.qrErrorCorrection = .quartile; updateLivePreview() }
                        Button("High (H)") { viewModel.qrErrorCorrection = .high; updateLivePreview() }
                    } label: {
                        HStack {
                            Text(viewModel.qrErrorCorrection.displayName)
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
                    }
                    .menuStyle(.borderlessButton)
                }
            }
        }
    }

    private func typeTabButton(title: String, type: QRContentType) -> some View {
        let isSelected = (viewModel.qrContentType == type)
        return Button {
            withAnimation(LiquidGlass.quickSpring) {
                viewModel.qrContentType = type
                updateLivePreview()
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : SubtleTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SubtleTheme.accentGradient)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SubtleTheme.cardBackgroundSubtle)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(SubtleTheme.cardBorder, lineWidth: 0.6)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var inputContentTitle: String {
        switch viewModel.qrContentType {
        case .text: return "Text Content"
        case .url: return "URL Content"
        case .wifi: return "Wi-Fi Configuration"
        case .email: return "Email Address"
        case .vcard: return "Contact Name"
        case .phone: return "Phone Number"
        }
    }

    // MARK: - Scanner Subview

    private var scannerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scan QR Code or Barcode from dropped image")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SubtleTheme.textSecondary)
        }
    }

    // MARK: - Bottom Action Bar (Screen 7 Reference)

    private var bottomActionBar: some View {
        HStack {
            Button {
                viewModel.resetCurrentTool()
                updateLivePreview()
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
                Text("Generating...")
                    .font(.system(size: 12))
                    .foregroundStyle(SubtleTheme.textSecondary)
            }

            Button {
                Task {
                    await viewModel.runActiveCommand()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 12))
                    Text("Generate")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
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
            .disabled(viewModel.isProcessing)
        }
        .padding(.top, 4)
    }

    private func updateLivePreview() {
        Task {
            do {
                let payload = viewModel.formattedQRPayload
                let cg = try QRCodeEngine.shared.generateQRCode(
                    message: payload.isEmpty ? "https://morph.app" : payload,
                    errorCorrection: viewModel.qrErrorCorrection,
                    pixelSize: viewModel.qrPixelSize
                )
                let nsImg = NSImage(cgImage: cg, size: NSSize(width: 140, height: 140))
                await MainActor.run {
                    viewModel.qrLivePreviewImage = nsImg
                }
            } catch {
                // Ignore preview errors during typing
            }
        }
    }
}
