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

public struct GoldenGateBridgeBackdrop: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        LiquidGlass.nightBay,
                        LiquidGlass.bayTeal.opacity(0.90),
                        LiquidGlass.bridgeOrangeDeep.opacity(0.48),
                        LiquidGlass.nightBay
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        LiquidGlass.bridgeOrange.opacity(0.34),
                        LiquidGlass.bridgeOrange.opacity(0.08),
                        .clear
                    ],
                    center: .bottomLeading,
                    startRadius: 20,
                    endRadius: proxy.size.width * 0.72
                )
                .blendMode(.plusLighter)

                RadialGradient(
                    colors: [
                        LiquidGlass.fogHighlight.opacity(0.20),
                        .clear
                    ],
                    center: UnitPoint(x: 0.74, y: 0.10),
                    startRadius: 10,
                    endRadius: proxy.size.width * 0.54
                )
                .blendMode(.screen)

                GoldenGateBridgeSilhouette()
                    .stroke(
                        LiquidGlass.bridgeOrange.opacity(0.34),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
                    )
                    .frame(height: proxy.size.height * 0.32)
                    .offset(y: proxy.size.height * 0.32)
                    .blur(radius: 0.3)

                GoldenGateBridgeSilhouette()
                    .stroke(
                        LiquidGlass.fogHighlight.opacity(0.10),
                        style: StrokeStyle(lineWidth: 0.7, lineCap: .round, lineJoin: .round)
                    )
                    .frame(height: proxy.size.height * 0.32)
                    .offset(y: proxy.size.height * 0.315)

                Rectangle()
                    .fill(.black.opacity(0.18))
                    .blendMode(.multiply)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct GoldenGateBridgeSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.maxY * 0.82
        let leftTowerX = rect.minX + rect.width * 0.24
        let rightTowerX = rect.minX + rect.width * 0.76
        let towerTop = rect.minY + rect.height * 0.15
        let deckY = rect.minY + rect.height * 0.63

        path.move(to: CGPoint(x: rect.minX - rect.width * 0.05, y: deckY))
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * 0.05, y: deckY))

        for towerX in [leftTowerX, rightTowerX] {
            let towerWidth = rect.width * 0.030
            path.move(to: CGPoint(x: towerX - towerWidth, y: baseline))
            path.addLine(to: CGPoint(x: towerX - towerWidth, y: towerTop))
            path.move(to: CGPoint(x: towerX + towerWidth, y: baseline))
            path.addLine(to: CGPoint(x: towerX + towerWidth, y: towerTop))
            path.move(to: CGPoint(x: towerX - towerWidth * 1.55, y: towerTop))
            path.addLine(to: CGPoint(x: towerX + towerWidth * 1.55, y: towerTop))
            path.move(to: CGPoint(x: towerX - towerWidth * 1.30, y: towerTop + rect.height * 0.12))
            path.addLine(to: CGPoint(x: towerX + towerWidth * 1.30, y: towerTop + rect.height * 0.12))
        }

        path.move(to: CGPoint(x: rect.minX - rect.width * 0.05, y: deckY + rect.height * 0.08))
        path.addCurve(
            to: CGPoint(x: rect.maxX + rect.width * 0.05, y: deckY + rect.height * 0.08),
            control1: CGPoint(x: rect.width * 0.30, y: rect.minY - rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.70, y: rect.minY - rect.height * 0.20)
        )

        for i in 0...18 {
            let x = rect.minX + rect.width * CGFloat(i) / 18.0
            let normalized = abs((CGFloat(i) / 18.0) - 0.5) * 2.0
            let cableY = deckY - rect.height * (0.38 * (1.0 - normalized * normalized))
            path.move(to: CGPoint(x: x, y: deckY))
            path.addLine(to: CGPoint(x: x, y: cableY))
        }

        return path
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

                        GoldenGateBridgeBackdrop()

                        // Floating HUD material layer. The bridge treatment stays behind the functional glass surface.
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThickMaterial.opacity(0.82))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        // Inner stroke (glass edge) to simulate the physical edge of glass
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LiquidGlass.bridgeOrange.opacity(0.22), lineWidth: 0.7)
                    }
                    .shadow(
                        color: Color.black.opacity(0.26),
                        radius: 30,
                        x: 0,
                        y: 16
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
