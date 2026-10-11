# Morph 🪄

A lightweight, privacy-focused, offline-first native macOS utility application for everyday image and PDF operations, featuring an authentic Apple **Liquid Glass** UI and built strictly following Apple's **Human Interface Guidelines (HIG)**.

Morph combines the speed and keyboard-first experience of Raycast and Spotlight with high-performance local image and PDF engines built with AppKit, SwiftUI, ImageIO, Core Graphics, Quartz, and PDFKit.

---

## ✨ Key Highlights & Apple HIG Compliance

- **100% Offline & Private**: Zero cloud processing, zero remote conversion APIs, zero accounts, zero analytics. Works completely without an internet connection.
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

### Image Utilities
| Command | Synonyms / Keywords | Supported Formats | Description |
| :--- | :--- | :--- | :--- |
| **Compress Image** | *"Make image smaller"*, *"reduce photo size"*, *"shrink photo"* | JPEG, PNG, HEIC, WebP, TIFF | 3 Presets: **Light** (quality priority), **Balanced** (optimal), **Maximum** (downscaling). Honest savings reporting. |
| **Convert Image** | *"Change image format"*, *"png to jpg"*, *"heic to jpg"* | JPEG, PNG, HEIC, WebP | Preserves alpha or safely flattens transparent pixels to white when converting to JPEG. |
| **Resize Image** | *"Scale photo"*, *"change resolution"*, *"downscale"* | JPEG, PNG, HEIC, WebP | Exact Dimensions (W×H), Max Width, Max Height, or Percentage scale with aspect ratio preservation. |
| **Batch Process** | *"Batch compress"*, *"bulk convert"*, *"multiple images"* | Multi-file queue | Memory-safe streaming processing (avoids decoding all images at once into RAM). |
| **Image to PDF** | *"Pictures to PDF"*, *"photos to pdf"*, *"scan to pdf"* | Multi-image to PDF | Bundles images into a multi-page PDF document with Match Image, A4, or US Letter sizing. |

### PDF Utilities
| Command | Synonyms / Keywords | Operations | Description |
| :--- | :--- | :--- | :--- |
| **Compress PDF** | *"Reduce pdf size"*, *"shrink pdf"*, *"compact pdf"* | Light, Balanced, Maximum | Stream cleaning and raster downsampling (144 / 96 DPI) while preserving vector text and lines. |
| **Merge PDF** | *"Combine pdfs"*, *"join pdf"*, *"stitch pdf"* | Multi-PDF assembly | Combines multiple documents while preserving page dimensions, mediabox, and orientations. |
| **Split PDF** | *"Separate pdf pages"*, *"cut pdf"*, *"extract pages"* | All pages or custom ranges | Split every page into separate files or extract custom ranges (e.g. `1-3, 5, 8-10`). |
| **PDF to Image** | *"PDF to JPG"*, *"pdf to png"*, *"export pages"* | PNG (lossless), JPEG | Renders pages at 72 DPI (Screen), 150 DPI (Print), or 300 DPI (High Res) with predictable filenames. |
| **Rotate Pages** | *"Rotate document"*, *"turn pdf page"*, *"flip pdf"* | 90°, 180°, 270° | Live rotating visual page thumbnails with instant orientation feedback. |
| **Extract Pages** | *"Extract pdf pages"*, *"isolate pages"* | Interactive page selection | Visually select specific pages via thumbnails to extract into a new standalone PDF. |
| **Remove Pages** | *"Delete page from pdf"*, *"remove pdf pages"* | Visual page deletion | Mark unwanted pages visually with trash badges and remove them safely. |
| **Reorder Pages** | *"Rearrange pdf pages"*, *"change page order"* | Live position strip | Reorganize document sequence with interactive thumbnail repositioning controls. |


---

## 🧱 Architecture

