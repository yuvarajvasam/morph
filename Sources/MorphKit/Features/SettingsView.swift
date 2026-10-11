import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var preferences: PreferencesManager
    var onDismiss: () -> Void

    public init(preferences: PreferencesManager = PreferencesManager.shared, onDismiss: @escaping () -> Void) {
        self.preferences = preferences
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SettingsWindowView(layoutMode: .tabs)
    }
}
