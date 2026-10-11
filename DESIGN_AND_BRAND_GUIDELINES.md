# Morph — Design & Brand Guidelines

## 🌟 Overview & Design Philosophy

Morph is designed to feel like an authentic, future-forward macOS utility built with Apple's **Liquid Glass** design language and strictly adhering to the **macOS Human Interface Guidelines (HIG)**.

Combining the immediacy of Spotlight, the command palette ergonomics of Raycast, and a bespoke obsidian translucent aesthetic, Morph delivers an extraordinary tactile experience for everyday file transformations.

---

## 🏝 1. Dual Floating Island Architecture

Morph's visual interface departs from standard monolithic application windows. It consists of two detached, self-contained floating translucent glass islands hovering directly over the desktop wallpaper:

```
┌────────────────────────────────────────────────────────┐
│   [●]  Search Morph or drop a file...          •••     │  ← Layer A: Detached Floating Capsule
└────────────────────────────────────────────────────────┘
                          ↕ 12pt Gap
┌────────────────────────────────────────────────────────┐
│  [All Tools]  [Images]  [PDFs]  [Archives]  [QR & Bar] │  ← Category Filter Chips Row
│                                                        │
│  [✦]       [✦]       [✦]       [✦]       [✦]       [✦] │
│  Compress  Convert   Merge     Archive   QR Code   ... │  ← Dynamic Presentation:
│                                                        │    • Top Shelf + List Mode
│                                                        │    • 7-Column Squircle Grid Mode
│                                                        │
│  ────────────────────────────────────────────────────  │
│  ↑↓/←→ Navigate   ↩ Select   ⌘K Actions   100% Offline │  ← Persistent Shortcut Footer
└────────────────────────────────────────────────────────┘  ← Layer B: 28pt Continuous Squircle Card
```

### Layer A: The Floating Search Capsule
- **Geometry**: Continuous `Capsule()`, centered horizontally (`maxWidth: 460pt`), height `46pt`.
- **Material**: Deep Obsidian HUD glass (`.hudWindow` material + deep slate gradient `#121C24` to `#0A1218` at 88–92% opacity).
- **Specular Rim**: 0.75pt top-down hairline stroke gradient (`Color.white.opacity(0.32)` tapering to transparent).
- **Elevation**: Ambient floating shadow (`radius: 14pt, y: 7pt, opacity: 0.38`).
- **Interactive Elements**:
  - Left Glyph: Stylized Morph brand circular badge with crisp SF Symbol.
  - Search Field: Native plain text field with white label text and search prompt.
  - Quick Badges: Dropped file counts (`GlassPill`).
  - View Switcher Ellipsis (`•••`): Native menu allowing one-click switching between **Grid** and **List** presentation modes, plus quick access to Preferences (`⌘,`) and Actions (`⌘K`).

### 12pt Island Separation Gap
- Completely transparent spacing separating Layer A from Layer B.
- Enabled by `MorphFloatingPanel` with `isOpaque = false` and `backgroundColor = .clear`, allowing the macOS desktop wallpaper and wallpaper tinting to flow freely between both islands.

### Layer B: The 28pt Squircle Content Surface
- **Geometry**: `RoundedRectangle(cornerRadius: 28, style: .continuous)`.
- **Material**: Deep atmospheric Liquid Glass (`.hudWindow` with `#0E1A22` to `#081016` gradient).
- **Specular Top Highlight**: 0.75pt continuous edge stroke reflecting light from above.
- **Elevation**: Grounding deep ambient shadow (`radius: 26pt, y: 14pt, opacity: 0.42`).

---

## 🎨 2. Brand Color Palette & Squircle Tokens

### Core Brand Accents
- **Golden Gate Crimson (`brandAccent`)**: `#C74634` (RGB 199, 70, 52)
  - Primary accent for Morph brand identity, action buttons, focus rings, and image compression.
- **Deep Crimson (`brandAccentDeep`)**: `#942A1E` (RGB 148, 42, 30)
- **Golden Gate Light (`brandAccentLight`)**: `#E86956` (RGB 232, 105, 86)
- **Night Bay / Obsidian Slate**: `#081016` to `#121C24` (Base liquid glass container).

### App-Style Squircle Tool Gradients
Each tool features a distinct, vibrant macOS app-style gradient with specular top rim and drop shadow:

