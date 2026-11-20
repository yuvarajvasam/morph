import SwiftUI
import AppKit

/// Handcrafted macOS App-style squircle tile icon conforming to the Liquid Glass design reference.
/// Features curated vibrant gradients, crisp specular rim lighting, and white SF symbols.
public struct ToolSquircleIcon: View {
    public let commandId: String
    public let systemIcon: String
    public let size: CGFloat
    public let cornerRadius: CGFloat

    public init(
        commandId: String,
        systemIcon: String,
        size: CGFloat = 48,
        cornerRadius: CGFloat? = nil
    ) {
        self.commandId = commandId
        self.systemIcon = systemIcon
        self.size = size
        self.cornerRadius = cornerRadius ?? (size * 0.25)
    }

    public init(command: ConversionCommand, size: CGFloat = 48, cornerRadius: CGFloat? = nil) {
        self.init(commandId: command.id, systemIcon: command.systemIcon, size: size, cornerRadius: cornerRadius)
    }

    public var body: some View {
        ZStack {
            // Squircle Gradient Fill
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tileGradient)
                .frame(width: size, height: size)
                .overlay {
                    // Specular Top-Edge Rim Highlight
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.38),
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                }
                .shadow(color: Color.black.opacity(0.25), radius: size * 0.08, x: 0, y: size * 0.04)

