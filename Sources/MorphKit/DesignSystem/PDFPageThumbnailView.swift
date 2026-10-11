import SwiftUI
import AppKit

@MainActor
public final class PageThumbnailLoader: ObservableObject {
    @Published public var image: NSImage?
    @Published public var isLoading: Bool = false

    public init() {}

    public func load(url: URL, pageIndex: Int, maxDimension: CGFloat = 180) {
        if image != nil { return }
        isLoading = true

        Task {
            let thumb = await ThumbnailService.shared.pdfPageThumbnail(url: url, pageIndex: pageIndex, maxDimension: maxDimension)
            self.image = thumb
            self.isLoading = false
        }
    }
}

public struct PDFPageThumbnailView: View {
    let url: URL
    let pageIndex: Int
    let pageNumber: Int
    let isSelected: Bool
    let rotationAngle: Int
    let isMarkedForRemoval: Bool
    let badgeText: String?
    let size: CGSize
    let showPageLabel: Bool
    let onTap: () -> Void

    @StateObject private var loader = PageThumbnailLoader()

    public init(
        url: URL,
        pageIndex: Int,
        pageNumber: Int,
        isSelected: Bool = false,
        rotationAngle: Int = 0,
        isMarkedForRemoval: Bool = false,
        badgeText: String? = nil,
        size: CGSize = CGSize(width: 80, height: 104),
        showPageLabel: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.url = url
        self.pageIndex = pageIndex
        self.pageNumber = pageNumber
        self.isSelected = isSelected
        self.rotationAngle = rotationAngle
        self.isMarkedForRemoval = isMarkedForRemoval
        self.badgeText = badgeText
        self.size = size
        self.showPageLabel = showPageLabel
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        }
                        .frame(width: size.width, height: size.height)

                    if let img = loader.image {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: max(10, size.width - 6), maxHeight: max(10, size.height - 6))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .rotationEffect(.degrees(Double(rotationAngle)))
                            .animation(LiquidGlass.quickSpring, value: rotationAngle)
                    } else {
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(size.width < 50 ? 0.45 : 0.6)
                            if size.width >= 50 {
                                Text("Page \(pageNumber)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }

                    // Removal Overlay
                    if isMarkedForRemoval {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.red.opacity(0.35))
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("REMOVE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }

                    // Selection border & checkmark
                    if isSelected && !isMarkedForRemoval {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(LiquidGlass.brandAccent, lineWidth: 2.0)
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LiquidGlass.brandAccent)
                                    .background(Circle().fill(Color.white))
                                    .font(.system(size: 13))
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }

                // Page Number Tag
                if showPageLabel {
                    HStack(spacing: 4) {
                        Text("\(pageNumber)")
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .monospacedDigit()
                            .foregroundStyle(isMarkedForRemoval ? Color.red : (isSelected ? LiquidGlass.brandAccent : Color.secondary))

                        if let badge = badgeText {
                            Text(badge)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loader.load(url: url, pageIndex: pageIndex)
        }
    }
}
