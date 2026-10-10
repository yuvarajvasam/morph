import AppKit
import Quartz

public final class QuickLookItem: NSObject, QLPreviewItem, @unchecked Sendable {
    public let previewItemURL: URL?
    public let previewItemTitle: String?

    public init(url: URL, title: String? = nil) {
        self.previewItemURL = url
        self.previewItemTitle = title ?? url.lastPathComponent
        super.init()
    }
}

public final class QuickLookManager: NSObject, @unchecked Sendable {
    public static let shared = QuickLookManager()

    private let lock = NSLock()
    private var currentItem: QuickLookItem?

    private override init() {
        super.init()
    }

    @MainActor
    public func preview(url: URL) {
        lock.lock()
        self.currentItem = QuickLookItem(url: url)
        lock.unlock()

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    @MainActor
    public func toggle(url: URL) {
        guard let panel = QLPreviewPanel.shared() else { return }
        lock.lock()
        let isSame = panel.isVisible && currentItem?.previewItemURL?.path == url.path
        lock.unlock()

        if isSame {
            panel.orderOut(nil)
        } else {
            preview(url: url)
        }
    }

    @MainActor
    public func dismiss() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
        }
    }
}

extension QuickLookManager: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return currentItem != nil ? 1 : 0
    }

    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        lock.lock()
        defer { lock.unlock() }
        return currentItem
    }
}