            // Centered High-Contrast Icon
            Image(systemName: iconName)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 0.5)
        }
        .frame(width: size, height: size)
    }

    private var iconName: String {
        switch commandId {
        case "image.compress": return "arrow.down.right.and.arrow.up.left"
        case "image.convert": return "arrow.triangle.2.circlepath"
        case "image.resize": return "aspectratio"
        case "image.batch": return "square.stack.3d.down.right"
        case "image.toPDF": return "photo.on.rectangle.angled"
        case "pdf.compress": return "doc.badge.arrow.up.fill"
        case "pdf.merge": return "doc.on.doc.fill"
        case "pdf.split": return "scissors"
        case "pdf.toImage": return "doc.viewfinder.fill"
        case "pdf.rotate": return "rotate.right.fill"
        case "pdf.extractPages": return "doc.badge.gearshape.fill"
        case "pdf.removePages": return "trash.fill"
        case "pdf.reorderPages": return "rectangle.stack.fill"
        case "archive.compress": return "archivebox.fill"
        case "archive.extract": return "tray.and.arrow.up.fill"
        case "archive.inspect": return "doc.text.magnifyingglass"
        case "qr.generate": return "qrcode"
        case "qr.scan": return "viewfinder"
        case "barcode.generate": return "barcode.viewfinder"
        case "ocr.imageToText": return "text.viewfinder"
        case "ocr.pdfToText": return "doc.text.viewfinder"
        case "ocr.searchablePDF": return "doc.badge.magnifyingglass"
        case "icon.generateICNS": return "app.dashed"
        case "icon.extractFromICNS": return "arrow.down.app"
        case "vector.toPDF": return "point.topleft.down.to.point.bottomright.curvepath"
        case "vector.toImage": return "photo.artframe"
        case "video.convert": return "video.badge.plus"
        case "video.compress": return "arrow.down.right.and.arrow.up.left.square.fill"
        case "video.toGIF": return "play.square.stack"
        case "video.extractAudio": return "waveform.and.magnifyingglass"
        case "audio.convert": return "waveform"
        case "office.toPDF": return "doc.text.fill"
        case "markdown.toPDF": return "doc.richtext"
        case "data.convert": return "curlybraces"
        case "data.prettify": return "text.alignleft"
        case "metadata.strip": return "eye.slash"
        case "metadata.inspect": return "info.circle.fill"
        default: return systemIcon
        }
    }

    private var tileGradient: LinearGradient {
        let (c1, c2): (Color, Color)
        switch commandId {
        // Images Suite
        case "image.compress":
            c1 = Color(red: 235 / 255, green: 75 / 255, blue: 55 / 255) // Golden Gate Crimson
            c2 = Color(red: 180 / 255, green: 40 / 255, blue: 30 / 255)
        case "image.convert":
            c1 = Color(red: 130 / 255, green: 85 / 255, blue: 245 / 255) // Electric Violet
            c2 = Color(red: 85 / 255, green: 45 / 255, blue: 190 / 255)
        case "image.resize":
            c1 = Color(red: 255 / 255, green: 155 / 255, blue: 35 / 255) // Sunset Amber
            c2 = Color(red: 230 / 255, green: 95 / 255, blue: 20 / 255)
        case "image.batch":
            c1 = Color(red: 225 / 255, green: 55 / 255, blue: 165 / 255) // Vivid Magenta
            c2 = Color(red: 170 / 255, green: 25 / 255, blue: 115 / 255)
        case "image.toPDF":
            c1 = Color(red: 240 / 255, green: 70 / 255, blue: 85 / 255) // Coral Red
            c2 = Color(red: 190 / 255, green: 35 / 255, blue: 50 / 255)

        // PDF Suite
        case "pdf.compress":
            c1 = Color(red: 215 / 255, green: 50 / 255, blue: 55 / 255) // Deep Scarlet
            c2 = Color(red: 150 / 255, green: 25 / 255, blue: 30 / 255)
        case "pdf.merge":
            c1 = Color(red: 40 / 255, green: 140 / 255, blue: 255 / 255) // Royal Blue
            c2 = Color(red: 20 / 255, green: 95 / 255, blue: 210 / 255)
        case "pdf.split":
            c1 = Color(red: 25 / 255, green: 185 / 255, blue: 220 / 255) // Electric Cyan
            c2 = Color(red: 10 / 255, green: 130 / 255, blue: 175 / 255)
        case "pdf.toImage":
            c1 = Color(red: 45 / 255, green: 200 / 255, blue: 115 / 255) // Emerald Green
            c2 = Color(red: 25 / 255, green: 150 / 255, blue: 80 / 255)
        case "pdf.rotate":
            c1 = Color(red: 155 / 255, green: 80 / 255, blue: 250 / 255) // Lavender Purple
            c2 = Color(red: 105 / 255, green: 40 / 255, blue: 200 / 255)
        case "pdf.extractPages", "pdf.removePages":
            c1 = Color(red: 235 / 255, green: 45 / 255, blue: 95 / 255) // Carmine
            c2 = Color(red: 175 / 255, green: 20 / 255, blue: 65 / 255)
        case "pdf.reorderPages":
            c1 = Color(red: 95 / 255, green: 85 / 255, blue: 215 / 255) // Deep Indigo
            c2 = Color(red: 55 / 255, green: 45 / 255, blue: 165 / 255)

        // Archive Suite
        case "archive.compress":
            c1 = Color(red: 245 / 255, green: 170 / 255, blue: 25 / 255) // Warm Gold / Amber
            c2 = Color(red: 205 / 255, green: 120 / 255, blue: 15 / 255)
        case "archive.extract":
            c1 = Color(red: 250 / 255, green: 120 / 255, blue: 35 / 255) // Flame Orange
            c2 = Color(red: 205 / 255, green: 75 / 255, blue: 20 / 255)
        case "archive.inspect":
            c1 = Color(red: 100 / 255, green: 125 / 255, blue: 140 / 255) // Slate Steel
            c2 = Color(red: 60 / 255, green: 80 / 255, blue: 95 / 255)

        // QR & Barcode Suite
        case "qr.generate":
            c1 = Color(red: 55 / 255, green: 65 / 255, blue: 75 / 255) // Obsidian / Graphite
            c2 = Color(red: 25 / 255, green: 30 / 255, blue: 36 / 255)
        case "qr.scan":
            c1 = Color(red: 20 / 255, green: 165 / 255, blue: 255 / 255) // Azure Neon
            c2 = Color(red: 10 / 255, green: 115 / 255, blue: 220 / 255)
        case "barcode.generate":
            c1 = Color(red: 75 / 255, green: 80 / 255, blue: 90 / 255) // Titanium Gray
            c2 = Color(red: 45 / 255, green: 50 / 255, blue: 58 / 255)

        // OCR & Vision Suite
        case "ocr.imageToText", "ocr.pdfToText", "ocr.searchablePDF":
            c1 = Color(red: 30 / 255, green: 200 / 255, blue: 200 / 255) // Cyber Cyan
            c2 = Color(red: 15 / 255, green: 140 / 255, blue: 160 / 255)

        // Icons & Vector Suite
        case "icon.generateICNS", "icon.extractFromICNS":
            c1 = Color(red: 110 / 255, green: 80 / 255, blue: 235 / 255) // Royal Indigo
            c2 = Color(red: 70 / 255, green: 45 / 255, blue: 180 / 255)
        case "vector.toPDF", "vector.toImage":
            c1 = Color(red: 250 / 255, green: 110 / 255, blue: 180 / 255) // Fuchsia
            c2 = Color(red: 195 / 255, green: 60 / 255, blue: 130 / 255)

        // Media & Video Suite
        case "video.convert", "video.compress":
            c1 = Color(red: 235 / 255, green: 40 / 255, blue: 110 / 255) // Neon Crimson
            c2 = Color(red: 165 / 255, green: 20 / 255, blue: 75 / 255)
        case "video.toGIF":
            c1 = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255) // Deep Orange
            c2 = Color(red: 200 / 255, green: 90 / 255, blue: 0 / 255)
        case "video.extractAudio", "audio.convert":
            c1 = Color(red: 140 / 255, green: 60 / 255, blue: 240 / 255) // Electric Purple
            c2 = Color(red: 90 / 255, green: 30 / 255, blue: 180 / 255)

        // Office & Documents Suite
        case "office.toPDF", "markdown.toPDF":
            c1 = Color(red: 40 / 255, green: 120 / 255, blue: 240 / 255) // Cobalt Blue
            c2 = Color(red: 20 / 255, green: 80 / 255, blue: 190 / 255)

        // Data Suite
        case "data.convert", "data.prettify":
            c1 = Color(red: 45 / 255, green: 185 / 255, blue: 130 / 255) // Mint Teal
            c2 = Color(red: 20 / 255, green: 130 / 255, blue: 90 / 255)

        // Metadata Suite
        case "metadata.strip", "metadata.inspect":
            c1 = Color(red: 100 / 255, green: 115 / 255, blue: 135 / 255) // Cool Graphite
            c2 = Color(red: 65 / 255, green: 75 / 255, blue: 90 / 255)

        default:
            c1 = LiquidGlass.brandAccentLight
            c2 = LiquidGlass.brandAccentDeep
        }

        return LinearGradient(
            colors: [c1, c2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
