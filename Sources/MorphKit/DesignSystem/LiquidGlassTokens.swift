import SwiftUI
import AppKit

/// Apple Liquid Glass Design Language & macOS HIG Tokens for Morph
public enum LiquidGlass {
    // MARK: - Morph Brand Colors (Golden Gate Inspired)
    /// Primary brand accent (#C74634), inspired by the Golden Gate Bridge.
    /// Used sparingly for: selected/highlighted controls, focus indicators, important brand moments, and primary actions.
    public static let brandAccent = Color(red: 199.0 / 255.0, green: 70.0 / 255.0, blue: 52.0 / 255.0)
    public static let brandAccentDeep = Color(red: 148.0 / 255.0, green: 42.0 / 255.0, blue: 30.0 / 255.0)
    public static let brandAccentLight = Color(red: 232.0 / 255.0, green: 105.0 / 255.0, blue: 86.0 / 255.0)

    // Backwards-compatible aliases
    public static var bridgeOrange: Color { brandAccent }
    public static var bridgeOrangeDeep: Color { brandAccentDeep }
    public static let fogHighlight = Color(red: 0.94, green: 0.89, blue: 0.82)
    public static let bayTeal = Color(red: 0.08, green: 0.27, blue: 0.31)
    public static let nightBay = Color(red: 0.035, green: 0.055, blue: 0.065)

