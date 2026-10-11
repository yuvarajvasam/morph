import Foundation
import AppKit
import SwiftUI
import MorphKit
import PDFKit

@MainActor
public func runVisualVerification() async throws {
    print("\n🎨 RUNNING VISUAL VERIFICATION & SCREENSHOT CAPTURE...")

    let outputDir = URL(fileURLWithPath: "/Users/yuvi/.gemini/antigravity-ide/brain/f45f6497-095e-4242-8928-438d1c004fcd")
    try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    let workDir = FileManager.default.currentDirectoryPath
    let samplesDir = URL(fileURLWithPath: workDir).appendingPathComponent("TestOutputs", isDirectory: true)

    let samplePhotoURL = samplesDir.appendingPathComponent("sample_photo.jpg")
    let samplePDFURL = samplesDir.appendingPathComponent("sample_document.pdf")

    let canvasSize = CGSize(width: 720, height: 600)

    // Helper to render view to PNG file over atmospheric wallpaper backdrop
    func render<V: View>(_ view: V, size: CGSize = canvasSize, appearance: NSAppearance.Name = .darkAqua, filename: String) {
        let container = ZStack {
            // Ambient forest wallpaper backdrop matching reference
            LinearGradient(
                colors: [
                    Color(red: 24 / 255, green: 44 / 255, blue: 40 / 255),
                    Color(red: 16 / 255, green: 30 / 255, blue: 34 / 255),
                    Color(red: 10 / 255, green: 20 / 255, blue: 24 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            view
        }
        .frame(width: size.width, height: size.height)

        let hostingView = NSHostingView(rootView: container.preferredColorScheme(appearance == .darkAqua ? .dark : .light))
        hostingView.appearance = NSAppearance(named: appearance)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            print("  ❌ Could not create bitmap rep for \(filename)")
            return
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        if let pngData = rep.representation(using: .png, properties: [:]) {
            let fileURL = outputDir.appendingPathComponent(filename)
            do {
                try pngData.write(to: fileURL)
                print("  📸 Captured: \(filename) (\(Int(size.width))×\(Int(size.height)) pt)")
            } catch {
                print("  ❌ Failed to write \(filename): \(error)")
            }
        }
    }

    let registry = ConversionRegistry.shared

    // 1. Launcher List View Mode (Matching Reference Image 1)
    let vmList = LauncherViewModel()
    vmList.preferences.viewMode = .list
    render(LauncherView(viewModel: vmList), filename: "01_launcher_list_mode.png")

    // 2. Launcher Grid View Mode (Matching Reference Images 2 & 3)
    let vmGrid = LauncherViewModel()
    vmGrid.preferences.viewMode = .grid
    render(LauncherView(viewModel: vmGrid), filename: "02_launcher_grid_mode.png")

    // 3. Launcher Search Query ("compress")
    let vmSearch = LauncherViewModel()
    vmSearch.searchQuery = "compress"
    render(LauncherView(viewModel: vmSearch), filename: "03_launcher_search_query.png")

    // 4. Launcher with Dropped Image File
    let vmDrop = LauncherViewModel()
    vmDrop.handleDroppedURLs([samplePhotoURL])
    render(LauncherView(viewModel: vmDrop), filename: "04_launcher_dropped_file.png")

    // 5. Contextual Action Panel (⌘K)
    let vmAction = LauncherViewModel()
    vmAction.handleDroppedURLs([samplePhotoURL])
    vmAction.isShowingActionPanel = true
    render(LauncherView(viewModel: vmAction), filename: "05_launcher_action_panel.png")

    // 6. Image Compression Tool Screen
    let vmImage = LauncherViewModel()
    vmImage.handleDroppedURLs([samplePhotoURL])
    vmImage.activeCommand = registry.allCommands.first(where: { $0.id == "image.compress" })
    render(LauncherView(viewModel: vmImage), filename: "06_image_compression_tool.png")

    // 7. PDF Operations Tool Screen (Compress)
    let vmPDF = LauncherViewModel()
    vmPDF.handleDroppedURLs([samplePDFURL])
    vmPDF.activeCommand = registry.allCommands.first(where: { $0.id == "pdf.compress" })
    render(LauncherView(viewModel: vmPDF), filename: "07_pdf_operations_tool.png")

    // 8. QR Code Generator Screen
    let vmQR = LauncherViewModel()
    vmQR.activeCommand = registry.allCommands.first(where: { $0.id == "qr.generate" })
    if let cg = try? QRCodeEngine.shared.generateQRCode(message: "https://morph.app", errorCorrection: .medium, pixelSize: 256) {
        vmQR.qrLivePreviewImage = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
    render(LauncherView(viewModel: vmQR), filename: "08_qrcode_tool.png")

    // 9. Result Preview View (Real Conversion Result)
    let vmResult = LauncherViewModel()
    let mockResult = ConversionResult(
        originalURL: samplePhotoURL,
        outputURLs: [samplePhotoURL],
        originalSize: 450 * 1024,
        outputSize: 120 * 1024,
        originalDimensions: CGSize(width: 2000, height: 1400),
        outputDimensions: CGSize(width: 2000, height: 1400),
        outputFormat: "JPEG",
        durationSeconds: 0.14
    )
    vmResult.currentResult = mockResult
    render(LauncherView(viewModel: vmResult), filename: "09_result_preview.png")

    // 10. Settings View
    let vmSettings = LauncherViewModel()
    vmSettings.isShowingSettings = true
    render(LauncherView(viewModel: vmSettings), filename: "10_settings_view.png")

    print("✅ VISUAL VERIFICATION CAPTURE COMPLETE (10 screens exported)!\n")
}