| Command Category | Command | Primary Gradient | Mood / Meaning |
| :--- | :--- | :--- | :--- |
| **Image** | **Compress Image** | `#EB4B37` → `#B4281E` | Golden Gate Crimson |
| **Image** | **Convert Image** | `#8255F5` → `#552DBE` | Electric Violet |
| **Image** | **Resize Image** | `#FF9B23` → `#E65F14` | Sunset Amber |
| **Image** | **Batch Images** | `#E137A5` → `#AA1973` | Vivid Magenta |
| **PDF** | **Merge PDF** | `#288CFF` → `#145FD2` | Royal Blue |
| **PDF** | **Split PDF** | `#19B9DC` → `#0A82AF` | Electric Cyan |
| **PDF** | **PDF to Image** | `#2DC873` → `#199650` | Emerald Green |
| **PDF** | **Rotate Pages** | `#9B50FA` → `#6928C8` | Lavender Purple |
| **Archive** | **Create Archive** | `#F5AA19` → `#CD780F` | Warm Gold |
| **Archive** | **Extract Archive** | `#FA7823` → `#CD4B14` | Flame Orange |
| **Archive** | **Inspect Archive** | `#647D8C` → `#3C505F` | Slate Steel |
| **QR & Barcode** | **Generate QR** | `#323C46` → `#192028` | Obsidian Carbon |
| **QR & Barcode** | **Scan QR** | `#1482FF` → `#0A5AC8` | Laser Blue |

---

## 🔲 3. Presentation Modes (Dual UX)

Conforming directly to the visual design references, Morph provides two complementary presentation models switched via the `•••` capsule menu or Preferences (`⌘,`):

### Mode 1: Top Shelf + List Mode (Design Reference 1)
- **Top Shelf**: A curated horizontal row of 5 large app squircles (`48×48pt`, corner radius `12pt`) featuring the top frequently used tools:
  1. Compress Image
  2. Convert Image
  3. Merge PDF
  4. Create Archive
  5. Generate QR Code
- **Hairline Divider**: Subtle 10% white separation line.
- **Vertical List**: Clean, scannable rows with `34×34pt` squircle icons, titles, descriptions, and category glass pills.
- **Selection State**: Translucent pill background (`Color.white.opacity(0.12)`) and return glyph (`↩`).

### Mode 2: 7-Column Squircle Grid Mode (Design References 2 & 3)
- **Layout**: Symmetric 7-column adaptive grid of `50×50pt` squircle icons.
- **Typography**: 2-line centered labels with clean white/semi-opaque typography.
- **Focus Indicator**: Specular focus border (`2pt`) and soft brand glow around the active squircle tile.
- **4-Way Keyboard Navigation**: Full directional arrow navigation (`↑`, `↓`, `←`, `→`) across rows and columns.

---

## 🎛 4. Category Filter Chips

- Located at the top of the 28pt squircle card.
- **Pills**:
  - `[All Tools]` (Grid symbol)
  - `[Images]` (Photo symbol)
  - `[PDFs]` (Document symbol)
  - `[Archives]` (Archive box symbol)
  - `[QR & Barcodes]` (QR symbol)
- **States**:
  - *Inactive*: `Color.white.opacity(0.06)` with `0.5pt` border, 70% white text.
  - *Active*: `Color.white.opacity(0.18)` with `0.75pt` crisp border, 100% white bold text.

---

## ♿️ 5. macOS HIG & Accessibility Guidelines

1. **Reduce Transparency**:
   - When macOS "Reduce Transparency" is enabled (or selected in Morph Preferences), materials fall back to solid high-contrast dark window surfaces (`Color(nsColor: .windowBackgroundColor)`).
2. **Reduce Motion**:
   - Animations switch from spring dynamics to instantaneous or linear transitions.
3. **High Contrast Typography**:
   - All text utilizes Apple's San Francisco font system (`.system(size:weight:)`) with `.monospacedDigit()` for all numbers, file sizes, and percentages.
4. **Keyboard-First Design**:
   - Every single function is accessible via hotkeys:
     - `⌥Space`: Summon Morph anywhere
     - `↑`/`↓`/`←`/`→`: 4-way arrow navigation
     - `↩`: Select / execute
     - `Space`: Quick Look preview
     - `⌘K`: Raycast Action Panel
     - `⌘O`: Open file dialog
     - `⌘,`: Settings window
     - `⎋`: Back / Dismiss
