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
        state: NSVisualEffectView.State = .followsWindowActiveState,
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

/// Enforces the Apple Human Interface Guidelines "Liquid Glass" spatial aesthetic:
/// Uses semantic materials, desktop wallpaper bleed-through, vibrancy, inner glass stroke, and elevation shadows.
public struct LiquidGlassBackgroundModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var cornerRadius: CGFloat = LiquidGlass.windowRadius

    public func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency || LiquidGlass.shouldReduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.5)
                        }
                        .shadow(
                            color: Color.black.opacity(0.15),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                } else {
                    ZStack {
                        // Desktop wallpaper blur bleeding through behind window
                        VisualEffectView(
                            material: .hudWindow,
                            blendingMode: .behindWindow,
                            state: .followsWindowActiveState,
                            cornerRadius: cornerRadius
                        )

                        // Floating HUD material layer
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThickMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        // Inner stroke (glass edge) to simulate the physical edge of glass
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.5)
                    }
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                }
            }
    }
}

public extension View {
    func liquidGlassWindow(radius: CGFloat = LiquidGlass.windowRadius) -> some View {
        self.modifier(LiquidGlassBackgroundModifier(cornerRadius: radius))
    }
}
