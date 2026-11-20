import SwiftUI
import AppKit

@MainActor
public final class FloatingDropTargetViewModel: ObservableObject {
    public static let shared = FloatingDropTargetViewModel()

    @Published public var isTargeted: Bool = false
    @Published public var isHoveringRings: Bool = false
    @Published public var isVisible: Bool = false
    @Published public var ringHoverOffset: CGFloat = 0.0

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
            // Background Liquid Glass Pod
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.16, blue: 0.22).opacity(0.92),
                            Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(viewModel.isTargeted ? 0.75 : 0.35),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: viewModel.isTargeted ? 1.6 : 1.0
                        )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
                .shadow(
                    color: viewModel.isTargeted ? Color.cyan.opacity(0.5) : Color.clear,
                    radius: 14
                )

            // 3D Levitating Portal Artwork
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // 1. Lower Base Pedestal (Polished Chrome & Slate)
                    basePedestal
                        .offset(y: 19)

                    // 2. Fiery Portal Core Well
                    portalCore
                        .offset(y: 15)

                    // 3. Lower Ring (Neon Purple / Violet 3D Torus)
                    FloatingPortalRing(
                        topColor: Color(red: 0.95, green: 0.70, blue: 1.0),
                        bodyColor: Color(red: 0.75, green: 0.38, blue: 0.98),
                        bottomColor: Color(red: 0.50, green: 0.15, blue: 0.80),
                        glowColor: Color(red: 0.85, green: 0.35, blue: 1.0),
                        ringWidth: 54,
                        ringHeight: 18,
                        wallHeight: 5
                    )
                    .offset(y: 1 - viewModel.ringHoverOffset * 0.5)

                    // 4. Upper Ring (Neon Cyan / Sky Blue 3D Torus)
                    FloatingPortalRing(
                        topColor: Color(red: 0.85, green: 0.98, blue: 1.0),
                        bodyColor: Color(red: 0.35, green: 0.75, blue: 1.0),
                        bottomColor: Color(red: 0.18, green: 0.48, blue: 0.88),
                        glowColor: Color(red: 0.35, green: 0.80, blue: 1.0),
                        ringWidth: 54,
                        ringHeight: 18,
                        wallHeight: 5
                    )
                    .offset(y: -14 - viewModel.ringHoverOffset)
                }
                .frame(width: 82, height: 72)
                .scaleEffect(viewModel.isTargeted ? 1.10 : 1.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.68), value: viewModel.isTargeted)

                Spacer()
            }

            // Saved Items Count Badge in Top Right
            if shelfManager.items.count > 0 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(shelfManager.items.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .padding(.horizontal, 4)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                            .shadow(color: Color.cyan.opacity(0.5), radius: 4)
                            .offset(x: -6, y: 6)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: 96, height: 96)
        .contentShape(Rectangle())
        .onTapGesture {
            StatusBarController.shared.toggleShelf()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                viewModel.ringHoverOffset = 3.5
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

    // MARK: - Metallic Base Pedestal
    private var basePedestal: some View {
        ZStack {
            // Drop shadow under base
            Ellipse()
                .fill(Color.black.opacity(0.65))
                .frame(width: 72, height: 26)
                .offset(y: 4)

            // Lower bevel / chrome cylinder side
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.55),
                            Color(white: 0.30),
                            Color(white: 0.60)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 25)
                .offset(y: 2)

            // Outer polished chrome top rim
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.92),
                            Color(white: 0.55),
                            Color(white: 0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 24)

            // Inner slate platform bevel
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.18, blue: 0.26),
                            Color(red: 0.09, green: 0.10, blue: 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 63, height: 20)
        }
    }

    // MARK: - Fiery Portal Core
    private var portalCore: some View {
        ZStack {
            // Hot inner glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.48, blue: 0.38),
                            Color(red: 0.95, green: 0.18, blue: 0.32),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 44, height: 16)
                .blur(radius: viewModel.isTargeted ? 2.5 : 1.5)
                .scaleEffect(viewModel.isTargeted ? 1.25 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isTargeted)
        }
    }
}

// MARK: - 3D Levitating Portal Ring Component
struct FloatingPortalRing: View {
    let topColor: Color
    let bodyColor: Color
    let bottomColor: Color
    let glowColor: Color
    let ringWidth: CGFloat
    let ringHeight: CGFloat
    let wallHeight: CGFloat

    var body: some View {
        ZStack {
            // 3D Cylindrical wall depth
            ZStack {
                // Bottom edge rim
                Ellipse()
                    .stroke(bottomColor, lineWidth: 3.5)
                    .frame(width: ringWidth, height: ringHeight)
                    .offset(y: wallHeight)

                // Vertical cylinder gradient band
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [bodyColor.opacity(0.85), bottomColor],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 4
                    )
                    .frame(width: ringWidth, height: ringHeight)
                    .offset(y: wallHeight / 2)
            }

            // Top specular rim with bright highlight
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            topColor,
                            bodyColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3.5
                )
                .frame(width: ringWidth, height: ringHeight)
        }
        .shadow(color: glowColor.opacity(0.75), radius: 6, x: 0, y: 1)
    }
}
