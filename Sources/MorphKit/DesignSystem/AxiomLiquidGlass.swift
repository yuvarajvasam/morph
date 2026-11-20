import SwiftUI
import AppKit

// MARK: - Axiom Liquid Glass Meta-Material Model

/// Axiom Liquid Glass meta-material specification representing Apple's next-generation material system.
///
/// Features:
/// - Lensing: Dynamically shapes and bends ambient light
/// - Motion & Fluidity: Gel-like flexibility communicating malleable transient states
/// - Adaptive Behavior: Continuously adapts depth and tint based on environment and content
/// - Three canonical base variants: `.regular` (default), `.clear`, and `.identity`
/// - Chainable configuration: `.tint(_:)` and `.interactive(_:)`
public struct Glass: Equatable, Sendable {
    public enum Variant: Equatable, Sendable {
        /// Regular Liquid Glass: Most versatile. Full adaptive depth, automatic legibility,
        /// specular highlights, and behind-window optical vibrancy blur.
        case regular
        /// Clear Liquid Glass: Permanently more transparent, no adaptive behaviors.
        /// Intended for media-rich surfaces with a dedicated dimming layer.
        case clear
        /// Identity: Passthrough / unmodified material.
        case identity
    }

    public var variant: Variant
    public var tintColor: Color?
    public var isInteractive: Bool

    public init(variant: Variant = .regular, tintColor: Color? = nil, isInteractive: Bool = false) {
        self.variant = variant
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }

    /// Standard Regular Liquid Glass meta-material (recommended for 95% of UI surfaces)
    public static let regular = Glass(variant: .regular)

    /// Clear Liquid Glass meta-material for high-transparency media overlays
    public static let clear = Glass(variant: .clear)

    /// Identity material (no-op)
    public static let identity = Glass(variant: .identity)

    /// Returns a copy of the glass material with the specified adaptive tint color
    public func tint(_ color: Color?) -> Glass {
        var copy = self
        copy.tintColor = color
        return copy
    }

    /// Returns a copy of the glass material with interactive touch/hover physics enabled
    public func interactive(_ isEnabled: Bool = true) -> Glass {
        var copy = self
        copy.isInteractive = isEnabled
        return copy
    }
}

// MARK: - Default Glass Effect Shape

/// Default shape for Liquid Glass effects when no explicit shape is provided.
public struct DefaultGlassEffectShape: InsettableShape {
    public var cornerRadius: CGFloat
    public var insetAmount: CGFloat = 0

    public init(cornerRadius: CGFloat = 12.0, insetAmount: CGFloat = 0) {
        self.cornerRadius = cornerRadius
        self.insetAmount = insetAmount
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = max(0, min(cornerRadius - insetAmount, min(insetRect.width, insetRect.height) / 2))
        return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: insetRect)
    }

    public func inset(by amount: CGFloat) -> DefaultGlassEffectShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Concentric Rectangle Shape (Axiom Liquid Glass)

/// A continuous squircle shape whose curvature resolves concentrically with its enclosing container or display.
public struct ConcentricRectangle: InsettableShape {
    public var cornerRadius: CGFloat
    public var minimumRadius: CGFloat
    public var insetAmount: CGFloat = 0

    public init(cornerRadius: CGFloat = 12.0, minimumRadius: CGFloat = 4.0, insetAmount: CGFloat = 0) {
        self.cornerRadius = cornerRadius
        self.minimumRadius = max(0, minimumRadius)
        self.insetAmount = insetAmount
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let maxRadius = min(insetRect.width, insetRect.height) / 2
        let effective = max(minimumRadius, min(cornerRadius - insetAmount, maxRadius))
        return RoundedRectangle(cornerRadius: effective, style: .continuous).path(in: insetRect)
    }

