import SwiftUI
import AppKit

/// Figma "macOS 27 (Community)" Design System Tokens for Morph
public enum LiquidGlass {

    // MARK: - Corner Radii
    public static let windowRadius: CGFloat = 20.0
    public static let dialogRadius: CGFloat = 14.0
    public static let cardRadius: CGFloat = 12.0
    public static let buttonRadius: CGFloat = 7.0
    public static let controlRadius: CGFloat = 6.0
    public static let smallControlRadius: CGFloat = 5.0
    public static let pillRadius: CGFloat = 999.0

    // MARK: - Control Heights
    public static let smallControlHeight: CGFloat = 22.0
    public static let regularControlHeight: CGFloat = 28.0
    public static let prominentControlHeight: CGFloat = 34.0
    public static let searchFieldHeight: CGFloat = 38.0

    // MARK: - Accessibility Checks
    public static var shouldReduceTransparency: Bool {
        if UserDefaults.standard.string(forKey: "transparencyPreference") == "Reduced Transparency" {
            return true
        }
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    public static var shouldReduceMotion: Bool {
        if UserDefaults.standard.string(forKey: "animationPreference") == "Reduced Motion" {
            return true
        }
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    // MARK: - Figma Materials Hierarchy
    public static var ultrathinMaterial: AnyShapeStyle {
        if shouldReduceTransparency {
            return AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    public static var thinMaterial: AnyShapeStyle {
        if shouldReduceTransparency {
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
        }
        return AnyShapeStyle(.thinMaterial)
    }

    public static var regularMaterial: AnyShapeStyle {
        if shouldReduceTransparency {
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
        }
        return AnyShapeStyle(.regularMaterial)
    }

    public static var thickMaterial: AnyShapeStyle {
        if shouldReduceTransparency {
            return AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
        }
        return AnyShapeStyle(.thickMaterial)
    }

    public static var ultrathickMaterial: AnyShapeStyle {
        if shouldReduceTransparency {
            return AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
        }
        return AnyShapeStyle(.ultraThickMaterial)
    }

    // MARK: - Shadows (Multi-tier elevation)
    // 1. Window Ambient + Contact Shadows
    public static let ambientShadowColor = Color.black.opacity(0.24)
    public static let ambientShadowRadius: CGFloat = 36.0
    public static let ambientShadowY: CGFloat = 18.0

    public static let contactShadowColor = Color.black.opacity(0.12)
    public static let contactShadowRadius: CGFloat = 6.0
    public static let contactShadowY: CGFloat = 2.0

    // 2. Card Shadows
    public static let cardShadowColor = Color.black.opacity(0.06)
    public static let cardShadowRadius: CGFloat = 4.0
    public static let cardShadowY: CGFloat = 1.5

    // 3. Control Elevation
    public static let controlShadowColor = Color.black.opacity(0.08)
    public static let controlShadowRadius: CGFloat = 2.0
    public static let controlShadowY: CGFloat = 1.0

    // MARK: - Specular Borders & Highlights
    /// Dynamic Specular Rim Light (Light reflection at the top-leading corner)
    public static var specularBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.38),
                Color.white.opacity(0.12),
                Color(nsColor: .separatorColor).opacity(0.12),
                Color.white.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle Card Border that respects macOS Light and Dark appearance
    public static var cardBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                Color.white.opacity(0.06),
                Color(nsColor: .separatorColor).opacity(0.08),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Hairline separator matching Figma separators
    public static var hairlineColor: Color {
        Color(nsColor: .separatorColor).opacity(0.40)
    }

    // MARK: - Gradients & Accents
    public static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor,
                Color.accentColor.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var successGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.green,
                Color.mint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var destructiveGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.red,
                Color.red.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animation Springs
    public static var standardSpring: Animation {
        if shouldReduceMotion {
            return .linear(duration: 0.05)
        }
        return .spring(response: 0.30, dampingFraction: 0.82)
    }

    public static var quickSpring: Animation {
        if shouldReduceMotion {
            return .linear(duration: 0.05)
        }
        return .spring(response: 0.20, dampingFraction: 0.85)
    }
}

// MARK: - Subtle Colors Theme
public enum SubtleTheme {
    // Window & Card Surfaces
    public static let windowBackground = Color(red: 0.07, green: 0.08, blue: 0.10)
    public static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.85)
    public static let cardBackgroundSubtle = Color.white.opacity(0.04)
    public static let cardBorder = Color.white.opacity(0.08)
    public static let cardBorderHover = Color.white.opacity(0.15)
    public static let surfaceHover = Color.white.opacity(0.07)
    public static let innerHighlight = Color.white.opacity(0.04)

    // Primary Subtle Accent (Refined Slate-Blue)
    public static let accent = Color(red: 0.22, green: 0.46, blue: 0.82)
    public static let accentLight = Color(red: 0.35, green: 0.58, blue: 0.90)
    public static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.48, blue: 0.84),
            Color(red: 0.20, green: 0.40, blue: 0.74)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    public static let accentTint = Color(red: 0.22, green: 0.46, blue: 0.82).opacity(0.20)
    public static let accentBorder = Color(red: 0.35, green: 0.58, blue: 0.90).opacity(0.38)

    // Category / Tool Subtle Muted Tints
    public static let blue = Color(red: 0.35, green: 0.58, blue: 0.88)
    public static let blueTint = Color(red: 0.20, green: 0.38, blue: 0.65).opacity(0.25)

    public static let purple = Color(red: 0.65, green: 0.52, blue: 0.85)
    public static let purpleTint = Color(red: 0.42, green: 0.32, blue: 0.60).opacity(0.25)

    public static let green = Color(red: 0.42, green: 0.75, blue: 0.58)
    public static let greenTint = Color(red: 0.22, green: 0.50, blue: 0.36).opacity(0.25)

    public static let red = Color(red: 0.85, green: 0.45, blue: 0.45)
    public static let redTint = Color(red: 0.65, green: 0.25, blue: 0.25).opacity(0.25)

    public static let orange = Color(red: 0.88, green: 0.62, blue: 0.38)
    public static let orangeTint = Color(red: 0.68, green: 0.42, blue: 0.20).opacity(0.25)

    public static let gold = Color(red: 0.88, green: 0.68, blue: 0.35)
    public static let goldTint = Color(red: 0.65, green: 0.48, blue: 0.18).opacity(0.25)

    public static let cyan = Color(red: 0.40, green: 0.68, blue: 0.85)
    public static let cyanTint = Color(red: 0.22, green: 0.45, blue: 0.60).opacity(0.25)

    // Neutral Text & Element Grays
    public static let textPrimary = Color.white.opacity(0.95)
    public static let textSecondary = Color.white.opacity(0.60)
    public static let textTertiary = Color.white.opacity(0.38)
    public static let pillBackground = Color.white.opacity(0.05)
    public static let pillBackgroundActive = Color(red: 0.22, green: 0.46, blue: 0.82)

    // Convenience Aliases
    public static var bgCard: Color { cardBackground }
    public static var bgCardHover: Color { surfaceHover }
    public static var borderSubtle: Color { cardBorder }
    public static var borderFocus: Color { accentBorder }
    public static var accentBlue: Color { accent }
    public static var accentBlueGradient: LinearGradient { accentGradient }
    public static var accentPurple: Color { purple }
    public static var accentGreen: Color { green }
    public static var accentRed: Color { red }
    public static var accentOrange: Color { orange }
    public static var accentCyan: Color { cyan }
    public static var accentSteel: Color { Color(red: 0.45, green: 0.55, blue: 0.65) }
}


// MARK: - Figma Typography Scale
public extension Font {
    /// Large Title: 26pt
    static func figmaLargeTitle(emphasized: Bool = false) -> Font {
        .system(size: 26, weight: emphasized ? .bold : .regular, design: .default)
    }

