import SwiftUI
import AppKit

/// Calm content surface (Layer B) adhering to macOS HIG:
/// - Provides clean contrast and readability without heavy nested glass blur layers
/// - Uses subtle system background tints and hairline borders
/// - Eliminates heavy artificial drop shadows on ordinary content
public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let isSelected: Bool

    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @StateObject private var hover = HoverState()

    private var shouldReduceTransparency: Bool {
        systemReduceTransparency || LiquidGlass.shouldReduceTransparency
    }

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
                if shouldReduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? LiquidGlass.brandAccent.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(
                                    isSelected ? LiquidGlass.brandAccent.opacity(0.55) : Color(nsColor: .separatorColor).opacity(0.35),
                                    lineWidth: isSelected ? 1.0 : 0.5
                                )
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(cardBackgroundFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(cardBorderStroke, lineWidth: isSelected ? 1.0 : 0.5)
                        }
                        .shadow(
                            color: hover.isHovered ? Color.black.opacity(0.04) : Color.clear,
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                }
            }
            .onHover { hovering in
                withAnimation(LiquidGlass.quickSpring) {
                    hover.isHovered = hovering
                }
            }
    }

    private var cardBackgroundFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.12))
        }
        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.40))
    }

    private var cardBorderStroke: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.55))
        }
        return AnyShapeStyle(Color.primary.opacity(0.06))
    }
}