    /// Restrained accent gradient for primary actions
    public static var brandAccentGradient: LinearGradient {
        LinearGradient(
            colors: [
                brandAccent,
                brandAccentDeep
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var bridgeAccentGradient: LinearGradient {
        brandAccentGradient
    }

    public static var bridgeTint: Color {
        brandAccent
    }

    // MARK: - Spacing Tokens
    public enum Spacing {
        public static let spaceXS: CGFloat = 4.0
        public static let spaceSM: CGFloat = 8.0
        public static let spaceMD: CGFloat = 12.0
        public static let spaceLG: CGFloat = 16.0
        public static let spaceXL: CGFloat = 24.0
        public static let space2XL: CGFloat = 32.0
    }

    public static let spaceXS: CGFloat = Spacing.spaceXS
    public static let spaceSM: CGFloat = Spacing.spaceSM
    public static let spaceMD: CGFloat = Spacing.spaceMD
    public static let spaceLG: CGFloat = Spacing.spaceLG
    public static let spaceXL: CGFloat = Spacing.spaceXL
    public static let space2XL: CGFloat = Spacing.space2XL

    // MARK: - Corner Radii Tokens
    public static let windowRadius: CGFloat = 20.0
    public static let contentRadius: CGFloat = 12.0
    public static let dialogRadius: CGFloat = 14.0
    public static let cardRadius: CGFloat = 10.0
    public static let buttonRadius: CGFloat = 7.0
    public static let controlRadius: CGFloat = 6.0
    public static let smallControlRadius: CGFloat = 5.0
    public static let pillRadius: CGFloat = 999.0

    // MARK: - Control Heights
    public static let smallControlHeight: CGFloat = 22.0
    public static let regularControlHeight: CGFloat = 28.0
    public static let prominentControlHeight: CGFloat = 34.0
    public static let searchFieldHeight: CGFloat = 42.0

    // MARK: - Semantic System Colors
    public static var primaryLabel: Color { Color.primary }
    public static var secondaryLabel: Color { Color.secondary }
    public static var tertiaryLabel: Color { Color.secondary.opacity(0.65) }
    public static var windowBackground: Color { Color(nsColor: .windowBackgroundColor) }
    public static var controlBackground: Color { Color(nsColor: .controlBackgroundColor) }
    public static var separator: Color { Color(nsColor: .separatorColor) }
    public static var selectedContentBackground: Color { Color(nsColor: .selectedContentBackgroundColor) }
    public static var systemGreen: Color { Color.green }
    public static var systemOrange: Color { Color.orange }
    public static var systemRed: Color { Color.red }

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

    // MARK: - Materials Hierarchy (Layer A & Layer B)
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

    // MARK: - Shadows (Restrained Depth)
    /// Floating launcher window elevation
    public static let floatingShadowColor = Color.black.opacity(0.20)
    public static let floatingShadowRadius: CGFloat = 24.0
    public static let floatingShadowY: CGFloat = 10.0

    // Backwards-compatible aliases
    public static let ambientShadowColor = Color.black.opacity(0.18)
    public static let ambientShadowRadius: CGFloat = 24.0
    public static let ambientShadowY: CGFloat = 10.0
    public static let contactShadowColor = Color.black.opacity(0.08)
    public static let contactShadowRadius: CGFloat = 4.0
    public static let contactShadowY: CGFloat = 1.5

    public static let cardShadowColor = Color.black.opacity(0.04)
    public static let cardShadowRadius: CGFloat = 3.0
    public static let cardShadowY: CGFloat = 1.0

    public static let controlShadowColor = Color.black.opacity(0.06)
    public static let controlShadowRadius: CGFloat = 2.0
    public static let controlShadowY: CGFloat = 1.0

    // MARK: - Specular Borders & Highlights
    /// Delicate top specular highlight simulating Apple's physical glass edge
    public static var specularBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                Color.white.opacity(0.06),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Subtle card border that respects macOS Light and Dark appearance
    public static var cardBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Color.white.opacity(0.04),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Hairline separator matching macOS HIG separators
    public static var hairlineColor: Color {
        Color(nsColor: .separatorColor).opacity(0.35)
    }

    // MARK: - Functional Gradients
    public static var accentGradient: LinearGradient {
        brandAccentGradient
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
        return .spring(response: 0.28, dampingFraction: 0.82)
    }

    public static var quickSpring: Animation {
        if shouldReduceMotion {
            return .linear(duration: 0.05)
        }
        return .spring(response: 0.18, dampingFraction: 0.85)
    }
}

// MARK: - Semantic Typography Tokens
public enum MorphTypography {
    /// Main window or tool title
    public static var windowTitle: Font { .system(size: 15, weight: .semibold, design: .default) }
    /// Section heading
    public static var sectionHeading: Font { .system(size: 11, weight: .bold, design: .default) }
    /// Primary item title
    public static var primaryItemTitle: Font { .system(size: 13, weight: .semibold, design: .default) }
    /// Body text
    public static var bodyText: Font { .system(size: 13, weight: .regular, design: .default) }
    /// Supporting metadata
    public static var supportingMetadata: Font { .system(size: 11, weight: .regular, design: .default) }
    /// Keyboard hints
    public static var keyboardHint: Font { .system(size: 10, weight: .medium, design: .monospaced) }
    /// Caption
    public static var caption: Font { .system(size: 10, weight: .regular, design: .default) }
}

// MARK: - Typography Scale (Backwards Compatibility & Native Scale)
public extension Font {
    static func figmaLargeTitle(emphasized: Bool = false) -> Font {
        .system(size: 24, weight: emphasized ? .bold : .regular, design: .default)
    }

    static func figmaTitle1(emphasized: Bool = false) -> Font {
        .system(size: 20, weight: emphasized ? .bold : .regular, design: .default)
    }

    static func figmaTitle2(emphasized: Bool = false) -> Font {
        .system(size: 16, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static func figmaTitle3(emphasized: Bool = false) -> Font {
        .system(size: 14, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static var figmaHeadline: Font {
        .system(size: 13, weight: .semibold, design: .default)
    }

    static func figmaBody(emphasized: Bool = false) -> Font {
        .system(size: 13, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static func figmaCallout(emphasized: Bool = false) -> Font {
        .system(size: 12, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static func figmaSubheadline(emphasized: Bool = false) -> Font {
        .system(size: 11, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static func figmaFootnote(emphasized: Bool = false) -> Font {
        .system(size: 10, weight: emphasized ? .semibold : .regular, design: .default)
    }

    static func figmaCaption1(emphasized: Bool = false) -> Font {
        .system(size: 10, weight: emphasized ? .medium : .regular, design: .default)
    }

    static func figmaCaption2(emphasized: Bool = false) -> Font {
        .system(size: 9, weight: emphasized ? .medium : .regular, design: .default)
    }
}

@MainActor
public final class HoverState: ObservableObject {
    @Published public var isHovered: Bool = false
    public init() {}
}
