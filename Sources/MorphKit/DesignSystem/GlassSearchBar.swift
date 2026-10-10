import SwiftUI
import AppKit

public struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search operations, formats, or drop files..."
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(text: Binding<String>, placeholder: String = "Search operations, formats, or drop files...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isFocused ? AnyShapeStyle(LiquidGlass.bridgeTint) : AnyShapeStyle(.secondary))
                .animation(LiquidGlass.quickSpring, value: isFocused)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.figmaBody())
                .foregroundStyle(.primary)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear search (⎋)")
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: LiquidGlass.searchFieldHeight)
        .background {
            if reduceTransparency || LiquidGlass.shouldReduceTransparency {
                RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                            .stroke(
                                isFocused ? AnyShapeStyle(LiquidGlass.bridgeTint) : AnyShapeStyle(.quaternary),
                                lineWidth: isFocused ? 1.5 : 0.5
                            )
                    }
            } else {
                RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                    .fill(.thickMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                            .stroke(
                                isFocused ? AnyShapeStyle(LiquidGlass.bridgeTint.opacity(0.80)) : AnyShapeStyle(.quaternary),
                                lineWidth: isFocused ? 1.5 : 0.5
                            )
                    }
                    .shadow(
                        color: isFocused ? LiquidGlass.bridgeTint.opacity(0.20) : Color.black.opacity(0.08),
                        radius: isFocused ? 8 : 4,
                        x: 0,
                        y: 2
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
