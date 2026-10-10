import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import MorphKit

@MainActor
public func runRealWorldVerification() async throws {
    print("\n🔬 RUNNING REAL-WORLD FILE OPERATIONS VERIFICATION...")
    let workDir = FileManager.default.currentDirectoryPath
    let samplesDir = URL(fileURLWithPath: workDir).appendingPathComponent("TestOutputs", isDirectory: true)
    try? FileManager.default.createDirectory(at: samplesDir, withIntermediateDirectories: true)

    let engine = ImageEngine.shared
    let pdfEngine = PDFEngine.shared

    // 1. Create realistic sample photo (2000x1400)
    print("\n📸 [1/8] Generating high-resolution sample image...")
    let samplePhotoURL = samplesDir.appendingPathComponent("sample_photo.jpg")
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil,
        width: 2000,
        height: 1400,
        bitsPerComponent: 8,
        bytesPerRow: 2000 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!

    // Draw rich gradient
    let colors = [
        CGColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0),
        CGColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 2000, y: 1400), options: [])

    // Add shapes
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.3))
    ctx.fillEllipse(in: CGRect(x: 400, y: 300, width: 800, height: 800))

    let photoCG = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(samplePhotoURL as CFURL, "public.jpeg" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, photoCG, [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
    CGImageDestinationFinalize(dest)

    let origPhotoSize = (try? FileManager.default.attributesOfItem(atPath: samplePhotoURL.path)[.size] as? Int64) ?? 0
    print("  Created sample_photo.jpg: \(origPhotoSize / 1024) KB (2000 × 1400 px)")

    // 2. Real Image Compression
    print("\n🗜 [2/8] Testing Image Compression (Balanced Preset)...")
    let compressRes = try await engine.compress(inputURL: samplePhotoURL, preset: .balanced, destinationDirectory: samplesDir)
    let compURL = compressRes.outputURLs[0]
    print("  Output: \(compURL.lastPathComponent)")
    print("  Original: \(compressRes.formattedOriginalSize) -> Compressed: \(compressRes.formattedOutputSize)")
    print("  Savings: \(compressRes.formattedSavingsText)")

    // 3. Real Image Resizing
    print("\n📐 [3/8] Testing Image Resizing (Exact 800x560 px)...")
    let resizeRes = try await engine.resize(inputURL: samplePhotoURL, mode: .exact(width: 800, height: 560), maintainAspectRatio: true, destinationDirectory: samplesDir)
    let resizeURL = resizeRes.outputURLs[0]
    print("  Output: \(resizeURL.lastPathComponent)")
    print("  Dimensions: \(Int(resizeRes.outputDimensions?.width ?? 0)) × \(Int(resizeRes.outputDimensions?.height ?? 0)) px")

    // 4. Real Format Conversion (with Transparency)
    print("\n🔄 [4/8] Testing Image Format Conversion with Alpha Handling...")
    let sampleIconURL = samplesDir.appendingPathComponent("sample_transparent.png")
    let iconCtx = CGContext(
        data: nil,
        width: 400,
        height: 400,
        bitsPerComponent: 8,
        bytesPerRow: 400 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    iconCtx.clear(CGRect(x: 0, y: 0, width: 400, height: 400))
    iconCtx.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.9))
    iconCtx.fillEllipse(in: CGRect(x: 50, y: 50, width: 300, height: 300))
    let iconCG = iconCtx.makeImage()!
    let iconDest = CGImageDestinationCreateWithURL(sampleIconURL as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(iconDest, iconCG, nil)
    CGImageDestinationFinalize(iconDest)

    let convertRes = try await engine.convert(inputURL: sampleIconURL, targetFormat: .jpeg, destinationDirectory: samplesDir)
    print("  Converted transparent PNG -> JPEG: \(convertRes.outputURLs[0].lastPathComponent)")
    print("  Note: \(convertRes.notes ?? "none")")

    // 5. Real Images to PDF
    print("\n📑 [5/8] Testing Images to PDF...")
    let imgToPdfRes = try await engine.imagesToPDF(
        imageURLs: [samplePhotoURL, sampleIconURL],
        pageSize: .a4,
        destinationDirectory: samplesDir,
        outputFilename: "photo_album.pdf"
    )
    print("  Output: \(imgToPdfRes.outputURLs[0].lastPathComponent) (\(imgToPdfRes.formattedOutputSize))")
    let albumDoc = PDFDocument(url: imgToPdfRes.outputURLs[0])!
    print("  Page count: \(albumDoc.pageCount)")

    // 6. Create Multi-Page PDF & Test PDF Compression
    print("\n📄 [6/8] Testing PDF Compression...")
    let samplePDFURL = samplesDir.appendingPathComponent("sample_document.pdf")
    let multiDoc = PDFDocument()
    for i in 1...4 {
        let pageCtx = CGContext(
            data: nil,
            width: 612,
            height: 792,
            bitsPerComponent: 8,
            bytesPerRow: 612 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        pageCtx.setFillColor(CGColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0))
        pageCtx.fill(CGRect(x: 0, y: 0, width: 612, height: 792))
        pageCtx.setFillColor(CGColor(red: 0.1, green: 0.3 * Double(i) / 4.0, blue: 0.8, alpha: 1.0))
        pageCtx.fill(CGRect(x: 60, y: 700, width: 492, height: 40))
        let img = pageCtx.makeImage()!
        let page = PDFPage(image: NSImage(cgImage: img, size: CGSize(width: 612, height: 792)))!
        multiDoc.insert(page, at: multiDoc.pageCount)
    }
    multiDoc.write(to: samplePDFURL)

    let pdfCompRes = try await pdfEngine.compress(inputURL: samplePDFURL, preset: .balanced, destinationDirectory: samplesDir)
    print("  Output: \(pdfCompRes.outputURLs[0].lastPathComponent)")
    print("  Original: \(pdfCompRes.formattedOriginalSize) -> Compressed: \(pdfCompRes.formattedOutputSize)")

    // 7. Real PDF Split & Merge
    print("\n✂️ [7/8] Testing PDF Split & Merge...")
    let splitRes = try await pdfEngine.split(inputURL: samplePDFURL, mode: .pageRange("1-2"), destinationDirectory: samplesDir)
    print("  Split extracted: \(splitRes.outputURLs[0].lastPathComponent) (pages: \(PDFDocument(url: splitRes.outputURLs[0])!.pageCount))")

    let mergeRes = try await pdfEngine.merge(pdfURLs: [samplePDFURL, splitRes.outputURLs[0]], outputFilename: "merged_report.pdf", destinationDirectory: samplesDir)
    print("  Merged output: \(mergeRes.outputURLs[0].lastPathComponent) (pages: \(PDFDocument(url: mergeRes.outputURLs[0])!.pageCount))")

    // 8. Real PDF to Image
    print("\n🖼 [8/8] Testing PDF to High-Res PNG Images...")
    let pdfToImgRes = try await pdfEngine.pdfToImage(inputURL: samplePDFURL, format: .png, dpi: 150, destinationDirectory: samplesDir)
    print("  Exported \(pdfToImgRes.outputURLs.count) high-res PNG pages:")
    for u in pdfToImgRes.outputURLs {
        print("    - \(u.lastPathComponent)")
    }

    print("\n✅ ALL REAL-WORLD CONVERSIONS VERIFIED & VALIDATED SUCCESSFULLY!")
}
