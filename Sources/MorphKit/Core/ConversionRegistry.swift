import Foundation

public final class ConversionRegistry: @unchecked Sendable {
    public static let shared = ConversionRegistry()

    public let allCommands: [ConversionCommand]

    private init() {
        self.allCommands = [
            ConversionCommand(
                id: "image.compress",
                title: "Compress Image",
                subtitle: "Reduce file size with Light, Balanced, or Maximum presets",
                category: .image,
                systemIcon: "arrow.down.right.and.arrow.up.left",
                keywords: ["compress", "shrink", "reduce", "optimize", "quality", "size"],
                synonyms: [
                    "make image smaller",
                    "reduce photo size",
                    "shrink image",
                    "optimize photo",
                    "compress photo",
                    "make photo smaller"
                ],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.convert",
                title: "Convert Image",
                subtitle: "Convert between JPEG, PNG, HEIC, and WebP formats",
                category: .image,
                systemIcon: "arrow.triangle.2.circlepath",
                keywords: ["convert", "format", "transcode", "export", "extension"],
                synonyms: [
                    "change image format",
                    "png to jpg",
                    "jpg to png",
                    "heic to jpg",
                    "webp to png",
                    "convert photo",
                    "save as png"
                ],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.resize",
                title: "Resize Image",
                subtitle: "Scale dimensions, max width/height, or percentage scale",
                category: .image,
                systemIcon: "aspectratio",
                keywords: ["resize", "dimensions", "scale", "width", "height", "pixels"],
                synonyms: [
                    "scale photo",
                    "change resolution",
                    "resize photo",
                    "downscale",
                    "image dimensions",
                    "shrink dimensions"
                ],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.crop",
                title: "Crop Image",
                subtitle: "Trim borders or crop to 1:1, 4:3, 16:9 aspect ratios",
                category: .image,
                systemIcon: "crop",
                keywords: ["crop", "aspect", "ratio", "cut", "trim", "square"],
                synonyms: ["crop photo", "make square", "trim photo", "cut image"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.rotate",
                title: "Rotate Image",
                subtitle: "Rotate photo by 90°, 180°, or flip orientation",
                category: .image,
                systemIcon: "rotate.right",
                keywords: ["rotate", "turn", "flip", "orientation", "portrait", "landscape"],
                synonyms: ["turn photo", "rotate picture", "flip photo"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.watermark",
                title: "Watermark Image",
                subtitle: "Apply text or logo watermark with customizable opacity",
                category: .image,
                systemIcon: "drop.fill",
                keywords: ["watermark", "stamp", "copyright", "brand", "logo", "text"],
                synonyms: ["add watermark", "stamp photo", "protect image"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.removeBg",
                title: "Remove Background",
                subtitle: "Isolate subjects and create transparent cutout backgrounds",
                category: .image,
                systemIcon: "wand.and.stars",
                keywords: ["background", "remove", "cutout", "transparent", "alpha", "subject"],
                synonyms: ["remove photo background", "make transparent", "isolate person"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.formatConverter",
                title: "Format Converter",
                subtitle: "Universal file format converter for modern and legacy graphics",
                category: .image,
                systemIcon: "doc.badge.gearshape",
                keywords: ["format", "converter", "transcode", "png", "jpeg", "webp"],
                synonyms: ["convert format", "change extension", "image converter"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.heicToJpg",
                title: "HEIC to JPG",
                subtitle: "Quick 1-click conversion from Apple HEIC to universal JPEG",
                category: .image,
                systemIcon: "photo.badge.arrow.forward",
                keywords: ["heic", "jpg", "jpeg", "apple", "iphone", "convert"],
                synonyms: ["heic to jpg", "iphone photo to jpg", "convert heic"],
                supportedExtensions: ["heic", "heif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "image.toPDF",
                title: "Image to PDF",
                subtitle: "Assemble photos or scans into a single multi-page PDF",
                category: .pdf,
                systemIcon: "doc.badge.plus",
                keywords: ["pdf", "combine", "scans", "photos", "document"],
                synonyms: [
                    "pictures to pdf",
                    "photos to pdf",
                    "convert images to pdf",
                    "create pdf from images",
                    "scan to pdf"
                ],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: true
            ),
            ConversionCommand(
                id: "image.batch",
                title: "Batch Process Images",
                subtitle: "Apply compression, conversion, or resizing to multiple images",
                category: .image,
                systemIcon: "square.stack.3d.down.right",
                keywords: ["batch", "bulk", "multiple", "queue", "all"],
                synonyms: [
                    "batch compress",
                    "batch convert",
                    "multiple images",
                    "bulk resize",
                    "bulk photo",
                    "convert folder of images"
                ],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: true
            ),
            ConversionCommand(
                id: "pdf.compress",
                title: "Compress PDF",
                subtitle: "Downsample raster graphics and optimize document size",
                category: .pdf,
                systemIcon: "doc.zipper",
                keywords: ["compress", "shrink", "optimize", "reduce", "size"],
                synonyms: [
                    "reduce pdf size",
                    "shrink pdf",
                    "make pdf smaller",
                    "compact pdf",
                    "optimize pdf document"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.merge",
                title: "Merge PDF",
                subtitle: "Combine multiple PDF documents in custom order",
                category: .pdf,
                systemIcon: "doc.on.doc",
                keywords: ["merge", "combine", "join", "stitch", "append"],
                synonyms: [
                    "combine pdfs",
                    "join pdf",
                    "stitch pdf",
                    "bind pdf",
                    "merge documents",
                    "assemble pdf"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: true
            ),
            ConversionCommand(
                id: "pdf.split",
                title: "Split PDF",
                subtitle: "Extract individual pages or custom ranges (e.g. 1-3, 5)",
                category: .pdf,
                systemIcon: "scissors",
                keywords: ["split", "extract", "range", "divide", "pages", "separate"],
                synonyms: [
                    "separate pdf pages",
                    "cut pdf",
                    "extract pages",
                    "divide pdf",
                    "split pages from pdf"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.toImage",
                title: "PDF to Image",
                subtitle: "Export document pages as high-resolution PNG or JPEG",
                category: .pdf,
                systemIcon: "photo.stack",
                keywords: ["export", "render", "extract", "png", "jpeg", "jpg"],
                synonyms: [
                    "pdf to jpg",
                    "pdf to png",
                    "export pdf pages as images",
                    "save pdf as picture"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.rotate",
                title: "Rotate Pages",
                subtitle: "Turn PDF pages by 90°, 180°, or 270° with visual preview",
                category: .pdf,
                systemIcon: "rotate.right",
                keywords: ["rotate", "turn", "orientation", "landscape", "portrait", "flip"],
                synonyms: [
                    "rotate document",
                    "turn pdf page",
                    "flip pdf",
                    "fix orientation",
                    "landscape to portrait"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.extractPages",
                title: "Extract Pages",
                subtitle: "Visually select and extract specific pages into a new PDF",
                category: .pdf,
                systemIcon: "doc.badge.gearshape",
                keywords: ["extract", "pick", "select", "pages", "subset"],
                synonyms: [
                    "extract pdf pages",
                    "pull pages",
                    "select pages to save",
                    "isolate pages"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.removePages",
                title: "Remove Pages",
                subtitle: "Visually select and delete unwanted pages from PDF",
                category: .pdf,
                systemIcon: "trash",
                keywords: ["delete", "remove", "cut", "discard", "pages"],
                synonyms: [
                    "remove pdf pages",
                    "delete page from pdf",
                    "drop pages",
                    "eliminate pages"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "pdf.reorderPages",
                title: "Reorder Pages",
                subtitle: "Rearrange page sequence with interactive thumbnail strip",
                category: .pdf,
                systemIcon: "arrow.up.arrow.down.square",
                keywords: ["reorder", "rearrange", "sort", "sequence", "organize"],
                synonyms: [
                    "reorder pdf",
                    "rearrange pdf pages",
                    "change page order",
                    "move pages"
                ],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "archive.compress",
                title: "Create Archive",
                subtitle: "Compress files or folders into ZIP, TAR, or TAR.GZ",
                category: .archive,
                systemIcon: "archivebox",
                keywords: ["zip", "archive", "compress", "tar", "gzip", "bundle", "pack"],
                synonyms: [
                    "zip file",
                    "create zip",
                    "make archive",
                    "compress folder",
                    "tar file",
                    "zip folder"
                ],
                supportedExtensions: [],
                supportsMultipleFiles: true
            ),
            ConversionCommand(
                id: "archive.extract",
                title: "Extract Archive",
                subtitle: "Unpack ZIP, TAR, or TAR.GZ archives",
                category: .archive,
                systemIcon: "tray.and.arrow.up",
                keywords: ["unzip", "extract", "unpack", "decompress", "archive", "open zip"],
                synonyms: [
                    "unzip file",
                    "open archive",
                    "unpack zip",
                    "extract tar",
                    "uncompress archive"
                ],
                supportedExtensions: ["zip", "tar", "gz", "tgz", "bz2", "xz"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "archive.inspect",
                title: "Inspect Archive",
                subtitle: "View files and folders inside an archive without extracting",
                category: .archive,
                systemIcon: "doc.text.magnifyingglass",
                keywords: ["inspect", "list", "view", "peek", "contents", "archive"],
                synonyms: [
                    "view zip",
                    "list archive",
                    "peek archive",
                    "archive contents"
                ],
                supportedExtensions: ["zip", "tar", "gz", "tgz", "bz2", "xz"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "qr.generate",
                title: "Generate QR Code",
                subtitle: "Create high-resolution QR codes for URLs, Wi-Fi, email, or contacts",
                category: .qrBarcode,
                systemIcon: "qrcode",
                keywords: ["qr", "qrcode", "generator", "barcode", "wifi", "link", "url"],
                synonyms: [
                    "create qr",
                    "make qr code",
                    "generate qr",
                    "wifi qr",
                    "qr code"
                ],
                supportedExtensions: [],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "barcode.generate",
                title: "Generate Barcode",
                subtitle: "Create standard Code 128 barcodes",
                category: .qrBarcode,
                systemIcon: "barcode",
                keywords: ["barcode", "code128", "generator", "upc", "ean", "scan"],
                synonyms: [
                    "create barcode",
                    "make barcode",
                    "generate barcode",
                    "code 128"
                ],
                supportedExtensions: [],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "qr.scan",
                title: "Scan QR / Barcode",
                subtitle: "Decode QR codes or barcodes locally from an image",
                category: .qrBarcode,
                systemIcon: "qrcode.viewfinder",
                keywords: ["scan", "read", "detect", "decode", "recognize", "qr", "barcode"],
                synonyms: [
                    "read qr code",
                    "decode qr",
                    "scan barcode",
                    "detect qr",
                    "scan code"
                ],
                supportedExtensions: ["png", "jpg", "jpeg", "webp", "heic", "tiff"],
                supportsMultipleFiles: false
            )
        ]
    }

    /// Searches commands by query with ranked matching.
    public func search(query: String) -> [ConversionCommand] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return allCommands
        }

        // Score each command
        let scored = allCommands.compactMap { cmd -> (command: ConversionCommand, score: Int)? in
            var score = 0
            let titleLower = cmd.title.lowercased()
            let subtitleLower = cmd.subtitle.lowercased()

            if titleLower == trimmed {
                score += 100
            } else if titleLower.hasPrefix(trimmed) {
                score += 50
            } else if titleLower.contains(trimmed) {
                score += 30
            }

            for syn in cmd.synonyms {
                let synLower = syn.lowercased()
                if synLower == trimmed {
                    score += 90
                } else if synLower.hasPrefix(trimmed) || trimmed.hasPrefix(synLower) {
                    score += 45
                } else if synLower.contains(trimmed) || trimmed.contains(synLower) {
                    score += 25
                }
            }

            for kw in cmd.keywords {
                let kwLower = kw.lowercased()
                if kwLower == trimmed {
                    score += 40
                } else if kwLower.contains(trimmed) {
                    score += 20
                }
            }

            if subtitleLower.contains(trimmed) {
                score += 15
            }

            // Tokenized match check
            let tokens = trimmed.split(separator: " ").map { String($0) }
            let allText = (cmd.title + " " + cmd.subtitle + " " + cmd.keywords.joined(separator: " ") + " " + cmd.synonyms.joined(separator: " ")).lowercased()
            let matchedTokenCount = tokens.filter { allText.contains($0) }.count
            if matchedTokenCount > 0 {
                score += matchedTokenCount * 10
            }

            return score > 0 ? (command: cmd, score: score) : nil
        }

        return scored.sorted { $0.score > $1.score }.map { $0.command }
    }

    /// Returns recommended commands based on dropped file URLs.
    public func suggestedCommands(for urls: [URL]) -> [ConversionCommand] {
        guard !urls.isEmpty else { return [] }

        let extensions = urls.map { $0.pathExtension.lowercased() }
        let allArePDFs = extensions.allSatisfy { $0 == "pdf" }
        let allAreImages = extensions.allSatisfy { ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"].contains($0) }
        let allAreArchives = extensions.allSatisfy { ["zip", "tar", "gz", "tgz", "bz2", "xz"].contains($0) }

        if urls.count > 1 {
            if allArePDFs {
                return allCommands.filter { $0.id == "pdf.merge" }
            } else if allAreImages {
                return allCommands.filter { ["image.batch", "image.toPDF", "archive.compress"].contains($0.id) }
            } else {
                return allCommands.filter { $0.id == "archive.compress" }
            }
        } else if urls.count == 1 {
            let ext = extensions[0]
            if ext == "pdf" {
                return allCommands.filter {
                    ["pdf.compress", "pdf.merge", "pdf.split", "pdf.toImage", "pdf.rotate", "pdf.extractPages", "pdf.removePages", "pdf.reorderPages"].contains($0.id)
                }
            } else if ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"].contains(ext) {
                return allCommands.filter { ["image.compress", "image.convert", "image.resize", "image.toPDF", "qr.scan"].contains($0.id) }
            } else if allAreArchives {
                return allCommands.filter { ["archive.extract", "archive.inspect"].contains($0.id) }
            } else {
                return allCommands.filter { $0.id == "archive.compress" }
            }
        }

        return []
    }

    /// Lookup a command by its unique ID.
    public func command(id: String) -> ConversionCommand? {
        if id == "pdf.managePages" {
            return allCommands.first(where: { $0.id == "pdf.removePages" })
        }
        return allCommands.first(where: { $0.id == id })
    }

    /// Top 5 Most Used Commands (Screen 1 Launcher reference)
    public var mostUsedCommands: [ConversionCommand] {
        [
            command(id: "image.compress"),
            command(id: "image.resize"),
            command(id: "image.convert"),
            command(id: "pdf.compress"),
            command(id: "pdf.merge")
        ].compactMap { $0 }
    }

    /// Commands belonging to a given category
    public func commands(for category: ConversionCategory) -> [ConversionCommand] {
        allCommands.filter { $0.category == category }
    }
}