    /// Title 1: 22pt
    static func figmaTitle1(emphasized: Bool = false) -> Font {
        .system(size: 22, weight: emphasized ? .bold : .regular, design: .default)
    }

    /// Title 2: 17pt
    static func figmaTitle2(emphasized: Bool = false) -> Font {
        .system(size: 17, weight: emphasized ? .bold : .regular, design: .default)
    }

    /// Title 3: 15pt
    static func figmaTitle3(emphasized: Bool = false) -> Font {
        .system(size: 15, weight: emphasized ? .semibold : .regular, design: .default)
    }

    /// Headline: 13pt Semibold
    static var figmaHeadline: Font {
        .system(size: 13, weight: .semibold, design: .default)
    }

    /// Body: 13pt
    static func figmaBody(emphasized: Bool = false) -> Font {
        .system(size: 13, weight: emphasized ? .semibold : .regular, design: .default)
    }

    /// Callout: 12pt
    static func figmaCallout(emphasized: Bool = false) -> Font {
        .system(size: 12, weight: emphasized ? .semibold : .regular, design: .default)
    }

    /// Subheadline: 11pt
    static func figmaSubheadline(emphasized: Bool = false) -> Font {
        .system(size: 11, weight: emphasized ? .semibold : .regular, design: .default)
    }

    /// Footnote: 10pt
    static func figmaFootnote(emphasized: Bool = false) -> Font {
        .system(size: 10, weight: emphasized ? .semibold : .regular, design: .default)
    }

    /// Caption 1: 10pt
    static func figmaCaption1(emphasized: Bool = false) -> Font {
        .system(size: 10, weight: emphasized ? .medium : .regular, design: .default)
    }

    /// Caption 2: 9pt
    static func figmaCaption2(emphasized: Bool = false) -> Font {
        .system(size: 9, weight: emphasized ? .medium : .regular, design: .default)
    }
}

@MainActor
public final class HoverState: ObservableObject {
    @Published public var isHovered: Bool = false
    public init() {}
}
