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
        onTap: @escaping () -> Void
    ) {
        self.url = url
        self.pageIndex = pageIndex
        self.pageNumber = pageNumber
        self.isSelected = isSelected
        self.rotationAngle = rotationAngle
        self.isMarkedForRemoval = isMarkedForRemoval
        self.badgeText = badgeText
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.5)
                        }
                        .frame(width: 86, height: 110)
                        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)

                    if let img = loader.image {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 80, maxHeight: 104)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .rotationEffect(.degrees(Double(rotationAngle)))
                            .animation(LiquidGlass.quickSpring, value: rotationAngle)
                    } else {
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Page \(pageNumber)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Removal Overlay
                    if isMarkedForRemoval {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.35))
                        VStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3)
                            Text("REMOVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    // Selection checkmark
                    if isSelected && !isMarkedForRemoval {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 2.5)
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .symbolEffect(.bounce, value: isSelected)
                                    .background(Circle().fill(Color.white))
                                    .font(.system(size: 14))
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .overlay {
                    if !isSelected && !isMarkedForRemoval {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
                    }
                }

                // Page Number Tag
                HStack(spacing: 4) {
                    Text("\(pageNumber)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isMarkedForRemoval ? Color.red : (isSelected ? Color.accentColor : Color.primary))

                    if let badge = badgeText {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
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
