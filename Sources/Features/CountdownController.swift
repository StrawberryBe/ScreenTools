import AppKit
import SwiftUI
import Combine

/// Owns a draggable floating HUD panel that shows a large countdown timer.
final class CountdownController: ObservableObject {
    @Published var remaining: Int = 300
    @Published var isRunning = false
    @Published var finished = false

    private var panel: NSPanel?
    private var timer: Timer?

    func setVisible(_ visible: Bool, settings: AppState) {
        if visible {
            if remaining == 0 || !isRunning { remaining = settings.countdownDefaultSeconds }
            showPanel()
        } else {
            pause()
            panel?.orderOut(nil)
        }
    }

    private func showPanel() {
        if panel == nil {
            let hosting = NSHostingView(rootView: CountdownView(controller: self))
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 400),
                                styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
                                backing: .buffered, defer: false)
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.contentView = hosting
            self.panel = panel
        }
        centerOnActiveScreen()
        panel?.orderFrontRegardless()
    }

    private func centerOnActiveScreen() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let screen else { return }
        let f = screen.frame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.midY - size.height / 2))
    }

    // MARK: Timer controls

    func start() {
        guard !isRunning, remaining > 0 else { return }
        isRunning = true
        finished = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset(to seconds: Int) {
        pause()
        finished = false
        remaining = seconds
    }

    func adjust(by delta: Int) {
        remaining = max(0, remaining + delta)
    }

    private func tick() {
        guard remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 {
            pause()
            finished = true
            NSSound.beep()
        }
    }
}
