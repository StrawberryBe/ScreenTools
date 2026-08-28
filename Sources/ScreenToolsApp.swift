import SwiftUI
import AppKit

@main
struct ScreenToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Screen Tools", systemImage: "wand.and.rays") {
            MenuContent()
                .environmentObject(delegate.appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(delegate.appState)
                .frame(width: 420)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar only app: no Dock icon, never a foreground activation.
        NSApp.setActivationPolicy(.accessory)
        appState.registerHotKeys()

        // Debug/testing hook: set SCREENTOOLS_DEBUG_TOOL=halo|spotlight|magnifier|countdown
        // to auto-enable a tool on launch (used for automated verification).
        if let name = ProcessInfo.processInfo.environment["SCREENTOOLS_DEBUG_TOOL"] {
            let map: [String: Tool] = [
                "halo": .halo, "spotlight": .spotlight, "magnifier": .magnifier,
                "countdown": .countdown
            ]
            if let tool = map[name.lowercased()] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [appState] in
                    appState.set(tool, on: true)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.tearDown()
    }
}
