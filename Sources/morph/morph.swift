import AppKit
import SwiftUI
import MorphKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Spotlight/Raycast style accessory application
        NSApp.setActivationPolicy(.accessory)

        // Apply appearance mode from preferences
        PreferencesManager.shared.applyAppearance()

        // Initialize status bar menu item if enabled
        if PreferencesManager.shared.showInMenuBar {
            StatusBarController.shared.setupStatusBar()
        }

        // Setup and display floating command launcher
        FloatingPanelController.shared.setupPanel()
        FloatingPanelController.shared.show()

        // Register Global System-Wide Hotkey (Option + Space)
        GlobalHotkeyManager.shared.register {
            FloatingPanelController.shared.toggle()
        }

        print("✨ Morph launched successfully. Floating launcher active (Option+Space).")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        FloatingPanelController.shared.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalHotkeyManager.shared.unregister()
    }
}

@main
enum MorphApp {
    @MainActor
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if !args.isEmpty {
            // Headless CLI mode (e.g. for Raycast extension, scripts, terminal)
            let exitCode = await CLIHandler.run(arguments: args)
            exit(exitCode)
        } else {
            // Native GUI mode with Liquid Glass floating launcher
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            app.run()
        }
    }
}
