import SwiftUI
import AppKit

public final class MorphFloatingPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}

@MainActor
public final class FloatingPanelController: NSObject, NSWindowDelegate {
    public static let shared = FloatingPanelController()

    public let viewModel = LauncherViewModel()
    private var panel: MorphFloatingPanel?
    private var eventMonitor: Any?

    public override init() {
        super.init()
    }

    public func setupPanel() {
        guard panel == nil else { return }

        let launcherView = LauncherView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: launcherView)

        let dims = PreferencesManager.shared.launcherSize.dimensions
        let newPanel = MorphFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: dims.width, height: dims.height),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.contentView = hostingView
        newPanel.delegate = self
        newPanel.center()

        self.panel = newPanel

        setupKeyboardMonitor()
    }

    public func toggle() {
        if panel == nil {
            setupPanel()
        }

        guard let panel else { return }

        if panel.isVisible && panel.isKeyWindow {
            panel.orderOut(nil)
        } else {
            show()
        }
    }

    public func show() {
        if panel == nil {
            setupPanel()
        }

        guard let panel else { return }

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        QuickLookManager.shared.dismiss()
        panel?.orderOut(nil)
    }

    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return event }

            // Escape key (53)
            if event.keyCode == 53 {
                QuickLookManager.shared.dismiss()
                if self.viewModel.isShowingSettings ||
                    self.viewModel.currentResult != nil ||
                    self.viewModel.activeCommand != nil ||
                    !self.viewModel.droppedFiles.isEmpty ||
                    self.viewModel.selectedCategory != nil {
                    self.viewModel.goBack()
                    return nil
                }
                if !self.viewModel.searchQuery.isEmpty {
                    self.viewModel.searchQuery = ""
                    return nil
                }
                self.hide()
                return nil
            }

            // Command + W
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
                self.hide()
                return nil
            }

            // Command + Q
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }

            // Command + , (Settings)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                SettingsWindowController.shared.show()
                return nil
            }

            // Command + O (Open / Browse)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "o" {
                if let primaryURL = self.viewModel.currentResult?.primaryOutputURL {
                    self.viewModel.openFile(url: primaryURL)
                } else {
                    self.viewModel.openFilePicker()
                }
                return nil
            }

            // Command + S (Save As in Result view)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "s" {
                if let primaryURL = self.viewModel.currentResult?.primaryOutputURL {
                    self.viewModel.saveOutputAs(url: primaryURL)
                    return nil
                }
            }

            // Command + C (Copy output file in Result view)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "c" {
                if self.viewModel.currentResult != nil {
                    self.viewModel.copyOutputToClipboard()
                    return nil
                }
            }

            // Command + K (Toggle Raycast Action Panel)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k" {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    self.viewModel.isShowingActionPanel.toggle()
                }
                return nil
            }

            // Command + D (Toggle Favorite)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "d" {
                if let cmd = self.viewModel.selectedCommandForActions {
                    self.viewModel.preferences.toggleFavorite(id: cmd.id)
                    return nil
                }
            }

            // Option + Command + C (Copy File Path)
            if event.modifierFlags.contains([.command, .option]) && event.charactersIgnoringModifiers == "c" {
                let targetURL = self.viewModel.currentResult?.primaryOutputURL ?? self.viewModel.droppedFiles.first?.url
                if let targetURL {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(targetURL.path, forType: .string)
                    self.viewModel.copyStatusMessage = "Path Copied"
                    return nil
                }
            }

            // Command + R (Reveal in Finder)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "r" {
                let targetURL = self.viewModel.currentResult?.primaryOutputURL ?? self.viewModel.droppedFiles.first?.url
                if let targetURL {
                    self.viewModel.revealInFinder(url: targetURL)
                    return nil
                }
            }

            // Command + Backspace (Remove dropped files)
            if event.modifierFlags.contains(.command) && event.keyCode == 51 {
                if !self.viewModel.droppedFiles.isEmpty && self.viewModel.activeCommand == nil {
                    self.viewModel.droppedFiles = []
                    return nil
                }
            }

            // Spacebar (Keycode 49) - Quick Look preview in Result view
            if event.keyCode == 49 {
                if self.viewModel.currentResult != nil {
                    self.viewModel.toggleQuickLook()
                    return nil
                }
            }

            // Command + [ or Command + Left (Go back)
            if event.modifierFlags.contains(.command) && (event.charactersIgnoringModifiers == "[" || event.keyCode == 123) {
                if self.viewModel.isShowingSettings ||
                    self.viewModel.currentResult != nil ||
                    self.viewModel.activeCommand != nil ||
                    !self.viewModel.droppedFiles.isEmpty ||
                    self.viewModel.selectedCategory != nil {
                    self.viewModel.goBack()
                    return nil
                }
            }

            // Command + N (New Action in Result view)
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
                if self.viewModel.currentResult != nil {
                    self.viewModel.clearAll()
                    return nil
                }
            }

            // Navigation in Command List: Up (126), Down (125), Return (36)
            if self.viewModel.activeCommand == nil && self.viewModel.currentResult == nil && !self.viewModel.isShowingSettings {
                if event.keyCode == 126 {
                    self.viewModel.navigateUp()
                    return nil
                }
                if event.keyCode == 125 {
                    self.viewModel.navigateDown()
                    return nil
                }
                if event.keyCode == 36 {
                    self.viewModel.selectCurrent()
                    return nil
                }
            }

            // Return key (36) - Execute active command when inside a tool
            if self.viewModel.activeCommand != nil && !self.viewModel.isProcessing {
                let isQR = (self.viewModel.activeCommand?.id == "qr.generate" || self.viewModel.activeCommand?.id == "barcode.generate")
                if !self.viewModel.droppedFiles.isEmpty || isQR {
                    if event.keyCode == 36 {
                        Task {
                            await self.viewModel.runActiveCommand()
                        }
                        return nil
                    }
                }
            }

            return event
        }
    }

    public func applySize(_ sizePreset: LauncherSizePreset) {
        guard let panel = self.panel else { return }
        let dims = sizePreset.dimensions
        panel.setContentSize(NSSize(width: dims.width, height: dims.height))
        panel.center()
    }

    public func windowDidResignKey(_ notification: Notification) {
        if PreferencesManager.shared.autoDismissOnBlur {
            hide()
        }
    }
}
