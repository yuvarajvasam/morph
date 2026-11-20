import AppKit
import SwiftUI

/// AppKit destination view capturing drag-and-drop events directly at the window layer
final class FloatingDropDestinationOverlayView: NSView {
    weak var controller: FloatingDropTargetController?
    private var hoverSpringTimer: Timer?

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

        // When a file, folder, or link is placed/held over the icon, reveal the menu bar shelf section
        hoverSpringTimer?.invalidate()
        hoverSpringTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard FloatingDropTargetViewModel.shared.isTargeted else { return }
                self?.controller?.hide(animated: false)
                StatusBarController.shared.openedByDrag = true
                StatusBarController.shared.showShelfPopover()
            }
        }

        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        FloatingDropTargetViewModel.shared.isTargeted = false
        hoverSpringTimer?.invalidate()
        hoverSpringTimer = nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hoverSpringTimer?.invalidate()
        hoverSpringTimer = nil
        FloatingDropTargetViewModel.shared.isTargeted = false
        StatusBarController.shared.openedByDrag = false
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []

        if let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: items)
        }

        if urls.isEmpty, let propertyList = pasteboard.propertyList(forType: .fileURL) as? [String] {
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
        controller?.hide(animated: false)
        StatusBarController.shared.showShelfPopover()
    }
}

@MainActor
public final class FloatingDropTargetController: NSObject {
    public static let shared = FloatingDropTargetController()

    private var panel: NSPanel?
    private var globalDragMonitor: Any?
    private var localDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var localMouseUpMonitor: Any?
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

        // Monitor local mouse drag events within Morph's own windows
        localDragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseDrag(event)
            }
            return event
        }

        // Monitor global mouse release across all applications
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseUp(event)
            }
        }

        // Monitor local mouse release within Morph's own windows
        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMouseUp(event)
            }
            return event
        }
    }

    public func stopMonitoring() {
        if let monitor = globalDragMonitor {
            NSEvent.removeMonitor(monitor)
            globalDragMonitor = nil
        }
        if let monitor = localDragMonitor {
            NSEvent.removeMonitor(monitor)
            localDragMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        if let monitor = localMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseUpMonitor = nil
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

        let windowSize: CGFloat = 70
        let overlay = FloatingDropDestinationOverlayView(frame: NSRect(x: 0, y: 0, width: windowSize, height: windowSize))
        overlay.autoresizingMask = [.width, .height]
        overlay.controller = self
        hostingView.addSubview(overlay)

        let targetPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: windowSize, height: windowSize),
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

    public func updatePanelPosition() {
        guard let panel else { return }
        let windowSize: CGFloat = 70
        let podSize: CGFloat = 50
        let topPadding: CGFloat = (windowSize - podSize) / 2

        var x: CGFloat
        var y: CGFloat

        if let buttonFrame = StatusBarController.shared.statusButtonFrameOnScreen {
            // Horizontally centered with the status bar icon
            x = buttonFrame.midX - (windowSize / 2)
            // Positioned so the visible 50x50 pod sits exactly 2pt below the menu bar bottom edge
            y = buttonFrame.minY - windowSize + topPadding - 2
        } else if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            x = screenRect.maxX - windowSize - 14
            y = screenRect.maxY - windowSize + topPadding - 2
        } else {
            return
        }

        // Clamp within main screen boundaries to avoid screen edge clipping
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            x = max(screenRect.minX + 4, min(x, screenRect.maxX - windowSize - 4))
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func isDraggingFiles() -> Bool {
        let dragPB = NSPasteboard(name: .drag)
        guard let types = dragPB.types, !types.isEmpty else { return false }
        let recognizedTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("com.apple.finder.node"),
            .URL,
            NSPasteboard.PasteboardType("public.url")
        ]
        if types.contains(where: { recognizedTypes.contains($0) }) {
            return true
        }
        if let urls = dragPB.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return true
        }
        return false
    }

    private func handleGlobalMouseDrag(_ event: NSEvent) {
        let dragging = isDraggingFiles() || StatusBarController.shared.isDraggingItemFromShelf

        // 1. When the menu bar drop section (popover) is shown
        if StatusBarController.shared.isShelfPopoverShown {
            if panel?.isVisible == true {
                hide(animated: false)
            }
            if dragging {
                let mouseLoc = NSEvent.mouseLocation
                if !StatusBarController.shared.isMouseOverPopoverOrButton(mouseLoc) {
                    // When a file is dragged out of the menu section, the menu section should not be shown!
                    StatusBarController.shared.hideShelfPopover()
                }
            }
            return
        }

        // 2. When popover is NOT shown:
        if StatusBarController.shared.isDraggingItemFromShelf {
            // User is dragging a file out of the shelf to another app; keep the drop pod hidden
            hide(animated: false)
            return
        }

        if dragging {
            cancelHideTimer()
            show()
        } else {
            // Close immediately when a file is not active
            hide(animated: false)
        }
    }

    private func handleGlobalMouseUp(_ event: NSEvent) {
        cancelHideTimer()
        // Close drag target immediately when a file is not active
        hide(animated: false)
        StatusBarController.shared.isDraggingItemFromShelf = false

        if StatusBarController.shared.openedByDrag {
            let mouseLoc = NSEvent.mouseLocation
            if !StatusBarController.shared.isMouseOverPopoverOrButton(mouseLoc) {
                StatusBarController.shared.hideShelfPopover()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    if StatusBarController.shared.openedByDrag {
                        StatusBarController.shared.hideShelfPopover()
                    }
                }
            }
        }
    }

    public func show() {
        // When the menu bar drop section (popover) is shown, the drag target pod must NOT be shown
        guard !StatusBarController.shared.isShelfPopoverShown else {
            hide(animated: false)
            return
        }

        setupPanel()
        guard let panel else { return }
        updatePanelPosition()

        cancelHideTimer()

        // Open immediately without animation lag
        panel.alphaValue = 1.0
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    public func hide(animated: Bool = false) {
        cancelHideTimer()
        guard let panel, panel.isVisible else { return }

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                panel.animator().alphaValue = 0.0
            }, completionHandler: { [weak panel] in
                DispatchQueue.main.async {
                    if panel?.alphaValue == 0 {
                        panel?.orderOut(nil)
                    }
                }
            })
        } else {
            // Close immediately without animation delay
            panel.alphaValue = 0.0
            panel.orderOut(nil)
        }
    }

    public func hideAfterDelay(_ delay: TimeInterval) {
        cancelHideTimer()
        let work = DispatchWorkItem { [weak self] in
            self?.hide(animated: false)
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
        StatusBarController.shared.openedByDrag = false
        NSSound(named: "Pop")?.play()
        ShelfManager.shared.addItems(urls: urls)
        // Hide the floating target before showing the drop shelf popover
        hide(animated: false)
        StatusBarController.shared.showShelfPopover()
    }
}
