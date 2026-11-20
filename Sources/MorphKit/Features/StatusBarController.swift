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

        // App Header
        let headerItem = NSMenuItem(title: "Morph — Drop Shelf & Utilities", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        let shelfItem = NSMenuItem(title: "Open Drop Shelf", action: #selector(openDropShelfAction), keyEquivalent: "d")
        shelfItem.target = self
        menu.addItem(shelfItem)

        let targetPodItem = NSMenuItem(title: "Show Floating Drop Target", action: #selector(showFloatingPodAction), keyEquivalent: "")
        targetPodItem.target = self
        menu.addItem(targetPodItem)

        let toggleItem = NSMenuItem(title: "Toggle Command Launcher", action: #selector(toggleLauncher), keyEquivalent: " ")
        toggleItem.keyEquivalentModifierMask = [.option]
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Quick Actions
        let compressImageItem = NSMenuItem(title: "Compress Image...", action: #selector(quickCompressImage), keyEquivalent: "")
        compressImageItem.target = self
        menu.addItem(compressImageItem)

        let convertImageItem = NSMenuItem(title: "Convert Image Format...", action: #selector(quickConvertImage), keyEquivalent: "")
        convertImageItem.target = self
        menu.addItem(convertImageItem)

        let compressPDFItem = NSMenuItem(title: "Compress PDF...", action: #selector(quickCompressPDF), keyEquivalent: "")
        compressPDFItem.target = self
        menu.addItem(compressPDFItem)

        let mergePDFItem = NSMenuItem(title: "Merge PDFs...", action: #selector(quickMergePDF), keyEquivalent: "")
        mergePDFItem.target = self
        menu.addItem(mergePDFItem)

        let createArchiveItem = NSMenuItem(title: "Create Archive...", action: #selector(quickCreateArchive), keyEquivalent: "")
        createArchiveItem.target = self
        menu.addItem(createArchiveItem)

        let generateQRItem = NSMenuItem(title: "Generate QR Code...", action: #selector(quickGenerateQR), keyEquivalent: "")
        generateQRItem.target = self
        menu.addItem(generateQRItem)

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
