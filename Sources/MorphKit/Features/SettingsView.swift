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
        VStack(spacing: 0) {
            // Header with Open in Dedicated Window option
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 15))
                    Text("Settings")
                        .font(.system(size: 15, weight: .semibold))
                }

                Spacer()

                GlassButton("Open Dedicated Window", icon: "macwindow", shortcutBadge: "⌘,", variant: .secondary) {
                    onDismiss()
                    SettingsWindowController.shared.show()
                }

                GlassButton("Done", shortcutBadge: "⎋", variant: .primary) {
                    onDismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().overlay(.quaternary)

            // Embed SettingsWindowView
            SettingsWindowView()
        }
        .frame(minWidth: 680, minHeight: 460)
        .liquidGlassWindow(radius: 18)
    }
}
