# Morph — Design & Brand Guidelines

## 🌟 Overview & Design Philosophy

Morph is designed to feel like an authentic, future-forward macOS utility built with Apple's **Liquid Glass** design language and strictly adhering to the **macOS Human Interface Guidelines (HIG)**.

Combining the immediacy of Spotlight, the command palette ergonomics of Raycast, and a bespoke obsidian translucent aesthetic, Morph delivers an extraordinary tactile experience for everyday file transformations.

---

## 🖥 1. Unified Integrated Window Architecture

Morph features a unified continuous floating squircle card where the search bar and tool navigation are integrated directly into the top of the interface:

```
┌────────────────────────────────────────────────────────────────────────┐
│  [✦]  Search for apps or commands...                              •••  │  ← Integrated Search Header
├────────────────────────────────────────────────────────────────────────┤
│  [All Tools]  [Images]  [PDFs]  [Archives]  [QR & Barcodes]            │  ← Category Filter Chips
│                                                                        │
│  Suggestions                                                           │  ← Section Header
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ [✦] Compress Image                                        Images │  │  ← Selected Row Highlight
│  └──────────────────────────────────────────────────────────────────┘  │
│    [✦] Convert Image                                         Images    │
│    [✦] Merge PDF                                               PDFs    │
│    [✦] Create Archive                                      Archives    │
│    [✦] Generate QR Code                             QR & Barcodes      │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│  ↑↓/←→ Navigate   ↩ Select   Space Preview   ⌘K Actions   100% Offline │  ← Persistent Shortcut Footer
└────────────────────────────────────────────────────────────────────────┘  ← 28pt Continuous Squircle Card
```

### Top Integrated Search Header
- **Geometry**: Integrated directly within the top of the window card (`height: 52pt`, `padding(.horizontal, 18)`).
- **Emblem / Glyph**: Stylized translucent badge (`Color.white.opacity(0.08)`, 24×24pt) with crisp grid icon.
- **Search Field**: Native plain text field with high-contrast white text (`15pt`, regular weight) with prompt `Search for apps or commands...`.
- **Ellipsis Menu (`•••`)**: Located at the top right, providing instant switching between **List** and **Grid** content modes, plus quick access to Preferences (`⌘,`) and Actions (`⌘K`).

### The 28pt Squircle Content Surface
- **Geometry**: `RoundedRectangle(cornerRadius: 28, style: .continuous)`.
- **Material**: Deep atmospheric Liquid Glass (`.hudWindow` with `#0E1A22` to `#081016` obsidian gradient at 88–92% opacity).
- **Specular Top Highlight**: 0.75pt continuous edge stroke gradient (`Color.white.opacity(0.26)` tapering to transparent) reflecting light from above.
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

Conforming directly to the visual design references, Morph provides two complementary presentation models switched via the `•••` menu or Preferences (`⌘,`):

### Mode 1: Integrated Scannable List Mode (Reference Image)
- **Section Header**: Clean `Suggestions` header (`11pt`, semibold, 50% white text).
- **List Rows**:
  - `28×28pt` compact squircle icons (`cornerRadius: 7pt`).
  - Title (`13pt`, medium weight, white).
  - Subtitle / tag in secondary tint (`Color.white.opacity(0.45)`).
  - Right-aligned category label (`Images`, `PDFs`, `Archives`, `QR & Barcode`).
- **Selection State**: Translucent pill background (`Color.white.opacity(0.12)`) with return symbol (`↩`).

### Mode 2: 7-Column Squircle Grid Mode
- **Layout**: Symmetric 7-column adaptive grid of `50×50pt` squircle icons.
- **Typography**: 2-line centered labels with clean white typography.
- **Focus Indicator**: Specular focus border (`2pt`) and brand glow around the active squircle tile.
- **4-Way Keyboard Navigation**: Full directional arrow navigation (`↑`, `↓`, `←`, `→`).

---

## 🎛 4. Category Filter Chips

- Located directly below the search header:
  - `[All Tools]` (Grid symbol)
  - `[Images]` (Photo symbol)
  - `[PDFs]` (Document symbol)
  - `[Archives]` (Archive box symbol)
  - `[QR & Barcodes]` (QR symbol)
- **States**:
  - *Inactive*: `Color.white.opacity(0.06)` with `0.5pt` border, 70% white text.
  - *Active*: `Color.white.opacity(0.18)` with `0.75pt` crisp border, 100% white text.

---

## ♿️ 5. macOS HIG & Accessibility Guidelines

1. **Reduce Transparency**:
   - Automatically honors macOS "Reduce Transparency" with solid high-contrast dark window surfaces (`Color(nsColor: .windowBackgroundColor)`).
2. **Reduce Motion**:
   - Disables spring bounces in favor of linear or instant transitions.
3. **High Contrast Typography**:
   - San Francisco typography (`.system(size:weight:)`) with `.monospacedDigit()` for all numeric values.
4. **Keyboard-First Controls**:
   - Full 4-way arrow navigation (`↑`, `↓`, `←`, `→`), `↩` select/execute, `Space` Quick Look, `⌘K` Actions palette, `⌘O` browse/open, `⌘,` Settings.
