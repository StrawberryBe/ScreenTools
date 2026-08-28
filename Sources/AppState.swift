import SwiftUI
import AppKit

/// Identifies each toggleable tool.
enum Tool: CaseIterable {
    case halo, magnifier, spotlight, countdown
}

/// Central app controller: holds toggle state + settings, owns the feature
/// controllers, and routes cursor updates and hotkeys to them.
final class AppState: ObservableObject {

    // MARK: Toggle state (observed by the menu UI)
    @Published var haloOn = false
    @Published var magnifierOn = false
    @Published var spotlightOn = false
    @Published var countdownOn = false

    // MARK: Settings (persisted)
    @AppStorage("haloColor")      var haloColorHex = "#FF2D95"
    @AppStorage("haloDiameter")   var haloDiameter = 90.0
    @AppStorage("haloOpacity")    var haloOpacity = 0.55
    @AppStorage("spotlightRadius") var spotlightRadius = 140.0
    @AppStorage("spotlightDim")   var spotlightDim = 0.55
    @AppStorage("magnifierDiameter") var magnifierDiameter = 240.0
    @AppStorage("magnifierZoom")  var magnifierZoom = 2.0
    @AppStorage("countdownSeconds") var countdownDefaultSeconds = 300

    // MARK: Feature controllers
    private lazy var overlay = OverlayController()
    private lazy var halo = HaloController(host: overlay)
    private lazy var spotlight = SpotlightController(host: overlay)
    private lazy var magnifier = MagnifierController(host: overlay)
    private lazy var countdown = CountdownController()

    private let cursor = CursorTracker()
    private var hotKeys: HotKeyCenter?
    private var activeScreen: NSScreen?

    init() {
        cursor.onTick = { [weak self] point in self?.handleCursor(point) }
    }

    // MARK: Hotkeys

    func registerHotKeys() {
        hotKeys = HotKeyCenter(app: self)
    }

    // MARK: Menu binding helpers

    func binding(for tool: Tool) -> Binding<Bool> {
        Binding(
            get: { [weak self] in self?.isOn(tool) ?? false },
            set: { [weak self] newValue in self?.set(tool, on: newValue) }
        )
    }

    func isOn(_ tool: Tool) -> Bool {
        switch tool {
        case .halo: return haloOn
        case .magnifier: return magnifierOn
        case .spotlight: return spotlightOn
        case .countdown: return countdownOn
        }
    }

    func toggle(_ tool: Tool) { set(tool, on: !isOn(tool)) }

    // MARK: Live size controls (bound to the menu-bar sliders)

    var haloSize: Binding<Double> {
        Binding(get: { [weak self] in self?.haloDiameter ?? 90 },
                set: { [weak self] in self?.haloDiameter = $0; self?.halo.applySize(self!) })
    }
    var magnifierSize: Binding<Double> {
        Binding(get: { [weak self] in self?.magnifierDiameter ?? 240 },
                set: { [weak self] in self?.magnifierDiameter = $0; self?.magnifier.applySize(self!) })
    }
    var spotlightSize: Binding<Double> {
        Binding(get: { [weak self] in self?.spotlightRadius ?? 140 },
                set: { [weak self] in self?.spotlightRadius = $0; self?.spotlight.applySize(self!) })
    }

    func set(_ tool: Tool, on: Bool) {
        switch tool {
        case .halo:
            haloOn = on
            halo.setActive(on, settings: self)
        case .magnifier:
            magnifierOn = on
            let magScreen = activeScreen ?? screenUnderCursor()
            if on { activeScreen = magScreen } // avoid a needless first-tick reconfigure
            magnifier.setActive(on, settings: self, screen: magScreen)
        case .spotlight:
            spotlightOn = on
            spotlight.setActive(on, settings: self)
        case .countdown:
            countdownOn = on
            countdown.setVisible(on, settings: self)
        }
        updateCursorTracking()
    }

    func turnEverythingOff() {
        for tool in Tool.allCases { set(tool, on: false) }
    }

    // Only the visual, cursor-following tools need cursor updates.
    private var needsCursor: Bool { haloOn || spotlightOn || magnifierOn }

    private func updateCursorTracking() {
        if needsCursor { cursor.start() } else { cursor.stop() }
        hotKeys?.setEscapeEnabled(haloOn || magnifierOn || spotlightOn || countdownOn)
    }

    // MARK: Cursor routing

    private func screenUnderCursor(_ point: CGPoint? = nil) -> NSScreen? {
        let p = point ?? NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main
    }

    private func handleCursor(_ point: CGPoint) {
        guard let screen = screenUnderCursor(point) else { return }

        if screen !== activeScreen {
            activeScreen = screen
            overlay.move(to: screen)
            if magnifierOn { magnifier.reconfigure(for: screen, settings: self) }
        }

        let local = CGPoint(x: point.x - screen.frame.minX,
                            y: point.y - screen.frame.minY)

        if haloOn { halo.update(localPoint: local) }
        if spotlightOn { spotlight.update(localPoint: local) }
        if magnifierOn { magnifier.update(globalPoint: point, localPoint: local, screen: screen) }
    }

    // MARK: Magnifier zoom (bound to hotkeys)

    func adjustMagnifierZoom(by delta: Double) {
        magnifierZoom = max(1.2, min(8.0, magnifierZoom + delta))
        magnifier.applySize(self)
    }

    func tearDown() {
        cursor.stop()
        turnEverythingOff()
    }
}
