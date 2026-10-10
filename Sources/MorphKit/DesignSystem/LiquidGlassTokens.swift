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
