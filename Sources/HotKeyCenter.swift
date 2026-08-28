import AppKit
import HotKey

/// Registers the system-wide hotkeys. Uses the `HotKey` package (a Carbon
/// `RegisterEventHotKey` wrapper) which works globally without Accessibility
/// permission. The Escape hotkey is only registered while a tool is active, so
/// we never hijack Escape system-wide.
final class HotKeyCenter {
    private weak var app: AppState?
    private var keys: [HotKey] = []
    private var escapeKey: HotKey?

    init(app: AppState) {
        self.app = app
        register(.one,   [.command, .option]) { [weak app] in app?.toggle(.halo) }
        register(.two,   [.command, .option]) { [weak app] in app?.toggle(.magnifier) }
        register(.three, [.command, .option]) { [weak app] in app?.toggle(.spotlight) }
        register(.four,  [.command, .option]) { [weak app] in app?.toggle(.countdown) }
        register(.equal, [.command, .option]) { [weak app] in app?.adjustMagnifierZoom(by: 0.5) }
        register(.minus, [.command, .option]) { [weak app] in app?.adjustMagnifierZoom(by: -0.5) }
    }

    private func register(_ key: Key, _ modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        let hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey.keyDownHandler = action
        keys.append(hotKey)
    }

    func setEscapeEnabled(_ enabled: Bool) {
        if enabled {
            guard escapeKey == nil else { return }
            let key = HotKey(key: .escape, modifiers: [])
            key.keyDownHandler = { [weak app] in app?.turnEverythingOff() }
            escapeKey = key
        } else {
            escapeKey = nil
        }
    }
}
