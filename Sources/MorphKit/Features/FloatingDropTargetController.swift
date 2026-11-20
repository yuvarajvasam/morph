import AppKit
import SwiftUI

/// AppKit destination view capturing drag-and-drop events directly at the window layer
final class FloatingDropDestinationOverlayView: NSView {
    weak var controller: FloatingDropTargetController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .URL, .string, NSPasteboard.PasteboardType("public.url")])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL, .URL, .string, NSPasteboard.PasteboardType("public.url")])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        FloatingDropTargetViewModel.shared.isTargeted = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        FloatingDropTargetViewModel.shared.isTargeted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        FloatingDropTargetViewModel.shared.isTargeted = false
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []

        if let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: items)
        }

        if urls.isEmpty, let propertyList = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            urls.append(contentsOf: propertyList.map { URL(fileURLWithPath: $0) })
        }

        // Check for text/web links
        if urls.isEmpty, let str = pasteboard.string(forType: .string) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                if let webURL = URL(string: trimmed) {
                    urls.append(webURL)
                }
            }
        }

        if !urls.isEmpty {
            controller?.handleFilesDropped(urls)
            return true
        }
        return false
    }

    override func mouseDown(with event: NSEvent) {
        StatusBarController.shared.toggleShelf()
    }
}

@MainActor
public final class FloatingDropTargetController: NSObject {
    public static let shared = FloatingDropTargetController()

    private var panel: NSPanel?
    private var globalDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var hideWorkItem: DispatchWorkItem?
    private var isMonitoring = false

    public override init() {
        super.init()
    }

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        setupPanel()

        // Monitor global mouse drag events across all applications (Finder, Desktop, etc.)
        globalDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseDrag(event)
            }
        }

        // Monitor global mouse release
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseUp(event)
            }
        }
    }

    public func stopMonitoring() {
        if let monitor = globalDragMonitor {
            NSEvent.removeMonitor(monitor)
            globalDragMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        isMonitoring = false
        hide(animated: false)
    }

    private func setupPanel() {
        guard panel == nil else { return }

        let dropView = FloatingDropTargetView { [weak self] urls in
            self?.handleFilesDropped(urls)
        }
        let hostingView = NSHostingView(rootView: dropView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let overlay = FloatingDropDestinationOverlayView(frame: NSRect(x: 0, y: 0, width: 96, height: 96))
        overlay.autoresizingMask = [.width, .height]
        overlay.controller = self
        hostingView.addSubview(overlay)

        let targetPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 96, height: 96),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        targetPanel.isOpaque = false
        targetPanel.backgroundColor = .clear
        targetPanel.hasShadow = false
        targetPanel.isFloatingPanel = true
        targetPanel.level = .statusBar
        targetPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        targetPanel.contentView = hostingView
        targetPanel.alphaValue = 0

        self.panel = targetPanel
        updatePanelPosition()
    }

    private func updatePanelPosition() {
        guard let panel, let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        // Positioned in top-right area right below the menu bar
        let x = screenRect.maxX - 130
        let y = screenRect.maxY - 110
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func isDraggingFiles() -> Bool {
        let dragPB = NSPasteboard(name: .drag)
        guard let types = dragPB.types, !types.isEmpty else { return false }
        let recognizedTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.finder.node"),
            NSPasteboard.PasteboardType("Apple URL pasteboard type"),
            NSPasteboard.PasteboardType("public.url")
        ]
        return types.contains(where: { recognizedTypes.contains($0) })
    }

    private func handleGlobalMouseDrag(_ event: NSEvent) {
        if isDraggingFiles() {
            cancelHideTimer()
            show()
        }
    }

    private func handleGlobalMouseUp(_ event: NSEvent) {
        hideAfterDelay(0.9)
    }

    public func show() {
        setupPanel()
        guard let panel else { return }
        updatePanelPosition()

        cancelHideTimer()

        if !panel.isVisible || panel.alphaValue < 1.0 {
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                panel.animator().alphaValue = 1.0
            }
        }
    }

    public func hide(animated: Bool = true) {
        guard let panel, panel.isVisible else { return }

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                panel.animator().alphaValue = 0.0
            }, completionHandler: { [weak panel] in
                DispatchQueue.main.async {
                    if panel?.alphaValue == 0 {
                        panel?.orderOut(nil)
                    }
                }
            })
        } else {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
        }
    }

    public func hideAfterDelay(_ delay: TimeInterval) {
        cancelHideTimer()
        let work = DispatchWorkItem { [weak self] in
            self?.hide(animated: true)
        }
        self.hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelHideTimer() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }

    public func handleFilesDropped(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        NSSound(named: "Pop")?.play()
        ShelfManager.shared.addItems(urls: urls)
        StatusBarController.shared.showShelfPopover()
        hide(animated: true)
    }
}
