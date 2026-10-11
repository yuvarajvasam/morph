import SwiftUI
import AppKit

/// Spotlight/Raycast-inspired Search Control (Layer A) adhering to macOS HIG:
/// - Immediate focus on launch
/// - Clear native typography and placeholder
/// - Restrained focus ring with Morph brand accent (#C74634)
/// - Single-layer floating surface (no nested glass cards)
public struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search operations, formats, or drop files..."
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    private var shouldReduceTransparency: Bool {
        systemReduceTransparency || LiquidGlass.shouldReduceTransparency
    }

    public init(text: Binding<String>, placeholder: String = "Search operations, formats, or drop files...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isFocused ? AnyShapeStyle(LiquidGlass.brandAccent) : AnyShapeStyle(Color.secondary))
                .animation(LiquidGlass.quickSpring, value: isFocused)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.primary)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search (⎋)")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: LiquidGlass.searchFieldHeight)
        .background {
            if shouldReduceTransparency {
                RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                            .strokeBorder(
                                isFocused ? LiquidGlass.brandAccent.opacity(0.65) : Color(nsColor: .separatorColor).opacity(0.35),
                                lineWidth: isFocused ? 1.0 : 0.5
                            )
                    }
            } else {
                RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.50))
                    .overlay {
                        RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                            .strokeBorder(
                                isFocused ? AnyShapeStyle(LiquidGlass.brandAccent.opacity(0.65)) : AnyShapeStyle(Color.primary.opacity(0.08)),
                                lineWidth: isFocused ? 1.0 : 0.5
                            )
                    }
                    .shadow(
                        color: isFocused ? LiquidGlass.brandAccent.opacity(0.12) : Color.black.opacity(0.04),
                        radius: isFocused ? 6 : 2,
                        x: 0,
                        y: 1
                    )
            }
        }
        .animation(LiquidGlass.quickSpring, value: text.isEmpty)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
