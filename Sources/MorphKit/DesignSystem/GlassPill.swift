import SwiftUI
import AppKit

public enum GlassPillStyle {
    case standard
    case accent
    case success
    case warning
    case destructive
}

public struct GlassPill: View {
    private let text: String
    private let icon: String?
    private let style: GlassPillStyle

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(_ text: String, icon: String? = nil, style: GlassPillStyle = .standard) {
        self.text = text
        self.icon = icon
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            Capsule(style: .continuous)
                .fill(backgroundFill)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(borderStroke, lineWidth: 0.5)
                }
        }
        .foregroundStyle(textColor)
    }

    private var backgroundFill: AnyShapeStyle {
        if reduceTransparency || LiquidGlass.shouldReduceTransparency {
            switch style {
            case .standard:
                return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
            case .accent:
                return AnyShapeStyle(Color.accentColor.opacity(0.18))
            case .success:
                return AnyShapeStyle(Color.green.opacity(0.18))
            case .warning:
                return AnyShapeStyle(Color.orange.opacity(0.18))
            case .destructive:
                return AnyShapeStyle(Color.red.opacity(0.18))
            }
        }

        switch style {
        case .standard:
            return AnyShapeStyle(.thinMaterial)
        case .accent:
            return AnyShapeStyle(Color.accentColor.opacity(0.18))
        case .success:
            return AnyShapeStyle(Color.green.opacity(0.18))
        case .warning:
            return AnyShapeStyle(Color.orange.opacity(0.18))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(0.18))
        }
    }

    private var borderStroke: AnyShapeStyle {
        switch style {
        case .standard:
            return AnyShapeStyle(.quaternary)
        case .accent:
            return AnyShapeStyle(Color.accentColor.opacity(0.35))
        case .success:
            return AnyShapeStyle(Color.green.opacity(0.35))
        case .warning:
            return AnyShapeStyle(Color.orange.opacity(0.35))
        case .destructive:
            return AnyShapeStyle(Color.red.opacity(0.35))
        }
    }

    private var textColor: AnyShapeStyle {
        switch style {
        case .standard:
            return AnyShapeStyle(.primary)
        case .accent:
            return AnyShapeStyle(Color.accentColor)
        case .success:
            return AnyShapeStyle(Color.green)
        case .warning:
            return AnyShapeStyle(Color.orange)
        case .destructive:
            return AnyShapeStyle(Color.red)
        }
    }
}
