import AppKit
import SwiftUI

final class StatusBarDropDestinationView: NSView {
    weak var controller: StatusBarController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL, .URL, .string])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        controller?.handleDragEntered(sender)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return controller?.handleDrop(sender) ?? false
    }

    override func mouseDown(with event: NSEvent) {
        controller?.statusBarButtonClicked()
    }

    override func rightMouseDown(with event: NSEvent) {
        controller?.showMenu()
    }
}

@MainActor
public final class StatusBarController: NSObject, NSPopoverDelegate {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private var dropOverlayView: StatusBarDropDestinationView?
    private var shelfPopover: NSPopover?

    public var isShelfPopoverShown: Bool {
        return shelfPopover?.isShown == true
    }

    public var statusButtonFrameOnScreen: NSRect? {
        guard let button = statusItem?.button, let window = button.window else { return nil }
        let rectInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }

    public func setupStatusBar() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "Morph Drop Shelf")
            button.imagePosition = .imageOnly

            let overlay = StatusBarDropDestinationView(frame: button.bounds)
            overlay.autoresizingMask = [.width, .height]
            overlay.controller = self
            button.addSubview(overlay)
            self.dropOverlayView = overlay
        }
    }

    public func updateVisibility(_ show: Bool) {
        if show {
            setupStatusBar()
        } else if let item = statusItem {
            hideShelfPopover()
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            dropOverlayView = nil
        }
    }

    public func statusBarButtonClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            toggleShelf()
        }
    }

    public func showShelfPopover() {
        guard let button = statusItem?.button else { return }

        // Hide floating drop target immediately when shelf popover is shown
        FloatingDropTargetController.shared.hide(animated: false)

        if shelfPopover == nil {
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 440, height: 380)
            popover.behavior = .transient
            popover.delegate = self
            let hostingController = NSHostingController(rootView: DropShelfView(shelfManager: ShelfManager.shared))
            popover.contentViewController = hostingController
            self.shelfPopover = popover
        }

        if shelfPopover?.isShown != true {
            NSApp.activate(ignoringOtherApps: true)
            shelfPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    public func popoverWillShow(_ notification: Notification) {
        FloatingDropTargetController.shared.hide(animated: false)
    }

    public func hideShelfPopover() {
        shelfPopover?.performClose(nil)
    }

    public func toggleShelf() {
        if shelfPopover?.isShown == true {
            hideShelfPopover()
        } else {
            showShelfPopover()
        }
    }

    public func handleDragEntered(_ sender: NSDraggingInfo) {
        showShelfPopover()
    }

    public func handleDrop(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []

        if let classes = [NSURL.self] as? [AnyClass],
           let items = pasteboard.readObjects(forClasses: classes, options: nil) as? [URL] {
            urls.append(contentsOf: items)
        }

        if urls.isEmpty, let propertyList = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            urls.append(contentsOf: propertyList.map { URL(fileURLWithPath: $0) })
        }

        if urls.isEmpty, let str = pasteboard.string(forType: .string) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                if let webURL = URL(string: trimmed) {
                    urls.append(webURL)
                }
            }
        }

        guard !urls.isEmpty else { return false }
        NSSound(named: "Pop")?.play()
        ShelfManager.shared.addItems(urls: urls)
        showShelfPopover()
        return true
    }

    public func showMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Drop Shelf", action: #selector(openDropShelfAction), keyEquivalent: "d")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Morph", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openDropShelfAction() {
        showShelfPopover()
    }

    @objc private func showFloatingPodAction() {
        FloatingDropTargetController.shared.show()
    }

    @objc private func toggleLauncher() {
        FloatingPanelController.shared.toggle()
    }

    @objc private func quickCompressImage() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "image.compress") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func quickConvertImage() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "image.convert") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func quickCompressPDF() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "pdf.compress") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func quickMergePDF() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "pdf.merge") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func quickCreateArchive() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "archive.compress") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func quickGenerateQR() {
        FloatingPanelController.shared.show()
        if let cmd = FloatingPanelController.shared.viewModel.registry.command(id: "qr.generate") {
            FloatingPanelController.shared.viewModel.selectCommand(cmd)
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
