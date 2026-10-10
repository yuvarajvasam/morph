import SwiftUI
import AppKit

@MainActor
public final class ImageThumbnailLoader: ObservableObject {
    @Published public var image: NSImage?
    @Published public var isLoading: Bool = false

    public init() {}

    public func load(url: URL, maxPixelSize: CGFloat = 300) {
        if image != nil { return }
        isLoading = true

        Task {
            let thumb = await ThumbnailService.shared.imageThumbnail(url: url, maxPixelSize: maxPixelSize)
            self.image = thumb
            self.isLoading = false
        }
    }
}

public struct ImageThumbnailView: View {
    let url: URL
    let maxPixelSize: CGFloat
    let cornerRadius: CGFloat

    @StateObject private var loader = ImageThumbnailLoader()

    public init(url: URL, maxPixelSize: CGFloat = 300, cornerRadius: CGFloat = 10) {
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))

            if let img = loader.image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.5)
        }
        .onAppear {
            loader.load(url: url, maxPixelSize: maxPixelSize)
        }
    }
}
