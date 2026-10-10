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
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary), lineWidth: isSelected ? 1.5 : 0.5)
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(SubtleTheme.accentTint) : AnyShapeStyle(hover.isHovered ? SubtleTheme.surfaceHover : SubtleTheme.cardBackgroundSubtle))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(isSelected ? AnyShapeStyle(SubtleTheme.accentBorder) : AnyShapeStyle(hover.isHovered ? SubtleTheme.cardBorderHover : SubtleTheme.cardBorder), lineWidth: isSelected ? 1.0 : 0.6)
                        }
                        .shadow(
                            color: Color.black.opacity(hover.isHovered ? 0.14 : 0.06),
                            radius: hover.isHovered ? 6 : 2,
                            x: 0,
                            y: hover.isHovered ? 2 : 1
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
