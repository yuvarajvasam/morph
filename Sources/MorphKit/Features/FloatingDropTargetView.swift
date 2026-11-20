import SwiftUI
import AppKit

@MainActor
public final class FloatingDropTargetViewModel: ObservableObject {
    public static let shared = FloatingDropTargetViewModel()

    @Published public var isTargeted: Bool = false
    @Published public var isVisible: Bool = false
    @Published public var pulseOffset: CGFloat = 0.0

    public init() {}
}

public struct FloatingDropTargetView: View {
    @ObservedObject public var viewModel: FloatingDropTargetViewModel = .shared
    @ObservedObject public var shelfManager: ShelfManager = .shared
    public var onDropAction: (([URL]) -> Void)?

    public init(viewModel: FloatingDropTargetViewModel = .shared, shelfManager: ShelfManager = .shared, onDropAction: (([URL]) -> Void)? = nil) {
        self.viewModel = viewModel
        self.shelfManager = shelfManager
        self.onDropAction = onDropAction
    }

    public var body: some View {
        ZStack {
            // Background Obsidian Liquid Glass Pod (Axiom Regular Liquid Glass)
            ZStack {
                // Desktop optical vibrancy blur
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active,
                    cornerRadius: 14
                )

                // Atmospheric dark glass tint
                LinearGradient(
                    colors: [
                        Color(red: 14 / 255, green: 26 / 255, blue: 34 / 255).opacity(0.85),
                        Color(red: 8 / 255, green: 16 / 255, blue: 22 / 255).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                // Specular highlight rim (Lensing & Edge Lighting)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(viewModel.isTargeted ? 0.85 : 0.32),
                                Color.white.opacity(viewModel.isTargeted ? 0.30 : 0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: viewModel.isTargeted ? 1.5 : 0.75
                    )
            )
            // Dual-layer shadows: ambient shadow + contact shadow
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
            .shadow(
                color: viewModel.isTargeted ? LiquidGlass.brandAccent.opacity(0.60) : Color.black.opacity(0.12),
                radius: viewModel.isTargeted ? 10 : 3,
                x: 0,
                y: 1.5
            )
            .frame(width: 50, height: 50)

            // New Sleek Illuminated Drop Tray Icon
            VStack(spacing: 3) {
                // Descending Animated Neon Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.85, blue: 1.0),
                                Color(red: 0.75, green: 0.45, blue: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: viewModel.isTargeted ? 2.5 : (viewModel.pulseOffset * 1.5))
                    .shadow(color: Color.cyan.opacity(0.6), radius: 4)

                // Frosted Glass Holding Shelf / Tray
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 28, height: 5)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.8),
                                    Color.white.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 28, height: 5)
                }
            }
            .scaleEffect(viewModel.isTargeted ? 1.08 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: viewModel.isTargeted)

            // Saved Items Count Badge in Top Right
            if shelfManager.items.count > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(shelfManager.items.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 15, minHeight: 15)
                            .padding(.horizontal, 3)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.8))
                            .shadow(color: Color.cyan.opacity(0.5), radius: 3)
                            .offset(x: -8, y: 8)
                    }
                    Spacer()
                }
                .frame(width: 50, height: 50)
            }
        }
        .frame(width: 70, height: 70)
        .contentShape(Rectangle())
        .onTapGesture {
            StatusBarController.shared.showShelfPopover()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                viewModel.pulseOffset = 2.0
            }
        }
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: Binding(
            get: { viewModel.isTargeted },
            set: { targeted in
                viewModel.isTargeted = targeted
            }
        )) { providers in
            var handled = false
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                        var droppedURL: URL? = nil
                        if let data = item as? Data {
                            droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                        } else if let url = item as? URL {
                            droppedURL = url
                        }
                        if let url = droppedURL {
                            DispatchQueue.main.async {
                                onDropAction?([url])
                            }
                        }
                    }
                    handled = true
                } else if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, _ in
                        var droppedURL: URL? = nil
                        if let data = item as? Data {
                            droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                        } else if let url = item as? URL {
                            droppedURL = url
                        }
                        if let url = droppedURL {
                            DispatchQueue.main.async {
                                onDropAction?([url])
                            }
                        }
                    }
                    handled = true
                } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                    provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { item, _ in
                        if let text = item as? String {
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                                if let webURL = URL(string: trimmed) {
                                    DispatchQueue.main.async {
                                        onDropAction?([webURL])
                                    }
                                }
                            }
                        }
                    }
                    handled = true
                }
            }
            return handled
        }
    }
}
