import SwiftUI
import AppKit

public final class MorphSettingsWindow: NSWindow {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    public let tabState = SettingsTabState()
    private var window: MorphSettingsWindow?

    public override init() {
        super.init()
    }

    public func setupWindow() {
        guard window == nil else { return }

        let settingsView = SettingsWindowView(tabState: tabState)
        let hostingView = NSHostingView(rootView: settingsView)

        let newWindow = MorphSettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Morph Settings"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = true
        newWindow.isMovableByWindowBackground = true
        newWindow.standardWindowButton(.closeButton)?.isHidden = true
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.minSize = NSSize(width: 780, height: 520)
        newWindow.contentView = hostingView
        newWindow.delegate = self
        newWindow.isReleasedWhenClosed = false
        newWindow.center()

        self.window = newWindow
    }

    public func show(section: SettingsTab? = nil) {
        if window == nil {
            setupWindow()
        }

        if let section {
            tabState.selectedTab = section
        }

        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        window?.orderOut(nil)
    }

    public func windowWillClose(_ notification: Notification) {
        // Keep window instance alive so state is preserved
    }
}