```
morph/
├── Morph.app/                 # Packaged and signed native macOS application bundle
├── Sources/
│   ├── MorphKit/              # Reusable Core Engine & Design System Library
│   │   ├── Core/
│   │   │   ├── CLIHandler.swift          # Headless CLI argument parsing and execution
│   │   │   ├── ConversionRegistry.swift  # Search ranking, synonym matching, file suggestions
│   │   │   ├── FileProcessor.swift       # High-level coordinator
│   │   │   ├── FileSafetyService.swift   # Non-overwriting naming, temp cleaning, validation
│   │   │   ├── ImageEngine.swift         # ImageIO/CoreGraphics compression, resize, format
│   │   │   ├── PDFEngine.swift           # PDFKit merge, split, compress, render, rotate
│   │   │   ├── QuickLookManager.swift    # Native macOS Quick Look QLPreviewPanel controller
│   │   │   └── SoundEffectManager.swift  # Auditory feedback for success/error
│   │   ├── DesignSystem/
│   │   │   ├── LiquidGlassTokens.swift   # Specular gradients, materials, corner radii, a11y tokens
│   │   │   ├── LiquidGlassBackground.swift # ultraThinMaterial background with specular border & a11y fallback
│   │   │   ├── GlassCard.swift           # Layered glass container with tactile hover & active states
│   │   │   ├── GlassButton.swift         # HIG buttons with shortcut pill badges, tooltips & ghost mode
│   │   │   ├── GlassPill.swift           # Status tags & monospaced savings pills (-42% saved)
│   │   │   ├── GlassSearchBar.swift      # Spotlight search field with focus illumination & clear button
│   │   │   └── GlassComparisonView.swift # Interactive Before/After split comparison slider with double-click reset
│   │   ├── Features/
│   │   │   ├── FloatingPanelController.swift # NSPanel floating window manager with keyboard monitors
│   │   │   ├── GlobalHotkeyManager.swift     # Native Carbon ⌥Space hotkey registration
│   │   │   ├── ImageOperationsView.swift     # Image settings and presets with Quick Look
│   │   │   ├── LauncherView.swift            # Main Spotlight/Raycast style interface
│   │   │   ├── LauncherViewModel.swift       # Observable state & navigation pipeline
│   │   │   ├── PDFOperationsView.swift       # PDF options and range configuration with Quick Look
│   │   │   ├── ResultPreviewView.swift       # Stats, before/after slider, drag-out, Finder actions
│   │   │   ├── SettingsView.swift            # HIG-compliant Preferences sheet (⌘,)
│   │   │   └── StatusBarController.swift     # macOS Menu Bar item with quick action routing
│   │   └── Models/
│   │       ├── ConversionCommand.swift
│   │       ├── ConversionResult.swift
│   │       ├── ConversionSettings.swift
│   │       ├── FileItem.swift
│   │       ├── PreferencesManager.swift      # Persistent UserDefaults configuration
│   │       └── ProcessingError.swift
│   ├── morph/
│   │   └── morph.swift        # Native macOS App entry point & NSApplicationDelegate
│   └── MorphTestRunner/
│       ├── main.swift         # Comprehensive automated unit test runner
│       └── Verification.swift # Live real-world file conversion pipeline validator
├── bundle.sh                  # Application packaging and codesigning script
└── Package.swift              # Swift Package Manager configuration
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

## 💻 CLI & Raycast Bridge

Morph includes a built-in headless CLI for terminal power-users and Raycast extensions:

```bash
# Inspect file metadata (supports --json)
morph info photo.jpg --json

# Compress images or PDFs
morph compress photo.jpg --preset maximum --json

# Convert formats with alpha preservation
morph convert logo.png --to webp

# Resize images
morph resize banner.jpg --scale 50

# Merge PDFs
morph merge doc1.pdf doc2.pdf --output merged.pdf

# Split PDF ranges
morph split book.pdf --range "1-5, 10"

# PDF to High-Res Images
morph to-image presentation.pdf --dpi 300
```

---

## ⚡️ Raycast Extension

A complete Raycast extension template is included in `raycast-extension/`:
1. Navigate to `raycast-extension/`
2. Install dependencies: `npm install`
3. Link into Raycast: `npm run dev`
4. Invoke Morph commands directly from Raycast!

---

## 🔒 Privacy & Safety Guarantee

- **Zero Overwriting**: Morph generates unique destination names (`doc-compressed (1).pdf`) if a target file already exists.
- **Local Isolation**: All ImageIO, Core Graphics, and PDFKit operations execute on the local CPU/GPU.
- **Zero Cloud**: Tested and verified with network disconnected.
