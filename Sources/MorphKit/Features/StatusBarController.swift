import AppKit

@MainActor
public final class StatusBarController: NSObject {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem?

    public func setupStatusBar() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "Morph")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    public func updateVisibility(_ show: Bool) {
        if show {
            setupStatusBar()
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            FloatingPanelController.shared.toggle()
        }
    }

    public func showMenu() {
        let menu = NSMenu()

        // App Header
        let headerItem = NSMenuItem(title: "Morph — Image & PDF Tools", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

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
        statusItem?.menu = nil // Restore normal toggle behavior for left click
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
