import AppKit

@MainActor
public final class AppMenuManager: NSObject {
    public static let shared = AppMenuManager()

    private var localKeyDownMonitor: Any?

    public override init() {
        super.init()
    }

    /// Sets up the complete application main menu and universal keyboard shortcut monitor
    public func setup() {
        setupMainMenu()
        setupUniversalKeyboardMonitor()
    }

    /// Configures the macOS NSApplication.shared.mainMenu with standard and custom commands
    public func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. Morph App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Morph")

        let aboutItem = NSMenuItem(title: "About Morph", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(aboutItem)

        appMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(NSMenuItem.separator())

        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)

        appMenu.addItem(NSMenuItem.separator())

        let hideItem = NSMenuItem(title: "Hide Morph", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hideItem.keyEquivalentModifierMask = [.command]
        appMenu.addItem(hideItem)

        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        let showAllItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Morph", action: #selector(quitAppAction), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")

        let dropShelfItem = NSMenuItem(title: "Open Drop Shelf", action: #selector(openDropShelfAction), keyEquivalent: "d")
        dropShelfItem.keyEquivalentModifierMask = [.command]
        dropShelfItem.target = self
        fileMenu.addItem(dropShelfItem)

        let toggleLauncherItem = NSMenuItem(title: "Toggle Command Launcher", action: #selector(toggleLauncherAction), keyEquivalent: " ")
        toggleLauncherItem.keyEquivalentModifierMask = [.option]
        toggleLauncherItem.target = self
        fileMenu.addItem(toggleLauncherItem)

        fileMenu.addItem(NSMenuItem.separator())

        let closeItem = NSMenuItem(title: "Close Window", action: #selector(closeFrontmostAction), keyEquivalent: "w")
        closeItem.keyEquivalentModifierMask = [.command]
        closeItem.target = self
        fileMenu.addItem(closeItem)

        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Edit Menu (Standard text editing responders)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")

        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 4. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    /// Installs universal application-level key monitor ensuring shortcuts always work across all windows/popovers
    private func setupUniversalKeyboardMonitor() {
        guard localKeyDownMonitor == nil else { return }

        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let chars = event.charactersIgnoringModifiers?.lowercased()

            // 1. Command + Q -> Always terminate immediately
            if flags == .command && chars == "q" {
                self.quitAppAction()
                return nil
            }

            // 2. Command + , -> Open Settings
            if flags == .command && event.charactersIgnoringModifiers == "," {
                self.openSettingsAction()
                return nil
            }

            // 3. Command + D -> Toggle Drop Shelf
            if flags == .command && chars == "d" {
                self.openDropShelfAction()
                return nil
            }

            // 4. Command + W -> Close frontmost window/popover
            if flags == .command && chars == "w" {
                self.closeFrontmostAction()
                return nil
            }

            return event
        }
    }

    // MARK: - Actions
    @objc public func quitAppAction() {
        NSApp.terminate(nil)
    }

    @objc public func openSettingsAction() {
        SettingsWindowController.shared.show()
    }

    @objc public func openDropShelfAction() {
        StatusBarController.shared.toggleShelf()
    }

    @objc public func toggleLauncherAction() {
        FloatingPanelController.shared.toggle()
    }

    @objc public func closeFrontmostAction() {
        if StatusBarController.shared.isShelfPopoverShown {
            StatusBarController.shared.hideShelfPopover()
            return
        }
        if SettingsWindowController.shared.isVisible {
            SettingsWindowController.shared.hide()
            return
        }
        if FloatingPanelController.shared.isVisible {
            FloatingPanelController.shared.hide()
            return
        }
        if let keyWindow = NSApp.keyWindow {
            keyWindow.performClose(nil)
        }
    }
}
