import SwiftUI
import AppKit

@MainActor
public final class ComparisonViewModel: ObservableObject {
    @Published public var splitPosition: CGFloat = 0.5
    @Published public var originalImage: NSImage?
    @Published public var processedImage: NSImage?

    public init() {}

    public func loadImages(originalURL: URL, processedURL: URL) {
        if let origData = try? Data(contentsOf: originalURL) {
            originalImage = NSImage(data: origData)
        }
        if let procData = try? Data(contentsOf: processedURL) {
            processedImage = NSImage(data: procData)
        }
    }

    public func resetSplit() {
        withAnimation(LiquidGlass.quickSpring) {
            splitPosition = 0.5
        }
    }
}

public struct GlassComparisonView: View {
    let originalURL: URL
    let processedURL: URL
    let originalDimensions: CGSize?
    let processedDimensions: CGSize?

    @StateObject private var model = ComparisonViewModel()

    public init(
        originalURL: URL,
        processedURL: URL,
        originalDimensions: CGSize? = nil,
        processedDimensions: CGSize? = nil
    ) {
        self.originalURL = originalURL
        self.processedURL = processedURL
        self.originalDimensions = originalDimensions
        self.processedDimensions = processedDimensions
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Background layer: Processed image
                if let proc = model.processedImage {
                    Image(nsImage: proc)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                }

                // Foreground layer: Original image clipped by split position
                if let orig = model.originalImage {
                    Image(nsImage: orig)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .mask {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: max(0, size.width * model.splitPosition))
                                Spacer(minLength: 0)
                            }
                        }
                }

                // Split Divider Line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 0)
                    .position(x: size.width * model.splitPosition, y: size.height / 2)

                // Drag handle knob
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.35), radius: 4))
                .position(x: size.width * model.splitPosition, y: size.height / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPos = value.location.x / size.width
                            model.splitPosition = min(max(newPos, 0.05), 0.95)
                        }
                )
                .onTapGesture(count: 2) {
                    model.resetSplit()
                }
                .help("Drag to compare before/after (Double-click to reset)")

                // Top Labels
                VStack {
                    HStack {
                        GlassPill("Original", icon: "photo", style: .standard)
                            .padding(.leading, 12)
                        Spacer()
                        GlassPill("Processed", icon: "sparkles", style: .accent)
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 12)
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlass.cardRadius, style: .continuous)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
        }
        .onAppear {
            model.loadImages(originalURL: originalURL, processedURL: processedURL)
        }
    }
}
