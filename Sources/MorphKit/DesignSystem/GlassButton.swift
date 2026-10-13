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
        case .small: return .system(size: 11, weight: .medium, design: .default)
        case .regular: return .system(size: 12, weight: .medium, design: .default)
        case .large: return .system(size: 13, weight: .semibold, design: .default)
        }
    }
}

/// Native macOS button conforming to HIG and Liquid Glass:
/// - Visually dominant primary action using Morph accent #C74634
/// - Restrained secondary actions with platform standard elevation
/// - Clear keyboard shortcut badges and tooltips
/// - Full support for hover, pressed, and disabled states
public struct GlassButton: View {
    private let title: String
    private let icon: String?
    private let shortcutBadge: String?
    private let variant: GlassButtonVariant
    private let size: GlassButtonSize
    private let tooltip: String?
    private let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.isEnabled) private var isEnabled
    @StateObject private var hover = HoverState()

    private var shouldReduceTransparency: Bool {
        systemReduceTransparency || LiquidGlass.shouldReduceTransparency
    }

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
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if let shortcut = shortcutBadge {
                    HStack(spacing: 2) {
                        ForEach(Array(shortcut.shortcutKeyTokens.enumerated()), id: \.offset) { _, token in
                            Text(token)
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .padding(.horizontal, token.count > 1 ? 4 : 2.5)
                                .padding(.vertical, 1)
                                .background {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(shortcutBadgeBackground)
                                }
                                .foregroundStyle(shortcutBadgeForeground)
                        }
                    }
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
                                .strokeBorder(borderStroke, lineWidth: 0.5)
                        }
                        .shadow(
                            color: hover.isHovered && isEnabled ? Color.black.opacity(0.08) : Color.clear,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                } else if hover.isHovered && isEnabled {
                    RoundedRectangle(cornerRadius: LiquidGlass.buttonRadius, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .foregroundStyle(contentForegroundStyle)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hover.isHovered = hovering
        }
        .help(tooltip ?? (shortcutBadge != nil && !title.isEmpty ? "\(title) (\(shortcutBadge!))" : title))
        .accessibilityLabel(title.isEmpty ? (tooltip ?? "Button") : title)
    }

    // MARK: - Background Styling
    private var buttonBackground: AnyShapeStyle {
        if shouldReduceTransparency {
            switch variant {
            case .primary:
                return AnyShapeStyle(LiquidGlass.brandAccent)
            case .secondary:
                return AnyShapeStyle(hover.isHovered ? Color(nsColor: .controlColor) : Color(nsColor: .controlBackgroundColor))
            case .tinted:
                return AnyShapeStyle(LiquidGlass.brandAccent.opacity(hover.isHovered ? 0.20 : 0.12))
            case .destructive:
                return AnyShapeStyle(Color.red.opacity(hover.isHovered ? 0.18 : 0.10))
            case .prominentDestructive:
                return AnyShapeStyle(Color.red)
            case .ghost:
                return AnyShapeStyle(Color.clear)
            }
        }

        switch variant {
        case .primary:
            return AnyShapeStyle(LiquidGlass.brandAccentGradient)
        case .secondary:
            return hover.isHovered ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.06))
        case .tinted:
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(hover.isHovered ? 0.20 : 0.12))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(hover.isHovered ? 0.20 : 0.12))
        case .prominentDestructive:
            return AnyShapeStyle(Color.red)
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
        case .tinted:
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.35))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(0.35))
        case .secondary:
            return AnyShapeStyle(Color.primary.opacity(0.08))
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
            return AnyShapeStyle(LiquidGlass.brandAccent)
        case .destructive:
            return AnyShapeStyle(Color.red)
        case .secondary:
            return AnyShapeStyle(Color.primary)
        case .ghost:
            return hover.isHovered ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.secondary)
        }
    }

    private var shortcutBadgeBackground: AnyShapeStyle {
        switch variant {
        case .primary, .prominentDestructive:
            return AnyShapeStyle(Color.white.opacity(0.22))
        default:
            return AnyShapeStyle(Color.primary.opacity(0.08))
        }
    }

    private var shortcutBadgeForeground: AnyShapeStyle {
        switch variant {
        case .primary, .prominentDestructive:
            return AnyShapeStyle(Color.white)
        default:
            return AnyShapeStyle(Color.secondary)
        }
    }
}
