import SwiftUI
import AppKit

/// Bridges AppKit's NSVisualEffectView to SwiftUI for desktop wallpaper tinting and vibrancy.
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State
    public var cornerRadius: CGFloat

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        cornerRadius: CGFloat = LiquidGlass.windowRadius
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}

/// Floating Search Capsule Modifier (Layer A) matching the design reference:
/// - Distinct capsule pill hovering above the main surface
/// - Rich dark liquid glass with specular top-edge highlight
/// - Soft ambient drop shadow
public struct LiquidGlassCapsuleModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    public func body(content: Content) -> some View {
        content
            .background {
                if systemReduceTransparency || LiquidGlass.shouldReduceTransparency {
                    Capsule()
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .overlay {
                            Capsule().stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        // Desktop wallpaper blur
                        VisualEffectView(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            state: .active,
                            cornerRadius: 24
                        )

                        // Deep atmospheric dark obsidian tint
                        LinearGradient(
                            colors: [
                                Color(red: 18 / 255, green: 28 / 255, blue: 36 / 255).opacity(0.85),
                                Color(red: 10 / 255, green: 18 / 255, blue: 24 / 255).opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipShape(Capsule())
                    .overlay {
                        // Specular rim stroke
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.32),
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.75
                            )
                    }
                    .shadow(color: Color.black.opacity(0.38), radius: 14, x: 0, y: 7)
                }
            }
    }
}

/// Main Glass Content Surface Modifier (Layer B) matching the design reference:
/// - 28pt continuous corner radius squircle
/// - Deep translucent obsidian liquid glass with subtle teal/slate undertone
/// - Specular highlight rim and deep elevation shadow
public struct LiquidGlassSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @ObservedObject private var preferences = PreferencesManager.shared
    var cornerRadius: CGFloat = 28.0

    public func body(content: Content) -> some View {
        content
            .background {
                if systemReduceTransparency || LiquidGlass.shouldReduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5)
                        }
                } else {
                    ZStack {
                        // Desktop wallpaper blur
                        VisualEffectView(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            state: .active,
                            cornerRadius: cornerRadius
                        )

                        // Deep atmospheric dark glass tint matching reference screenshot
                        LinearGradient(
                            colors: [
                                Color(red: 14 / 255, green: 26 / 255, blue: 34 / 255).opacity(0.84),
                                Color(red: 8 / 255, green: 16 / 255, blue: 22 / 255).opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        // Specular top-edge hairline highlight
                        if preferences.showSpecularHighlight {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.26),
                                            Color.white.opacity(0.06),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.75
                                )
                        }
                    }
                }
            }
    }
}

public extension View {
    /// Applies native Liquid Glass floating search capsule styling
    func liquidGlassCapsule() -> some View {
        self.modifier(LiquidGlassCapsuleModifier())
    }

    /// Applies native Liquid Glass content surface styling (28pt continuous corner squircle)
    func liquidGlassSurface(radius: CGFloat = 28.0) -> some View {
        self.modifier(LiquidGlassSurfaceModifier(cornerRadius: radius))
    }

    /// Backwards-compatible alias for whole-window modifier
    func liquidGlassWindow(radius: CGFloat = 28.0) -> some View {
        self.modifier(LiquidGlassSurfaceModifier(cornerRadius: radius))
    }
}
