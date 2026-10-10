import AppKit

@MainActor
public final class SoundEffectManager {
    public static let shared = SoundEffectManager()

    private let preferences = PreferencesManager.shared

    private init() {}

    public func playSuccess() {
        guard preferences.playSounds else { return }
        NSSound(named: NSSound.Name("Glass"))?.play()
    }

    public func playError() {
        guard preferences.playSounds else { return }
        NSSound.beep()
    }
}
