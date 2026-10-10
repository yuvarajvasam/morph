import Foundation
import Carbon
import AppKit

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    theEvent: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    Task { @MainActor in
        GlobalHotkeyManager.shared.handleHotkeyTriggered()
    }
    return noErr
}

@MainActor
public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    private init() {}

    public func register(
        keyCode: UInt32 = UInt32(kVK_Space),
        modifiers: UInt32 = UInt32(optionKey),
        action: @escaping () -> Void
    ) {
        self.action = action

        // 1. Install event handler if not already installed
        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            InstallEventHandler(
                GetApplicationEventTarget(),
                hotKeyEventHandler,
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )
        }

        // 2. Unregister existing hotkey if any
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }

        // 3. Register hotkey ('MORP', id: 1)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D4F5250), id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            print("✨ Global hotkey registered: Option + Space")
        } else {
            print("⚠️ Failed to register global hotkey (status: \(status))")
        }
    }

    public func unregister() {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    fileprivate func handleHotkeyTriggered() {
        action?()
    }
}