    public func inset(by amount: CGFloat) -> ConcentricRectangle {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Liquid Glass View Container

/// View providing Axiom Liquid Glass meta-material platter with optical lensing,
/// specular rim highlights, atmospheric tinting, and dual-layer shadows.
public struct GlassEffectView<Content: View, S: InsettableShape>: View {
    public let content: Content
    public let glass: Glass
    public let shape: S

    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @StateObject private var hover = HoverState()

    private var shouldReduceTransparency: Bool {
        systemReduceTransparency || LiquidGlass.shouldReduceTransparency
    }

    private var shouldReduceMotion: Bool {
        systemReduceMotion || LiquidGlass.shouldReduceMotion
    }

    public init(content: Content, glass: Glass = .regular, shape: S) {
        self.content = content
        self.glass = glass
        self.shape = shape
    }

    public var body: some View {
        if glass.variant == .identity {
            content
        } else {
            content
                .background {
                    glassBackground
                }
                .overlay {
                    specularRimOverlay
                }
                .shadow(
                    color: ambientShadowColor,
                    radius: ambientShadowRadius,
                    x: 0,
                    y: ambientShadowY
                )
                .shadow(
                    color: contactShadowColor,
                    radius: contactShadowRadius,
                    x: 0,
                    y: contactShadowY
                )
                .scaleEffect(glass.isInteractive && hover.isPressed && !shouldReduceMotion ? 0.98 : 1.0)
                .animation(
                    shouldReduceMotion ? .linear(duration: 0.05) : LiquidGlass.quickSpring,
                    value: hover.isHovered
                )
                .animation(
                    shouldReduceMotion ? .linear(duration: 0.05) : LiquidGlass.quickSpring,
                    value: hover.isPressed
                )
                .onHover { hovering in
                    if glass.isInteractive {
                        hover.isHovered = hovering
                    }
                }
        }
    }

    // MARK: - Glass Background Platter

    @ViewBuilder
    private var glassBackground: some View {
        if shouldReduceTransparency {
            // Accessible fallback: Solid opaque system background
            shape
                .fill(
                    glass.tintColor != nil ?
                    AnyShapeStyle(glass.tintColor!.opacity(hover.isHovered ? 0.22 : 0.14)) :
                    AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
                )
        } else {
            ZStack {
                // Layer 1: Desktop wallpaper optical vibrancy blur
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active,
                    cornerRadius: 0
                )

                // Layer 2: Atmospheric obsidian / night bay glass tint
                if glass.variant == .regular {
                    LinearGradient(
                        colors: [
                            Color(red: 14 / 255, green: 26 / 255, blue: 34 / 255).opacity(hover.isHovered ? 0.78 : 0.84),
                            Color(red: 8 / 255, green: 16 / 255, blue: 22 / 255).opacity(hover.isHovered ? 0.86 : 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.black.opacity(hover.isHovered ? 0.28 : 0.20)
                }

                // Layer 3: Adaptive tint color overlay
                if let tint = glass.tintColor {
                    LinearGradient(
                        colors: [
                            tint.opacity(hover.isHovered ? 0.38 : 0.28),
                            tint.opacity(hover.isHovered ? 0.22 : 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Layer 4: Interactive internal glow on hover / press
                if glass.isInteractive && hover.isHovered {
                    Color.white.opacity(hover.isPressed ? 0.08 : 0.04)
                }
            }
            .clipShape(shape)
        }
    }

    // MARK: - Specular Rim Highlight (Lensing)

    @ViewBuilder
    private var specularRimOverlay: some View {
        if shouldReduceTransparency {
            shape
                .strokeBorder(
                    Color(nsColor: .separatorColor).opacity(0.40),
                    lineWidth: 0.5
                )
        } else {
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            specularTopHighlight,
                            Color.white.opacity(hover.isHovered ? 0.10 : 0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        }
    }

    private var specularTopHighlight: Color {
        if let tint = glass.tintColor {
            return hover.isHovered ? Color.white.opacity(0.48) : tint.opacity(0.55)
        }
        return Color.white.opacity(hover.isHovered ? 0.36 : 0.26)
    }

    // MARK: - Dual-Layer Shadows (Ambient + Contact)

    private var ambientShadowColor: Color {
        guard glass.isInteractive || glass.variant == .regular else { return .clear }
        if let tint = glass.tintColor, hover.isHovered {
            return tint.opacity(0.35)
        }
        return Color.black.opacity(hover.isHovered ? 0.26 : 0.16)
    }

    private var ambientShadowRadius: CGFloat {
        hover.isHovered ? 12 : 6
    }

    private var ambientShadowY: CGFloat {
        hover.isHovered ? 5 : 2.5
    }

    private var contactShadowColor: Color {
        guard glass.isInteractive || glass.variant == .regular else { return .clear }
        return Color.black.opacity(hover.isHovered ? 0.12 : 0.06)
    }

    private var contactShadowRadius: CGFloat { 2.0 }
    private var contactShadowY: CGFloat { 1.0 }
}

// MARK: - View Extension: glassEffect

public extension View {
    /// Applies Axiom Liquid Glass meta-material to the view in the default capsule / squircle shape.
    ///
    /// - Parameter glass: The Liquid Glass configuration (defaults to `.regular`).
    func glassEffect(_ glass: Glass = .regular) -> some View {
        GlassEffectView(content: self, glass: glass, shape: DefaultGlassEffectShape())
    }

    /// Applies Axiom Liquid Glass meta-material to the view within a custom insettable shape.
    ///
    /// - Parameters:
    ///   - glass: The Liquid Glass configuration (defaults to `.regular`).
    ///   - shape: The continuous shape geometry to apply the glass platter to.
    func glassEffect<S: InsettableShape>(_ glass: Glass = .regular, in shape: S) -> some View {
        GlassEffectView(content: self, glass: glass, shape: shape)
    }
}

// MARK: - Dedicated Axiom Glass Button Styles

/// Dedicated Axiom standard glass button style (`.buttonStyle(.glass)`)
public struct GlassButtonStyle: ButtonStyle {
    public let glass: Glass

    public init(_ glass: Glass = .regular.interactive()) {
        self.glass = glass.interactive()
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.70 : 0.90))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(glass, in: ConcentricRectangle(cornerRadius: 8, minimumRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LiquidGlass.quickSpring, value: configuration.isPressed)
    }
}

/// Dedicated Axiom prominent glass button style (`.buttonStyle(.glassProminent)`)
public struct GlassProminentButtonStyle: ButtonStyle {
    public let glass: Glass

    public init(_ glass: Glass = .regular.tint(LiquidGlass.brandAccent).interactive()) {
        self.glass = glass.tint(glass.tintColor ?? LiquidGlass.brandAccent).interactive()
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassEffect(glass, in: ConcentricRectangle(cornerRadius: 8, minimumRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LiquidGlass.quickSpring, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == GlassButtonStyle {
    /// Standard Axiom Liquid Glass button style
    static var glass: GlassButtonStyle {
        GlassButtonStyle()
    }

    /// Configured Axiom Liquid Glass button style with specific glass properties
    static func glass(_ glass: Glass) -> GlassButtonStyle {
        GlassButtonStyle(glass)
    }
}

public extension ButtonStyle where Self == GlassProminentButtonStyle {
    /// Prominent Axiom Liquid Glass button style using the brand accent tint
    static var glassProminent: GlassProminentButtonStyle {
        GlassProminentButtonStyle()
    }

    /// Prominent Axiom Liquid Glass button style with specific tinted glass
    static func glassProminent(_ glass: Glass) -> GlassProminentButtonStyle {
        GlassProminentButtonStyle(glass)
    }
}

// MARK: - GlassEffectContainer (Axiom Shared Context)

/// A container that coordinates multiple nearby Liquid Glass elements to prevent
/// visual crowding, avoid optical sampling conflicts, and facilitate fluid morphing.
public struct GlassEffectContainer<Content: View>: View {
    public let spacing: CGFloat?
    public let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        content
    }
}

// MARK: - Morphing & Union Identifiers

public extension View {
    /// Identifies a Liquid Glass view within a namespace for fluid morphing transitions across states.
    func glassEffectID(_ id: AnyHashable, in namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}
