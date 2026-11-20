# Morph Supported Formats & Conversion Matrix 🪄

This document provides a comprehensive audit and numerical format comparison between **Morph** and **Filee** ([filee.sh/formats](https://filee.sh/formats/)), detailing the exact format counts, supported extensions, underlying engines, and category gap analysis.

---

## 📊 Format Counts: Morph vs. Filee

| Metric | Filee ([filee.sh](https://filee.sh/formats/)) | Morph | Notes |
| :--- | :---: | :---: | :--- |
| **Total Standard Format Catalog** | **255 Formats** | **58 Formats** | Morph focuses on high-frequency everyday & pro workflows |
| **Catalog Categories** | **18 Categories** | **10 Categories** | Unimplemented: 3D, CAD, E-books, Fonts, GIS, HWP, Subtitles |
| **macOS-Exclusive Engine Suites** | *None* | **3 Suites** | Apple Vision OCR, Apple `.icns` App Icons, CoreImage Barcodes |
| **Zero-Download Native Engines** | 6 engines | **6 engines** | Apple Vision, ImageIO, CoreGraphics, PDFKit, Foundation, iconutil |
| **Modular CLI Tool Integrations** | 5 engines | **4 engines** | FFmpeg, LibreOffice, Pandoc, Whisper |

---

## 📋 Category-by-Category Format Count Comparison

The table below maps each of the **18 categories from Filee's official catalog** against Morph's current format counts and supported file extensions:

| # | Category | Filee Count | Morph Count | Formats Supported in Morph | Engine Backend in Morph |
| :-: | :--- | :-: | :-: | :--- | :--- |
| **1** | **Images & Photos** | **38** | **16** | `JPEG`, `JPG`, `PNG`, `HEIC`, `HEIF`, `WebP`, `TIFF`, `TIF`, `GIF`, `BMP`, `ICO`, `DNG`, `CR2`, `NEF`, `ARW`, `RW2` | Native Apple ImageIO & CoreGraphics |
| **2** | **PDF Documents** | **1** | **1** | `PDF` *(Full Suite: Compress, Merge, Split, PDF→Images, Rotate, Extract, Reorder, Delete, Searchable PDF)* | Native Apple PDFKit & Quartz |
| **3** | **Vector Graphics** | **12** | **1** | `SVG` *(Renders to Vector PDF, High-Res PNG/JPEG 1x/2x/4x)* | Native CoreGraphics & ImageIO |
| **4** | **Documents (Word/Office)** | **24** | **5** | `DOCX`, `DOC`, `ODT`, `RTF`, `Markdown` (`.md`) | Modular LibreOffice Headless & Pandoc |
| **5** | **Spreadsheets** | **13** | **4** | `XLSX`, `XLS`, `ODS`, `CSV` *(to PDF & JSON)* | Modular LibreOffice & Foundation |
| **6** | **Presentations** | **12** | **3** | `PPTX`, `PPT`, `ODP` *(to PDF)* | Modular LibreOffice Headless |
| **7** | **Text & Markup** | **15** | **3** | `TXT`, `MD` (Markdown), `XML` | Modular Pandoc, Apple Vision & Foundation |
| **8** | **Data & Config** | **6** | **4** | `JSON`, `PLIST` (macOS Property List), `XML`, `CSV` | Native Apple Foundation |
| **9** | **Video** | **22** | **10** | `MP4`, `MOV`, `MKV`, `WEBM`, `AVI`, `M4V`, `FLV`, `WMV`, `MPEG`, `TS` *(plus Animated GIF)* | Modular FFmpeg Media Engine |
| **10** | **Audio** | **30** | **10** | `MP3`, `M4A`, `WAV`, `AAC`, `FLAC`, `OGG`, `OPUS`, `AIFF`, `WMA`, `CAF` | Modular FFmpeg Media Engine |
| **11** | **Archives** | **28** | **1** | `ZIP` *(Fast create, non-extracting inspection, safe unpack)* | Native Apple Foundation & libcompression |
| **12** | **Subtitles** | **9** | **0** | *(Not a dedicated format converter; Whisper outputs `.srt`/`.vtt`)* | Modular Whisper Speech Engine |
| **13** | **E-books & Comics** | **24** | **0** | *(Not currently supported; Filee integrates Calibre)* | Planned for future release |
| **14** | **CAD Drawings** | **2** | **0** | *(Not currently supported; AutoCAD DWG/DXF)* | Niche engineering format |
| **15** | **3D Models** | **7** | **0** | *(Not currently supported; GLB, glTF, STL, OBJ, FBX)* | Can leverage macOS ModelIO in future |
| **16** | **Fonts** | **5** | **0** | *(Not currently supported; TTF, OTF, WOFF, WOFF2)* | Niche web typography format |
| **17** | **Geospatial GIS Data** | **5** | **0** | *(Not currently supported; Shapefile, KML, KMZ, GPX)* | Planned via Swift DataEngine expansion |
| **18** | **Korean HWP (Hangul)** | **2** | **0** | *(Not supported; Hancom Office specific)* | Region-specific (South Korea) |
| 🧮 | **TOTAL (Filee Categories)**| **255** | **58** | **58 Distinct Formats Covered** *(100% of daily essential workflows)* | **6 Native + 4 Modular Engines** |

---

## 🌟 macOS-Exclusive Engines in Morph (Not in Filee)

In addition to matching Filee's core format conversions, Morph includes **3 Apple-exclusive engine suites** built natively into macOS that Filee does not offer:

| Feature / Engine | Supported Formats | Description | Backend |
| :--- | :--- | :--- | :--- |
| **Apple Vision On-Device OCR** | `PNG`, `JPG`, `HEIC`, `TIFF`, `WebP`, `PDF` → `.txt` / Searchable `PDF` | Offline neural text recognition running on Apple Neural Engine; embeds invisible selectable text layer into scanned PDFs. | Native `Vision.framework` |
| **Apple App Icon Engine** | `PNG`, `JPG`, `TIFF` ↔ macOS `.icns` | Synthesizes full 10-resolution macOS icon packages (`16px` to `1024px`) via Apple `iconutil`; extracts 1024px master PNG. | Native `/usr/bin/iconutil` & CoreGraphics |
| **CoreImage Barcodes & QR** | Text, URLs, Wi-Fi ↔ `PNG` | Generates crisp vector QR Codes and Code 128 barcodes; scans and decodes codes from images. | Native `CoreImage.framework` |
| **Privacy & EXIF Metadata** | `JPEG`, `PNG`, `TIFF`, `HEIC` | Deep EXIF/GPS/IPTC metadata inspector and zero-loss metadata stripper without re-encoding image data. | Native `ImageIO.framework` |
| **Interactive Before/After Split** | All Image Formats | Real-time dual-pane split comparison slider with double-click reset and live byte-savings readout. | Native SwiftUI Liquid Glass |

---

## 🛠 Detailed Conversions Morph Can Perform Right Now

### 1. Image Operations & Conversions (16 Formats)
**Engine:** Native Apple ImageIO & CoreGraphics (100% Offline, Zero Downloads)

| Input Format | Output Format | Supported Actions / Parameters |
| :--- | :--- | :--- |
| `JPEG`, `JPG` | `PNG`, `HEIC`, `WebP`, `TIFF`, `PDF`, `.icns` | Compression (Light, Balanced, Maximum), Resize (W×H, Max Width, Scale %), Strip EXIF/GPS, Multi-image to PDF |
| `PNG` | `JPEG`, `HEIC`, `WebP`, `TIFF`, `PDF`, `.icns` | Alpha preservation, safe background flattening to white when targeting JPEG, Multi-image to PDF |
| `HEIC`, `HEIF` | `JPEG`, `PNG`, `WebP`, `TIFF`, `PDF` | Apple High Efficiency conversion, metadata preservation or stripping |
| `WebP` | `JPEG`, `PNG`, `HEIC`, `TIFF`, `PDF` | Modern web format conversion with lossless or lossy compression |
| `TIFF`, `TIF` | `JPEG`, `PNG`, `HEIC`, `WebP`, `PDF` | High-bit-depth printing format rasterization |
| `GIF` (static/first frame) | `PNG`, `JPEG`, `WebP` | Frame extraction and static format conversion |
| `BMP`, `ICO` | `PNG`, `JPEG`, `HEIC`, `WebP` | Legacy bitmap conversion |
| `DNG`, `CR2`, `NEF`, `ARW`, `RW2` (RAW) | `JPEG`, `PNG`, `TIFF`, `PDF` | Apple ImageIO native Camera RAW decoding and export |

---

### 2. Apple App Icons (2 Conversions)
**Engine:** Native Apple `iconutil` & CoreGraphics

| Input Format | Output Format | Operations |
| :--- | :--- | :--- |
| `PNG`, `JPEG`, `TIFF` | macOS App Icon (`.icns`) | Generates all 10 standard Apple icon sizes: `16x16`, `16x16@2x`, `32x32`, `32x32@2x`, `128x128`, `128x128@2x`, `256x256`, `256x256@2x`, `512x512`, `512x512@2x` (1024px) |
| `.icns` | `PNG` | Lossless extraction of the 1024×1024 master artwork with full alpha transparency |

---

### 3. Vector Graphics (1 Format)
**Engine:** Native CoreGraphics & ImageIO

| Input Format | Output Format | Operations |
| :--- | :--- | :--- |
| `SVG` | Vector `PDF` | Resolution-independent vector rendering maintaining sharp bezier curves at any zoom |
| `SVG` | High-Res `PNG`, `JPEG` | Rasterization with configurable scaling factor (`1x`, `2x` Retina, `4x` Ultra-HD) |

---

### 4. PDF Document Utilities (1 Format, 8 Operations)
**Engine:** Native Apple PDFKit & Quartz

| Operation | Input | Output | Capabilities |
| :--- | :--- | :--- | :--- |
| **Compress PDF** | `PDF` | `PDF` | Stream compaction, duplicate font deduplication, downsampling raster images to 144 DPI or 96 DPI while keeping vector text sharp |
| **Merge PDFs** | Multi-`PDF` | Single `PDF` | Combines multiple documents while preserving page dimensions, rotation, and bookmarks |
| **Split PDF** | `PDF` | Multi-`PDF` | Split into individual pages or extract custom ranges (e.g. `1-3, 5, 8-10`) |
| **PDF to Images** | `PDF` | Multi-`PNG`, Multi-`JPEG` | Exports pages as individual high-res images at 72 DPI (Screen), 150 DPI (Print), or 300 DPI (High Res) |
| **Rotate Pages** | `PDF` | `PDF` | Visual page rotation (90°, 180°, 270°) |
| **Extract Pages** | `PDF` | `PDF` | Interactive selective extraction of chosen pages |
| **Remove Pages** | `PDF` | `PDF` | Visual deletion of unwanted pages with thumbnail preview |
| **Reorder Pages** | `PDF` | `PDF` | Interactive page sequence repositioning |

---

### 5. OCR & Vision Text Recognition (6 Formats)
**Engine:** Native Apple Vision Framework (Neural Engine / 100% On-Device)

| Input Format | Output Format | Capabilities |
| :--- | :--- | :--- |
| `PNG`, `JPEG`, `HEIC`, `TIFF`, `WebP`, Scanned `PDF` | Plain Text (`.txt`) | Fast, local text recognition with character recognition, line layout preservation, and automatic language detection |
| Scanned `PDF`, Images | Searchable `PDF` | Embeds an invisible, selectable, searchable text layer aligned precisely over the scanned bitmap image |

---

### 6. Video & Animation (10 Formats)
**Engine:** Modular FFmpeg Engine (`/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`)

| Input Format | Target Output | Capabilities |
| :--- | :--- | :--- |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI`, `M4V`, `FLV`, `WMV`, `MPEG`, `TS` | `MP4` | High-compatibility H.264 / AAC video container conversion |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI` | `MOV` | QuickTime-native video conversion |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI` | `WebM` | Modern web video (VP9 / Opus) |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI` | `MKV` | Open Matroska multimedia container conversion |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI` | Animated `GIF` | **Two-pass palette generation** (`palettegen` + `paletteuse`) for clean, dither-free GIFs with configurable framerates (10, 15, 24, 30 FPS) |
| `MP4`, `MOV`, `MKV` | Compressed Video | Constant Rate Factor (CRF) smart compression: **Light** (CRF 20), **Balanced** (CRF 26), **Maximum** (CRF 32) |
| `MP4`, `MOV`, `MKV`, `WebM`, `AVI` | `MP3`, `M4A`, `WAV`, `AAC`, `FLAC` | Direct audio soundtrack extraction from video stream |

---

### 7. Audio Transcoding & Extraction (10 Formats)
**Engine:** Modular FFmpeg Engine

| Input Format | Target Output | Capabilities |
| :--- | :--- | :--- |
| `MP3`, `M4A`, `WAV`, `AAC`, `FLAC`, `OGG`, `OPUS`, `AIFF`, `WMA`, `CAF` | `MP3` | Standard high-compatibility audio encoding (192 kbps CBR / VBR) |
| `MP3`, `WAV`, `FLAC`, `OGG`, etc. | `M4A` | Apple-native AAC audio encoding |
| `MP3`, `M4A`, `FLAC`, `OGG`, etc. | `WAV` | Lossless uncompressed 16-bit PCM audio export |
| `MP3`, `M4A`, `WAV`, `OGG`, etc. | `FLAC` | Lossless compressed audio transcoding |
| `MP3`, `WAV`, `FLAC`, etc. | `AAC` | Advanced Audio Coding export |

---

### 8. Office Documents & Markup (5 Formats)
**Engine:** Modular LibreOffice (`soffice`) & Pandoc

| Input Format | Target Output | Capabilities |
| :--- | :--- | :--- |
| Microsoft Word (`.docx`, `.doc`) | `PDF` | Headless LibreOffice conversion preserving font embedding, tables, headers, and pagination |
| Microsoft PowerPoint (`.pptx`, `.ppt`) | `PDF` | Slide deck vector PDF conversion |
| Microsoft Excel (`.xlsx`, `.xls`) | `PDF` | Spreadsheet sheet-to-page layout conversion |
| OpenDocument (`.odt`) | `PDF` | LibreOffice Writer document conversion |
| Rich Text (`.rtf`) | `PDF` | Formatted text layout rendering |
| Markdown (`.md`, `.markdown`) | `PDF` | Rendered via Pandoc with styling, or native CoreGraphics typography fallback |

---

### 9. Structured Data & Configuration (4 Formats)
**Engine:** Native Apple Foundation (`PropertyListSerialization` & `JSONSerialization`)

| Input Format | Target Output | Capabilities |
| :--- | :--- | :--- |
| `JSON` | Property List (`.plist`) | Converts modern JSON files into native macOS / iOS property list format |
| `JSON` | Comma-Separated Values (`.csv`) | Flattens JSON object arrays into structured CSV tabular files |
| `JSON` | Formatted `JSON` | Prettifies compact JSON files with 2-space indentation and sorted keys |
| Property List (`.plist`, `.xml`) | `JSON` | Converts binary or XML plist configuration files to standard JSON |
| Property List (`.plist`) | `XML` | Converts binary plists into human-readable XML format |
| `CSV` | `JSON` | Parses tabular CSV rows into structured JSON object arrays |

---

### 10. Archive Management (1 Format)
**Engine:** Native Apple Foundation & libcompression

| Operation | Input | Output | Capabilities |
| :--- | :--- | :--- | :--- |
| **Create Archive** | Any file(s) or folder | `.zip` | Fast, multi-file compression into a clean `.zip` archive |
| **Inspect Archive** | `.zip` | File List & Stats | Non-extracting entry inspection (count, compressed size, uncompressed size) |
| **Extract Archive** | `.zip` | Directory | Safe extraction preventing zip-slip vulnerabilities and collision safe renaming |

---

### 11. Barcodes & QR Codes (2 Formats)
**Engine:** Native Apple CoreImage (`CIQRCodeGenerator`, `CICode128BarcodeGenerator`) & Vision

| Operation | Input | Output | Capabilities |
| :--- | :--- | :--- | :--- |
| **Generate QR Code** | Text, URL, Wi-Fi | High-Res `PNG` | Correction levels (L, M, Q, H), crisp nearest-neighbor raster scaling |
| **Generate Barcode 128** | Alphanumeric string | High-Res `PNG` | Industrial Code 128 barcode generation |
| **Scan QR / Barcode** | Image (`PNG`, `JPG`, `HEIC`) | Decoded Text | Instant Vision-based barcode and QR code reading |

---

### 12. Privacy & Metadata
**Engine:** Native Apple ImageIO

| Operation | Input | Capabilities |
| :--- | :--- | :--- |
| **Inspect Metadata** | `JPEG`, `PNG`, `TIFF`, `HEIC` | Reads camera make/model, lens, exposure time, aperture, ISO, focal length, color space, and GPS latitude/longitude |
| **Strip Metadata** | `JPEG`, `PNG`, `TIFF`, `HEIC` | Generates a clean copy with all EXIF, GPS location coordinates, and IPTC ownership tags completely erased without re-encoding compression loss |

---

## 🔍 Category Gap Analysis (What Filee Has vs. Morph)

| Filee Category | Filee Formats | Why Not in Morph Yet | Potential Roadmap Strategy |
| :--- | :---: | :--- | :--- |
| **E-books & Comics** | EPUB, MOBI, AZW3, FB2, CBZ, CBR (24 formats) | Filee relies on Calibre and custom zip parsers. | Can add EPUB/CBZ reading and conversion via lightweight native Swift ZIP/XML parsers without Calibre bloat. |
| **CAD Drawings** | DWG, DXF (2 formats) | Filee has custom C# DWG/DXF parsers. Niche for engineering workflows. | Can be added via LibreOffice Draw or dedicated CAD conversion utilities if requested. |
| **3D Models** | GLB, glTF, STL, OBJ, 3MF, PLY, FBX (7 formats) | Specialized 3D gaming/printing domain. | macOS SceneKit and ModelIO provide native support for USDZ, OBJ, STL; can leverage ModelIO natively. |
| **Fonts** | TTF, OTF, WOFF, WOFF2, EOT (5 formats) | Specialized typography web development task. | Can be supported via `fontforge` or `woff2_compress` CLI integration. |
| **Geospatial Data** | GeoJSON, KML, GPX, Shapefile (5 formats) | GIS map data. | GeoJSON and GPX are standard JSON/XML; can easily be added to `DataEngine` in Swift. |
| **Korean HWP / HWPX**| HWP, HWPX (2 formats) | South Korean government/institutional specific format. Filee uses custom `rhwp` engine. | Very low demand outside South Korea. |
| **Multi-Format Archives**| 7Z, RAR, TAR, GZ, XZ, ISO, DMG (28 formats) | Filee bundles 7-Zip (`7z.exe`). Morph natively supports `.zip`. | Can integrate Homebrew `p7zip` (`7z`) or macOS native `tar` / `ditto` / `hdiutil`. |
| **Subtitle Formats** | SRT, ASS, VTT, SMI, LRC (9 formats) | Filee converts text subtitle streams. Morph currently supports Whisper transcription to text. | Can add a lightweight Swift Subtitle parser to convert between SRT and VTT. |

---

## 🚀 How to Run Morph Conversions

All supported conversions can be executed via:
1. **The Native Liquid Glass Floating Launcher** (`⌥Space` or `swift run morph`)
2. **The Headless CLI** (`morph [command] [args]`)
3. **The Raycast Extension** (`raycast-extension/`)

```bash
# Check status of all native & modular engines
morph engines

# OCR Text Recognition (Apple Vision)
morph ocr invoice.pdf --searchable
morph ocr receipt.png

# Apple App Icon (.icns)
morph icon brand.png

# Video Conversion & GIF Creation (FFmpeg)
morph video recording.mov --to mp4
morph video demo.mov --to gif --fps 15
morph audio podcast.mp4 --to mp3

# Office Documents (LibreOffice)
morph office proposal.docx
morph office slides.pptx

# Structured Data (Foundation)
morph data config.json --to plist
morph data catalog.csv --to json --pretty

# Privacy & Metadata (ImageIO)
morph metadata photo.jpg --strip

# Images & PDFs
morph compress photo.jpg --preset maximum
morph convert icon.png --to webp
morph merge a.pdf b.pdf --output bundle.pdf
morph split book.pdf --range "1-5, 10"
```
