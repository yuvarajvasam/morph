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
            ),
            // MARK: - OCR & Vision Suite (Apple Vision Framework)
            ConversionCommand(
                id: "ocr.imageToText",
                title: "Extract Text (OCR)",
                subtitle: "Extract text from photos or screenshots using Apple Vision",
                category: .ocr,
                systemIcon: "text.viewfinder",
                keywords: ["ocr", "text", "vision", "scan", "extract", "read", "copy"],
                synonyms: ["extract text", "read text from image", "ocr photo", "image to text", "copy text from picture"],
                supportedExtensions: ["png", "jpg", "jpeg", "heic", "webp", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "ocr.pdfToText",
                title: "Extract Text from PDF",
                subtitle: "Extract text from scanned PDF pages using Apple Vision",
                category: .ocr,
                systemIcon: "doc.text.viewfinder",
                keywords: ["ocr", "pdf", "text", "vision", "scanned"],
                synonyms: ["ocr pdf", "extract text from pdf", "pdf to text", "scanned pdf to text"],
                supportedExtensions: ["pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "ocr.searchablePDF",
                title: "Make PDF Searchable (OCR)",
                subtitle: "Create searchable PDF with recognized text layer",
                category: .ocr,
                systemIcon: "doc.badge.magnifyingglass",
                keywords: ["ocr", "searchable", "pdf", "layer", "scan"],
                synonyms: ["make pdf searchable", "searchable pdf", "ocr document to pdf", "add text layer to pdf"],
                supportedExtensions: ["pdf", "jpg", "jpeg", "png", "heic", "tiff", "tif"],
                supportsMultipleFiles: false
            ),
            // MARK: - Icons & Vector Suite
            ConversionCommand(
                id: "icon.generateICNS",
                title: "Generate macOS Icon (.icns)",
                subtitle: "Create multi-resolution Apple .icns app icon from image",
                category: .icon,
                systemIcon: "app.dashed",
                keywords: ["icon", "icns", "apple", "mac", "app", "favicon"],
                synonyms: ["create icns", "png to icns", "make mac icon", "generate icon", "mac app icon"],
                supportedExtensions: ["png", "jpg", "jpeg", "webp", "tiff", "tif", "svg"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "icon.extractFromICNS",
                title: "Extract Icon Image",
                subtitle: "Extract high-resolution 1024px PNG from macOS .icns file",
                category: .icon,
                systemIcon: "arrow.down.app",
                keywords: ["icns", "png", "extract", "icon", "export"],
                synonyms: ["icns to png", "extract icns", "convert icns to png", "open icns"],
                supportedExtensions: ["icns"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "vector.toPDF",
                title: "SVG to Vector PDF",
                subtitle: "Render scalable SVG graphic into resolution-independent PDF",
                category: .icon,
                systemIcon: "point.topleft.down.to.point.bottomright.curvepath",
                keywords: ["svg", "vector", "pdf", "scalable", "render"],
                synonyms: ["svg to pdf", "convert svg to pdf", "vector to pdf", "save svg as pdf"],
                supportedExtensions: ["svg"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "vector.toImage",
                title: "SVG to Raster Image",
                subtitle: "Rasterize SVG graphic to high-resolution PNG or JPEG",
                category: .icon,
                systemIcon: "photo.artframe",
                keywords: ["svg", "png", "jpeg", "raster", "render"],
                synonyms: ["svg to png", "svg to jpg", "convert svg to png", "rasterize svg"],
                supportedExtensions: ["svg"],
                supportsMultipleFiles: false
            ),
            // MARK: - Audio & Video Suite (FFmpeg)
            ConversionCommand(
                id: "video.convert",
                title: "Convert Video",
                subtitle: "Transcode video between MP4, MOV, MKV, WebM, and AVI (FFmpeg)",
                category: .media,
                systemIcon: "video.badge.plus",
                keywords: ["video", "convert", "mp4", "mov", "mkv", "webm", "avi", "transcode", "ffmpeg"],
                synonyms: ["convert video", "mov to mp4", "mkv to mp4", "webm to mp4", "change video format"],
                supportedExtensions: ["mp4", "mov", "mkv", "webm", "avi", "m4v", "flv"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "video.compress",
                title: "Compress Video",
                subtitle: "Reduce video file size with Light, Balanced, or Maximum presets",
                category: .media,
                systemIcon: "arrow.down.right.and.arrow.up.left.square.fill",
                keywords: ["compress", "shrink", "reduce", "video", "smaller", "size", "crf"],
                synonyms: ["make video smaller", "reduce video size", "compress movie", "shrink video"],
                supportedExtensions: ["mp4", "mov", "mkv", "webm", "avi", "m4v"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "video.toGIF",
                title: "Video to Animated GIF",
                subtitle: "Convert video clip to smooth animated GIF with palette mapping",
                category: .media,
                systemIcon: "play.square.stack",
                keywords: ["gif", "animated", "video", "clip", "palette", "loop"],
                synonyms: ["video to gif", "make gif from video", "mp4 to gif", "convert video to gif"],
                supportedExtensions: ["mp4", "mov", "mkv", "webm", "avi", "m4v"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "video.extractAudio",
                title: "Extract Audio from Video",
                subtitle: "Extract soundtrack to MP3, AAC, M4A, or WAV",
                category: .media,
                systemIcon: "waveform.and.magnifyingglass",
                keywords: ["extract", "audio", "soundtrack", "mp3", "video", "rip"],
                synonyms: ["extract audio", "video to mp3", "rip audio from video", "get mp3 from video"],
                supportedExtensions: ["mp4", "mov", "mkv", "webm", "avi", "m4v"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "audio.convert",
                title: "Convert Audio",
                subtitle: "Convert between MP3, M4A, WAV, AAC, FLAC, and OGG formats",
                category: .media,
                systemIcon: "waveform",
                keywords: ["audio", "sound", "mp3", "wav", "m4a", "flac", "aac", "ogg"],
                synonyms: ["convert audio", "wav to mp3", "flac to mp3", "m4a to mp3", "change audio format"],
                supportedExtensions: ["mp3", "m4a", "wav", "aac", "flac", "ogg", "aiff"],
                supportsMultipleFiles: false
            ),
            // MARK: - Office Documents Suite (LibreOffice & Pandoc)
            ConversionCommand(
                id: "office.toPDF",
                title: "Office Document to PDF",
                subtitle: "Convert Word, Excel, PowerPoint to PDF offline without Office (LibreOffice)",
                category: .office,
                systemIcon: "doc.text.fill",
                keywords: ["office", "word", "excel", "powerpoint", "docx", "pptx", "xlsx", "pdf", "libreoffice"],
                synonyms: ["docx to pdf", "word to pdf", "pptx to pdf", "excel to pdf", "convert docx to pdf"],
                supportedExtensions: ["docx", "doc", "pptx", "ppt", "xlsx", "xls", "odt", "ods", "odp", "rtf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "markdown.toPDF",
                title: "Markdown to PDF",
                subtitle: "Convert Markdown document (.md) into styled PDF",
                category: .office,
                systemIcon: "doc.richtext",
                keywords: ["markdown", "md", "pdf", "pandoc", "document"],
                synonyms: ["md to pdf", "markdown to pdf", "convert markdown to pdf", "render markdown"],
                supportedExtensions: ["md", "markdown"],
                supportsMultipleFiles: false
            ),
            // MARK: - Structured Data Suite
            ConversionCommand(
                id: "data.convert",
                title: "Convert Data Format",
                subtitle: "Convert between JSON, Property List (.plist), and CSV formats",
                category: .data,
                systemIcon: "curlybraces",
                keywords: ["json", "plist", "csv", "data", "convert", "table"],
                synonyms: ["json to plist", "plist to json", "json to csv", "csv to json", "convert json"],
                supportedExtensions: ["json", "plist", "csv", "xml"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "data.prettify",
                title: "Format & Beautify JSON",
                subtitle: "Format and indent JSON or XML with clean 2-space indentation",
                category: .data,
                systemIcon: "text.alignleft",
                keywords: ["json", "format", "beautify", "indent", "prettify", "clean"],
                synonyms: ["prettify json", "format json", "indent json", "beautify json"],
                supportedExtensions: ["json", "xml"],
                supportsMultipleFiles: false
            ),
            // MARK: - Metadata Suite
            ConversionCommand(
                id: "metadata.strip",
                title: "Strip Metadata & GPS",
                subtitle: "Remove private EXIF, GPS location, and camera profiles",
                category: .image,
                systemIcon: "eye.slash",
                keywords: ["metadata", "exif", "gps", "privacy", "strip", "remove", "clean"],
                synonyms: ["remove exif", "strip gps", "clean metadata", "remove camera info", "privacy clean"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "tiff", "tif", "pdf"],
                supportsMultipleFiles: false
            ),
            ConversionCommand(
                id: "metadata.inspect",
                title: "Inspect File Metadata",
                subtitle: "View camera, lens, exposure, GPS, and technical tags",
                category: .image,
                systemIcon: "info.circle.fill",
                keywords: ["metadata", "exif", "info", "camera", "lens", "gps", "details"],
                synonyms: ["view exif", "check metadata", "camera info", "show gps tags", "inspect photo"],
                supportedExtensions: ["jpg", "jpeg", "png", "heic", "tiff", "tif", "pdf", "mp4", "mov"],
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
                    ["pdf.compress", "pdf.merge", "pdf.split", "pdf.toImage", "pdf.rotate", "pdf.extractPages", "pdf.removePages", "pdf.reorderPages", "ocr.pdfToText", "ocr.searchablePDF", "metadata.strip"].contains($0.id)
                }
            } else if ["jpg", "jpeg", "png", "heic", "webp", "tiff", "tif"].contains(ext) {
                return allCommands.filter { ["image.compress", "image.convert", "image.resize", "image.toPDF", "ocr.imageToText", "icon.generateICNS", "metadata.strip", "metadata.inspect", "qr.scan"].contains($0.id) }
            } else if ["mp4", "mov", "mkv", "webm", "avi", "m4v", "flv"].contains(ext) {
                return allCommands.filter { ["video.convert", "video.compress", "video.toGIF", "video.extractAudio", "metadata.inspect"].contains($0.id) }
            } else if ["mp3", "m4a", "wav", "aac", "flac", "ogg", "aiff"].contains(ext) {
                return allCommands.filter { ["audio.convert"].contains($0.id) }
            } else if ["docx", "doc", "pptx", "ppt", "xlsx", "xls", "odt", "ods", "odp", "rtf"].contains(ext) {
                return allCommands.filter { ["office.toPDF"].contains($0.id) }
            } else if ["md", "markdown"].contains(ext) {
                return allCommands.filter { ["markdown.toPDF"].contains($0.id) }
            } else if ext == "svg" {
                return allCommands.filter { ["vector.toPDF", "vector.toImage", "icon.generateICNS"].contains($0.id) }
            } else if ext == "icns" {
                return allCommands.filter { ["icon.extractFromICNS"].contains($0.id) }
            } else if ["json", "plist", "csv", "xml"].contains(ext) {
                return allCommands.filter { ["data.convert", "data.prettify"].contains($0.id) }
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
}
