import SwiftUI
import AppKit

public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let isSelected: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @StateObject private var hover = HoverState()

    public init(
        cornerRadius: CGFloat = LiquidGlass.cardRadius,
        isSelected: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isSelected = isSelected
        self.content = content()
    }

    public var body: some View {
        content
            .background {
                if reduceTransparency || LiquidGlass.shouldReduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? LiquidGlass.bridgeTint.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(isSelected ? AnyShapeStyle(LiquidGlass.bridgeTint) : AnyShapeStyle(.quaternary), lineWidth: isSelected ? 1.5 : 0.5)
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(LiquidGlass.bridgeTint.opacity(0.18)) : AnyShapeStyle(.regularMaterial))
                        .overlay {
                            // Glass edge inner stroke
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(isSelected ? AnyShapeStyle(LiquidGlass.bridgeTint.opacity(0.80)) : AnyShapeStyle(.quaternary), lineWidth: isSelected ? 1.5 : 0.5)
                        }
                        .shadow(
                            color: Color.black.opacity(hover.isHovered ? 0.10 : 0.05),
                            radius: hover.isHovered ? 8 : 4,
                            x: 0,
                            y: hover.isHovered ? 3 : 1.5
                        )
                }
            }
            .onHover { hovering in
                withAnimation(LiquidGlass.quickSpring) {
                    hover.isHovered = hovering
                }
            }
    }
}
