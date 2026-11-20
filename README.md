# Morph 🪄

A lightweight, privacy-focused, offline-first native macOS utility application for everyday conversion, multimedia, document, and data operations, featuring an authentic Apple **Liquid Glass** UI and built strictly following Apple's **Human Interface Guidelines (HIG)**.

Morph combines the speed and keyboard-first experience of Raycast and Spotlight with high-performance local image, document, multimedia, and data engines inspired by [Filee](https://github.com/KnifeLemon/Filee)'s modular multi-engine architecture — pairing Apple-native macOS frameworks (Vision, ImageIO, CoreGraphics, PDFKit, Foundation) with modular CLI tool integrations (FFmpeg, LibreOffice, Pandoc, ExifTool, Whisper).

---

## ✨ Key Highlights & Apple HIG Compliance

- **100% Offline & Private**: Zero cloud processing, zero remote conversion APIs, zero accounts, zero analytics. Works completely without an internet connection.
- **Menu Bar Drop Shelf & Actions Drag & Drop**:
  - **Menu Bar Drop Target**: Drag any file(s) up to the menu bar icon to automatically reveal the translucent Liquid Glass holding shelf.
  - **Temporary File Holding**: Store files, images, PDFs, audio tracks, and web links temporarily with live high-res thumbnails and 2-line truncated titles.
  - **Drag Out to Anywhere**: Directly drag any stored card out (`.onDrag`) to Finder, Mail, Slack, Discord, or desktop browsers.
  - **Actions Drag & Drop Bar**: Drag files from the grid directly onto action pills at the bottom (**Compress**, **Convert**, **To PDF**, **OCR**, **Make Icon**, **Audio**, **Strip EXIF**) for instant processing!
- **Filee-Inspired Modular Engine Architecture**:
  - **Zero-Download Native Backends**: Apple Vision Framework for on-device Neural Engine OCR; Apple `iconutil` for `.icns` app icon generation; Foundation for JSON/Plist/XML/CSV data processing; ImageIO/CoreGraphics for lossless and lossy raster/vector manipulation.
  - **Pluggable CLI Tool Discovery**: Automatically discovers `/opt/homebrew/bin`, `/usr/local/bin`, and standard macOS application bundles for FFmpeg, LibreOffice, Pandoc, ExifTool, and Whisper.
  - **In-App Tool Diagnostics**: Live "Engines & Tools" Preferences tab (`⌘,`) showing installation status, detected binaries, version strings, and one-click copyable Homebrew commands.
- **Dual Floating Island Architecture**:
  - **Layer A (Floating Search Capsule)**: Detached hovering capsule pill with centered search, dropped file badges, and `•••` presentation switcher.
  - **12pt Wallpaper Gap**: Transparent separation allowing the macOS wallpaper to float between controls.
  - **Layer B (28pt Squircle Card)**: Deep translucent obsidian liquid glass card with specular highlight rim and category chips.
- **Dual Presentation UX (List & Grid)**:
  - **Top Shelf + List Mode**: 5 prominent squircle tool icons on a top shelf, followed by a hairline divider and scannable list rows.
  - **7-Column Squircle Grid Mode**: Symmetric grid of handcrafted app squircles with vibrant gradients and specular lighting.
  - Switched seamlessly via the `•••` menu or Preferences (`⌘,`).
- **Apple Human Interface Guidelines (HIG)**:
  - **Dynamic System Materials**: Authentic `.hudWindow` backdrops with dual-layer shadows (ambient depth + contact shadow) and specular rim highlights.
  - **Accessibility Compliance**: Automatically honors macOS **Reduce Transparency** (solid system background fallback) and **Reduce Motion** (disables spring bounces).
  - **San Francisco Typography**: Strict typographic scale with `.monospacedDigit()` for all numbers, file sizes, percentages, dimensions, and DPI values.
  - **Native Quick Look (Spacebar)**: Preview any input or generated file instantly via system `QLPreviewPanel`.
  - **Direct Manipulation**: Drag output files directly from the results card to Finder, Desktop, Mail, or Slack (`.onDrag`).
  - **Keyboard-First Controls**: Full 4-way keyboard navigation (`↑`/`↓`/`←`/`→` to navigate, `↩` to select/execute, `Space` to Quick Look, `⌘O` to browse/open, `⌘C` to copy, `⌘R` to reveal in Finder, `⌘,` for Settings, `⎋` to go back/dismiss).
  - **Native macOS Preferences (`⌘,`)**: Output destination preferences (Same as source, Desktop, Downloads), view mode, audio chimes, and default optimization presets.
  - **Subtle Auditory Feedback**: Native macOS system sound effects on completion (`Glass`) and error (`beep`).
- **Interactive Before/After Comparison**: Real-time split comparison slider for image compression with double-click reset and accurate byte savings reporting.
- **Safe by Design**: Never overwrites original files, generates collision-safe output names (`image-compressed (1).jpg`), cleans up intermediate temporary files, and validates output file integrity.
- **Brand & Design Guidelines**: Detailed specifications available in [DESIGN_AND_BRAND_GUIDELINES.md](file:///Users/yuvi/Developer/morph/DESIGN_AND_BRAND_GUIDELINES.md).

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `⌥Space` | **Toggle Morph Launcher** | System-Wide Global Hotkey |
| `↑` / `↓` | **Navigate Operations** | Command search list |
| `↩` | **Select / Execute** | Main launcher & options views |
| `Space` | **Quick Look Preview** | Results view & dropped files |
| `⌘O` | **Open File Dialog / Open Result** | Launcher header & Results view |
| `⌘S` | **Save As (Native Dialog)** | Results view |
| `⌘C` | **Copy Output to Clipboard** | Results view |
| `⌘R` | **Reveal in Finder** | Results view |
| `⌘,` | **Preferences / Settings** | Anywhere |
| `⎋` | **Back / Dismiss / Close Quick Look** | Anywhere |
| `⌘W` | **Hide Window** | Floating panel |
| `⌘Q` | **Quit Morph** | Anywhere |

---

## 🛠 Features & Supported Commands

> 📄 **Complete Format Matrix**: See [SUPPORTED_FORMATS.md](file:///Users/yuvi/Developer/morph/SUPPORTED_FORMATS.md) for a complete format-by-format breakdown and full comparison with [Filee](https://filee.sh/formats/) (255 formats in 18 categories).

### 1. Image Utilities (Apple ImageIO & Core Graphics)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Compress Image** | *"Make image smaller"*, *"reduce photo size"* | JPEG, PNG, HEIC, WebP, TIFF | 3 Presets: **Light** (quality priority), **Balanced** (optimal), **Maximum** (downscaling). Honest savings reporting. |
| **Convert Image** | *"Change image format"*, *"png to jpg"* | JPEG, PNG, HEIC, WebP | Preserves alpha or safely flattens transparent pixels to white when converting to JPEG. |
| **Resize Image** | *"Scale photo"*, *"change resolution"* | JPEG, PNG, HEIC, WebP | Exact Dimensions (W×H), Max Width, Max Height, or Percentage scale with aspect ratio preservation. |
| **Batch Process** | *"Batch compress"*, *"bulk convert"* | Multi-file queue | Memory-safe streaming processing (avoids decoding all images at once into RAM). |
| **Image to PDF** | *"Pictures to PDF"*, *"photos to pdf"* | Multi-image to PDF | Bundles images into a multi-page PDF document with Match Image, A4, or US Letter sizing. |

### 2. PDF Utilities (Apple PDFKit & Quartz)
| Command | Synonyms / Keywords | Operations | Description |
| :--- | :--- | :--- | :--- |
| **Compress PDF** | *"Reduce pdf size"*, *"shrink pdf"* | Light, Balanced, Maximum | Stream cleaning and raster downsampling (144 / 96 DPI) while preserving vector text and lines. |
| **Merge PDF** | *"Combine pdfs"*, *"join pdf"* | Multi-PDF assembly | Combines multiple documents while preserving page dimensions, mediabox, and orientations. |
| **Split PDF** | *"Separate pdf pages"*, *"cut pdf"* | All pages or custom ranges | Split every page into separate files or extract custom ranges (e.g. `1-3, 5, 8-10`). |
| **PDF to Image** | *"PDF to JPG"*, *"pdf to png"* | PNG (lossless), JPEG | Renders pages at 72 DPI (Screen), 150 DPI (Print), or 300 DPI (High Res) with predictable filenames. |
| **Rotate Pages** | *"Rotate document"*, *"flip pdf"* | 90°, 180°, 270° | Live rotating visual page thumbnails with instant orientation feedback. |
| **Extract Pages** | *"Extract pdf pages"*, *"isolate pages"* | Interactive page selection | Visually select specific pages via thumbnails to extract into a new standalone PDF. |
| **Remove Pages** | *"Delete page from pdf"* | Visual page deletion | Mark unwanted pages visually with trash badges and remove them safely. |
| **Reorder Pages** | *"Rearrange pdf pages"* | Live position strip | Reorganize document sequence with interactive thumbnail repositioning controls. |

### 3. OCR & Vision Utilities (Native Apple Vision Framework)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Extract Text (OCR)** | *"ocr"*, *"text recognition"*, *"read image"* | PNG, JPG, HEIC, TIFF, WebP, PDF | Offline Apple Neural Engine text recognition. Exports recognized text directly to formatted `.txt`. |
| **Searchable PDF** | *"pdf ocr"*, *"make pdf searchable"* | Scanned PDF, Images | Generates a clean PDF document with an embedded, invisible, selectable text layer aligned to images. |

### 4. Apple Icons & Vector Graphics (iconutil & CoreGraphics)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Make App Icon (.icns)** | *"create icns"*, *"mac icon"*, *"app icon"* | PNG, JPEG, TIFF | Automatically renders full multi-resolution Apple iconsets (`16x16` up to `512x512@2x` / 1024px) via `iconutil`. |
| **Extract PNG from Icon** | *"icns to png"*, *"unpack icon"* | Apple `.icns` | Extracts the highest resolution 1024×1024 master artwork as a crisp, lossless transparent PNG. |
| **Convert Vector (SVG)** | *"svg to pdf"*, *"svg to png"*, *"rasterize"* | SVG | Renders vector graphics to resolution-independent vector PDF or high-resolution raster PNG/JPEG (1x, 2x, 4x scale). |

### 5. Media & Audio/Video Utilities (Modular FFmpeg Engine)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Convert Video** | *"mp4 to mov"*, *"video converter"* | MP4, MOV, MKV, WebM, AVI | High-performance hardware-accelerated video transcoding via FFmpeg. |
| **Convert Video to GIF** | *"video to gif"*, *"make animated gif"* | MP4, MOV, WebM → GIF | Two-pass palette generation (`palettegen` / `paletteuse`) with configurable FPS (10–30) and scaling. |
| **Compress Video** | *"shrink video"*, *"reduce video size"* | MP4, MOV, MKV | CRF-based smart compression: Light (CRF 20), Balanced (CRF 26), Maximum (CRF 32). |
| **Extract Audio** | *"rip audio"*, *"video to mp3"*, *"soundtrack"* | Video → MP3, M4A, WAV, AAC, FLAC | Extracts audio stream from video with optional format conversion. |
| **Convert Audio** | *"audio converter"*, *"wav to mp3"* | MP3, M4A, WAV, AAC, FLAC, OGG | High-fidelity audio transcoding and compression. |

### 6. Office Documents & Markup (LibreOffice & Pandoc)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Document to PDF** | *"docx to pdf"*, *"convert word"*, *"office"* | DOCX, DOC, PPTX, PPT, XLSX, XLS, ODT, RTF | Headless LibreOffice conversion maintaining native layouts, fonts, and vector graphics. |
| **Markdown to PDF** | *"md to pdf"*, *"render markdown"* | Markdown (`.md`, `.markdown`) | High-fidelity PDF rendering with Pandoc, featuring native CoreGraphics typography fallback. |

### 7. Structured Data & Metadata (Foundation & ImageIO)
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Convert Structured Data** | *"json to plist"*, *"plist to xml"*, *"json to csv"* | JSON, Plist, XML, CSV | Fast Foundation-native serialization with formatting and indentation options. |
| **Prettify JSON** | *"format json"*, *"indent json"*, *"beautify"* | JSON | Formats unindented JSON files into clean 2-space indented output. |
| **Inspect Metadata** | *"view exif"*, *"check camera info"* | JPEG, PNG, TIFF, HEIC | Reads camera model, lens, exposure, dimensions, color space, and GPS tags. |
| **Strip Metadata** | *"remove exif"*, *"remove gps"*, *"clean photo"* | JPEG, PNG, TIFF, HEIC | Completely removes private EXIF, GPS location coordinates, and IPTC data without re-encoding loss. |

---

## ⚡️ Modular Engine Architecture

Morph adapts the battle-tested modular engine pattern from [Filee](https://github.com/KnifeLemon/Filee) into native Swift:

```
┌────────────────────────────────────────────────────────┐
│                   MorphKit Engine Manager              │
└───────────┬────────────────────────────────┬───────────┘
            │                                │
            ▼                                ▼
┌───────────────────────────┐    ┌───────────────────────────┐
│     Native macOS Engines  │    │    External CLI Engines   │
│  (100% Offline / Zero DL) │    │  (Dynamic Discovery /     │
│                           │    │   Homebrew Integration)   │
│ • Apple Vision (OCR)      │    │                           │
│ • Apple ImageIO & Quartz  │    │ • FFmpeg (Video/Audio)    │
│ • Apple PDFKit            │    │ • LibreOffice (Office)    │
│ • Apple iconutil (Icons)  │    │ • Pandoc (Markdown)       │
│ • Apple Foundation (Data) │    │ • ExifTool (Metadata)     │
│ • Apple CoreImage (Codes) │    │ • Whisper (Speech)        │
└───────────────────────────┘    └───────────────────────────┘
```

When an external CLI tool is missing, Morph:
1. **Never crashes or hangs**: Gracefully alerts the user through `ProcessingError.toolMissing`.
2. **Displays One-Click Copy Buttons**: Liquid Glass UI banners offer direct buttons to copy `brew install <tool>`.
3. **Offers Native Fallbacks**: Where applicable (e.g., Markdown to PDF, Metadata inspection/stripping), Morph seamlessly falls back to Apple-native frameworks.

---

## 💻 Headless CLI Reference

Morph includes a built-in headless CLI for automation, shell scripts, and Raycast extensions:

```bash
# Check status of all native & modular engines
morph engines
morph engines --json

# Text Recognition (Apple Vision OCR)
morph ocr scan.png                     # Extract text to scan-ocr.txt
morph ocr scan.png --searchable        # Generate searchable PDF

# Apple App Icons (.icns)
morph icon logo.png                    # Generate multi-resolution logo.icns
morph icon app.icns --extract          # Extract 1024px PNG

# Audio & Video (FFmpeg)
morph video recording.mov --to mp4
morph video demo.mov --to gif --fps 15
morph video footage.mp4 --to mp4 --crf 26
morph audio clip.mp4 --to mp3

# Office Documents (LibreOffice / Pandoc)
morph office proposal.docx             # Converts to proposal.pdf
morph office notes.md                  # Converts to notes.pdf

# Structured Data (Foundation)
morph data config.json --to plist
morph data table.csv --to json --pretty

# Privacy & Metadata (ImageIO)
morph metadata photo.jpg               # Print EXIF and GPS summary
morph metadata photo.jpg --strip       # Create clean photo-clean.jpg

# Image & PDF Essentials
morph compress photo.jpg --preset maximum --json
morph convert logo.png --to webp
morph resize banner.jpg --scale 50
morph merge doc1.pdf doc2.pdf --output merged.pdf
morph split book.pdf --range "1-5, 10"
morph to-image presentation.pdf --dpi 300
```

---

## ⚡️ Raycast Extension

A complete Raycast extension template is included in `raycast-extension/`:
1. Navigate to `raycast-extension/`
2. Install dependencies: `npm install`
3. Link into Raycast: `npm run dev`

Included Raycast Commands:
- **Compress Image or PDF** (`compress`)
- **Convert Image Format** (`convert`)
- **Merge PDFs** (`merge-pdf`)
- **Extract Text with OCR** (`ocr`)
- **Generate Apple App Icon** (`make-icon`)
- **Convert Video or Audio** (`convert-media`)

---

## 🧱 Project Structure

```
morph/
├── Morph.app/                 # Packaged and signed native macOS application bundle
├── Sources/
│   ├── MorphKit/              # Reusable Core Engine & Design System Library
│   │   ├── Core/
│   │   │   ├── CLIHandler.swift          # Headless CLI argument parsing and execution
│   │   │   ├── ConversionRegistry.swift  # Search ranking, synonym matching, file suggestions
│   │   │   ├── DataEngine.swift          # JSON, Plist, XML, and CSV conversions
│   │   │   ├── EngineManager.swift       # Tool detection, version auditing, async execution
│   │   │   ├── FileProcessor.swift       # High-level coordinator
│   │   │   ├── FileSafetyService.swift   # Non-overwriting naming, temp cleaning, validation
│   │   │   ├── IconEngine.swift          # Apple iconutil .icns generation and extraction
│   │   │   ├── ImageEngine.swift         # ImageIO/CoreGraphics compression, resize, format
│   │   │   ├── MediaEngine.swift         # FFmpeg video/audio transcoding and GIF generation
│   │   │   ├── MetadataEngine.swift      # ImageIO EXIF/GPS inspection and stripping
│   │   │   ├── OCREngine.swift           # Apple Vision text recognition & searchable PDF
│   │   │   ├── OfficeEngine.swift        # LibreOffice & Pandoc document conversion
│   │   │   ├── PDFEngine.swift           # PDFKit merge, split, compress, render, rotate
│   │   │   ├── QuickLookManager.swift    # Native macOS Quick Look QLPreviewPanel controller
│   │   │   ├── ShelfManager.swift        # Temporary holding shelf & action execution manager
│   │   │   ├── SoundEffectManager.swift  # Auditory feedback for success/error
│   │   │   └── VectorEngine.swift        # SVG to PDF vector and raster conversion
│   │   ├── DesignSystem/
│   │   │   ├── LiquidGlassTokens.swift   # Specular gradients, materials, corner radii, a11y tokens
│   │   │   ├── LiquidGlassBackground.swift # ultraThinMaterial background with specular border
│   │   │   ├── GlassCard.swift           # Layered glass container with tactile hover & active states
│   │   │   ├── GlassButton.swift         # HIG buttons with shortcut pill badges, tooltips
│   │   │   ├── GlassPill.swift           # Status tags & monospaced savings pills (-42% saved)
│   │   │   ├── GlassSearchBar.swift      # Spotlight search field with focus illumination
│   │   │   ├── GlassComparisonView.swift # Interactive Before/After split comparison slider
│   │   │   └── ToolSquircleIcon.swift    # Custom handcrafted 28pt app icons with SF symbols
│   │   ├── Features/
│   │   │   ├── DropShelfView.swift       # Menu bar drop shelf with holding grid & action targets
│   │   │   ├── EnginesDetailView.swift   # Live engine status & one-click install commands
│   │   │   ├── FloatingPanelController.swift # NSPanel floating window manager with keyboard monitors
│   │   │   ├── GlobalHotkeyManager.swift # Native Carbon ⌥Space hotkey registration
│   │   │   ├── ImageOperationsView.swift # Image settings and presets with Quick Look
│   │   │   ├── LauncherView.swift        # Main Spotlight/Raycast style interface
│   │   │   ├── LauncherViewModel.swift   # Observable state & navigation pipeline
│   │   │   ├── PDFOperationsView.swift   # PDF options and range configuration with Quick Look
│   │   │   ├── ResultPreviewView.swift   # Stats, before/after slider, drag-out, Finder actions
│   │   │   ├── SettingsView.swift        # HIG-compliant Preferences sheet (⌘,)
│   │   │   ├── SettingsWindowView.swift  # Preferences window with General and Engines tabs
│   │   │   ├── StatusBarController.swift # macOS Menu Bar item with quick action routing
│   │   │   └── UniversalOperationsView.swift # Liquid Glass parameters & missing tool banners
│   │   └── Models/
│   │       ├── ConversionCommand.swift
│   │       ├── ConversionResult.swift
│   │       ├── ConversionSettings.swift
│   │       ├── FileItem.swift
│   │       ├── PreferencesManager.swift  # Persistent UserDefaults configuration
│   │       ├── ProcessingError.swift
│   │       └── ShelfItem.swift           # Model for temporary holding shelf items & action pills
│   ├── morph/
│   │   └── morph.swift        # Native macOS App entry point & NSApplicationDelegate
│   └── MorphTestRunner/
│       ├── main.swift         # Comprehensive automated unit test runner (14 suites)
│       └── Verification.swift # Live real-world file conversion pipeline validator
├── bundle.sh                  # Application packaging and codesigning script
├── Package.swift              # Swift Package Manager configuration
└── raycast-extension/         # Full Raycast extension integration
```

---

## 🚀 Building & Running

### 1. Build and Run Directly
```bash
swift run morph
```

### 2. Package Native `Morph.app` Bundle
```bash
./bundle.sh
open Morph.app
```

### 3. Run Automated Engine & File Tests
```bash
swift run morph-test-runner
```

---

## 🔒 Privacy & Safety Guarantee

- **Zero Overwriting**: Morph generates unique destination names (`doc-compressed (1).pdf`) if a target file already exists.
- **Local Isolation**: All ImageIO, Vision, Core Graphics, and PDFKit operations execute on the local Apple Silicon / Intel processor.
- **Zero Cloud**: Tested and verified with network disconnected.
