import SwiftUI
import AppKit

public enum GlassPillStyle {
    case standard
    case accent
    case success
    case warning
    case destructive
}

/// Compact badge/pill component for categories, count badges, and statuses:
/// - Restrained visual weight
/// - Semantic colors with high contrast
/// - Clean typography
public struct GlassPill: View {
    private let text: String
    private let icon: String?
    private let style: GlassPillStyle

    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    private var shouldReduceTransparency: Bool {
        systemReduceTransparency || LiquidGlass.shouldReduceTransparency
    }

    public init(_ text: String, icon: String? = nil, style: GlassPillStyle = .standard) {
        self.text = text
        self.icon = icon
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .monospacedDigit()
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(backgroundFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(borderStroke, lineWidth: 0.5)
                }
        }
        .foregroundStyle(textColor)
    }

    private var backgroundFill: AnyShapeStyle {
        if shouldReduceTransparency {
            switch style {
            case .standard:
                return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
            case .accent:
                return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.14))
            case .success:
                return AnyShapeStyle(Color.green.opacity(0.14))
            case .warning:
                return AnyShapeStyle(Color.orange.opacity(0.14))
            case .destructive:
                return AnyShapeStyle(Color.red.opacity(0.14))
            }
        }

        switch style {
        case .standard:
            return AnyShapeStyle(Color.primary.opacity(0.06))
        case .accent:
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.14))
        case .success:
            return AnyShapeStyle(Color.green.opacity(0.14))
        case .warning:
            return AnyShapeStyle(Color.orange.opacity(0.14))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(0.14))
        }
    }

    private var borderStroke: AnyShapeStyle {
        switch style {
        case .standard:
            return AnyShapeStyle(Color.primary.opacity(0.06))
        case .accent:
            return AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.30))
        case .success:
            return AnyShapeStyle(Color.green.opacity(0.30))
        case .warning:
            return AnyShapeStyle(Color.orange.opacity(0.30))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(0.30))
        }
    }

    private var textColor: AnyShapeStyle {
        switch style {
        case .standard:
            return AnyShapeStyle(Color.secondary)
        case .accent:
            return AnyShapeStyle(LiquidGlass.brandAccent)
        case .success:
            return AnyShapeStyle(Color.green)
        case .warning:
            return AnyShapeStyle(Color.orange)
        case .destructive:
            return AnyShapeStyle(Color.red)
        }
    }
}
