import SwiftUI
import AppKit

public enum GlassButtonVariant: Equatable {
    case primary
    case secondary
    case tinted
    case destructive
    case prominentDestructive
    case ghost
}

public enum GlassButtonSize {
    case small
    case regular
    case large

    public var height: CGFloat {
        switch self {
        case .small: return LiquidGlass.smallControlHeight
        case .regular: return LiquidGlass.regularControlHeight
        case .large: return LiquidGlass.prominentControlHeight
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .regular: return 12
        case .large: return 16
        }
    }

    public var font: Font {
        switch self {
        case .small: return .figmaCaption1(emphasized: true)
        case .regular: return .figmaBody(emphasized: true)
        case .large: return .figmaCallout(emphasized: true)
        }
    }
}

public struct GlassButton: View {
    private let title: String
    private let icon: String?
    private let shortcutBadge: String?
    private let variant: GlassButtonVariant
    private let size: GlassButtonSize
    private let tooltip: String?
    private let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @StateObject private var hover = HoverState()

    public init(
        _ title: String,
        icon: String? = nil,
        shortcutBadge: String? = nil,
        variant: GlassButtonVariant = .secondary,
        size: GlassButtonSize = .regular,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.shortcutBadge = shortcutBadge
        self.variant = variant
        self.size = size
        self.tooltip = tooltip
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: size == .small ? 4 : 6) {
                if let icon {
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: size == .small ? 10 : 12, weight: .medium))
                }

                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                }

                if let shortcut = shortcutBadge {
                    Text(shortcut)
                        .font(.figmaCaption2(emphasized: true))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(shortcutBadgeBackground)
                        }
                        .foregroundStyle(shortcutBadgeForeground)
                }
            }
            .padding(.horizontal, variant == .ghost ? 6 : size.horizontalPadding)
            .frame(minHeight: size.height)
            .background {
                if variant != .ghost {
                    RoundedRectangle(cornerRadius: LiquidGlass.buttonRadius, style: .continuous)
                        .fill(buttonBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: LiquidGlass.buttonRadius, style: .continuous)
                                .stroke(borderStroke, lineWidth: 0.5)
                        }
                        .shadow(
                            color: hover.isHovered ? Color.black.opacity(0.12) : Color.clear,
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                } else if hover.isHovered {
                    RoundedRectangle(cornerRadius: LiquidGlass.buttonRadius, style: .continuous)
                        .fill(.quaternary)
                }
            }
            .foregroundStyle(contentForegroundStyle)
        }
        .buttonStyle(.plain)
        .scaleEffect(hover.isHovered && !LiquidGlass.shouldReduceMotion ? 1.01 : 1.0)
        .animation(LiquidGlass.quickSpring, value: hover.isHovered)
        .onHover { hovering in
            hover.isHovered = hovering
        }
        .help(tooltip ?? (shortcutBadge != nil && !title.isEmpty ? "\(title) (\(shortcutBadge!))" : title))
        .accessibilityLabel(title.isEmpty ? (tooltip ?? "Button") : title)
    }

    // MARK: - Background Styling
    private var buttonBackground: AnyShapeStyle {
        if reduceTransparency || LiquidGlass.shouldReduceTransparency {
            switch variant {
            case .primary:
                return AnyShapeStyle(Color.accentColor)
            case .secondary:
                return AnyShapeStyle(hover.isHovered ? Color(nsColor: .controlColor) : Color(nsColor: .controlBackgroundColor))
            case .tinted:
                return AnyShapeStyle(Color.accentColor.opacity(hover.isHovered ? 0.22 : 0.14))
            case .destructive:
                return AnyShapeStyle(Color.red.opacity(hover.isHovered ? 0.20 : 0.12))
            case .prominentDestructive:
                return AnyShapeStyle(Color.red)
            case .ghost:
                return AnyShapeStyle(Color.clear)
            }
        }

        switch variant {
        case .primary:
            return AnyShapeStyle(SubtleTheme.accentGradient)
        case .secondary:
            return hover.isHovered ? AnyShapeStyle(SubtleTheme.surfaceHover) : AnyShapeStyle(SubtleTheme.cardBackgroundSubtle)
        case .tinted:
            return AnyShapeStyle(SubtleTheme.accentTint)
        case .destructive:
            return AnyShapeStyle(SubtleTheme.redTint)
        case .prominentDestructive:
            return AnyShapeStyle(SubtleTheme.red)
        case .ghost:
            return AnyShapeStyle(Color.clear)
        }
    }

    // MARK: - Border Stroke
    private var borderStroke: AnyShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(Color.white.opacity(0.20))
        case .prominentDestructive:
            return AnyShapeStyle(Color.white.opacity(0.20))
        case .secondary:
            return AnyShapeStyle(hover.isHovered ? SubtleTheme.cardBorderHover : SubtleTheme.cardBorder)
        case .tinted:
            return AnyShapeStyle(SubtleTheme.accentBorder)
        case .destructive:
            return AnyShapeStyle(SubtleTheme.red.opacity(0.35))
        case .ghost:
            return AnyShapeStyle(Color.clear)
        }
    }

    // MARK: - Foreground Content Style
    private var contentForegroundStyle: AnyShapeStyle {
        switch variant {
        case .primary, .prominentDestructive:
            return AnyShapeStyle(Color.white)
        case .tinted:
            return AnyShapeStyle(Color.accentColor)
        case .destructive:
            return AnyShapeStyle(Color.red)
        case .secondary:
            return AnyShapeStyle(.primary)
        case .ghost:
            return hover.isHovered ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
        }
    }

    private var shortcutBadgeBackground: AnyShapeStyle {
        switch variant {
        case .primary, .prominentDestructive:
            return AnyShapeStyle(Color.white.opacity(0.20))
        default:
            return AnyShapeStyle(.quaternary)
        }
    }

    private var shortcutBadgeForeground: AnyShapeStyle {
        switch variant {
        case .primary, .prominentDestructive:
            return AnyShapeStyle(Color.white)
        default:
            return AnyShapeStyle(.secondary)
        }
    }
}
