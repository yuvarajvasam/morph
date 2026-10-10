import AppKit
import PDFKit
import ImageIO

public final class ThumbnailService: @unchecked Sendable {
    public static let shared = ThumbnailService()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB cache
    }

    /// Retrieves an image thumbnail, cached or rendered asynchronously with CoreGraphics.
    public func imageThumbnail(url: URL, maxPixelSize: CGFloat = 240) async -> NSImage? {
        let key = "\(url.path):img:\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) { [weak self] () -> NSImage? in
            guard let self else { return nil }
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                return nil
            }

            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceShouldCacheImmediately: true
            ]

            guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return nil
            }

            let nsImage = NSImage(cgImage: cgThumb, size: NSSize(width: cgThumb.width, height: cgThumb.height))
            self.cache.setObject(nsImage, forKey: key)
            return nsImage
        }.value
    }

    /// Retrieves a PDF page thumbnail, cached or rendered asynchronously via PDFKit.
    public func pdfPageThumbnail(url: URL, pageIndex: Int, maxDimension: CGFloat = 180) async -> NSImage? {
        let key = "\(url.path):pdf:\(pageIndex):\(Int(maxDimension))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) { [weak self] () -> NSImage? in
            guard let self else { return nil }
            guard let doc = PDFDocument(url: url),
                  pageIndex >= 0 && pageIndex < doc.pageCount,
                  let page = doc.page(at: pageIndex) else {
                return nil
            }

            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width > 0 && bounds.height > 0 else { return nil }

            let scale = maxDimension / max(bounds.width, bounds.height)
            let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

            let thumb = page.thumbnail(of: targetSize, for: .mediaBox)
            self.cache.setObject(thumb, forKey: key)
            return thumb
        }.value
    }

    /// Fast synchronous cache check
    public func cachedThumbnail(key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }
}
