import SwiftUI

public extension String {
    /// Splits a shortcut string into individual key tokens (e.g. "⌥ Space" -> ["⌥", "Space"], "⌘K" -> ["⌘", "K"])
    var shortcutKeyTokens: [String] {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return [] }

        // Paired arrows
        if trimmed == "↑ / ↓" { return ["↑", "↓"] }
        if trimmed == "← / →" { return ["←", "→"] }

        // Space-separated tokens (e.g. "⌥ Space", "⌘ Space", "Option Space")
        if trimmed.contains(" ") {
            return trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        }

        // Single key or word tokens
        if trimmed.count == 1 || trimmed == "Space" || trimmed == "Enter" || trimmed == "Esc" || trimmed == "Tab" {
            return [trimmed]
        }

        // Modifiers attached to keys (e.g. "⌘K", "⌘O", "⌘R", "⌘,", "⌘⌫", "⌥⌘C")
        var tokens: [String] = []
        for char in trimmed {
            tokens.append(String(char))
        }
        return tokens.isEmpty ? [trimmed] : tokens
    }
}

/// A macOS-native keycap badge representing a single individual physical key.
public struct KeycapBadge: View {
    public let symbol: String
    public var fontSize: CGFloat
    public var minDimension: CGFloat

    public init(_ symbol: String, fontSize: CGFloat = 10, minDimension: CGFloat = 16) {
        self.symbol = symbol
        self.fontSize = fontSize
        self.minDimension = minDimension
    }

    public var body: some View {
        Text(symbol)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.92))
            .frame(minWidth: minDimension, minHeight: minDimension)
            .padding(.horizontal, symbol.count > 1 ? 5 : 3)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
                    .shadow(color: Color.black.opacity(0.20), radius: 1, x: 0, y: 0.5)
            )
    }
}

/// Displays shortcut combinations as separate individual keycaps side-by-side.
public struct ShortcutKeycapView: View {
    public let shortcut: String
    public var spacing: CGFloat
    public var fontSize: CGFloat
    public var minDimension: CGFloat

    public init(
        _ shortcut: String,
        spacing: CGFloat = 3,
        fontSize: CGFloat = 10,
        minDimension: CGFloat = 16
    ) {
        self.shortcut = shortcut
        self.spacing = spacing
        self.fontSize = fontSize
        self.minDimension = minDimension
    }

    public var body: some View {
        let tokens = shortcut.shortcutKeyTokens
        HStack(spacing: spacing) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                KeycapBadge(token, fontSize: fontSize, minDimension: minDimension)
            }
        }
    }
}
