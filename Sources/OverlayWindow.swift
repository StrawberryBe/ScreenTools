import AppKit

/// A transparent, borderless, click-through window that floats above everything
/// (including full-screen apps) on a single display.
final class OverlayWindow: NSWindow {
    init(screenFrame: NSRect) {
        super.init(contentRect: screenFrame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let root = NSView(frame: NSRect(origin: .zero, size: screenFrame.size))
        root.wantsLayer = true
        // Use the AppKit-managed backing layer (do NOT assign a custom layer,
        // which would switch the view to layer-hosting and leave the layer
        // unsized). Sublayers are added by OverlayController.
        root.layer?.masksToBounds = false
        contentView = root
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Owns the single shared click-through overlay window and hosts the layers for
/// the halo, spotlight, and magnifier tools. The window is repositioned only
/// when the cursor crosses to a different display — never per frame.
final class OverlayController {
    let haloLayer = CALayer()
    let spotlightLayer = CALayer()
    let magnifierLayer = CALayer()

    private var window: OverlayWindow?
    private var currentScreen: NSScreen?
    private var activeLayers = 0

    private func ensureWindow(for screen: NSScreen) {
        if window == nil {
            let win = OverlayWindow(screenFrame: screen.frame)
            if let host = win.contentView?.layer {
                for layer in [spotlightLayer, magnifierLayer, haloLayer] {
                    layer.isHidden = true
                    host.addSublayer(layer)
                }
                // Full-bleed layers cover the whole screen.
                spotlightLayer.frame = win.contentView?.bounds ?? .zero
            }
            window = win
            currentScreen = screen
        }
        move(to: screen)
    }

    /// Reposition/resize the overlay to a screen (only when the screen changes).
    func move(to screen: NSScreen) {
        guard let window, let content = window.contentView else { return }
        guard screen !== currentScreen || window.frame != screen.frame else { return }
        currentScreen = screen
        window.setFrame(screen.frame, display: true)
        content.frame = NSRect(origin: .zero, size: screen.frame.size)
        CATransaction.begin(); CATransaction.setDisableActions(true)
        spotlightLayer.frame = content.bounds
        CATransaction.commit()
    }

    /// Called by a feature when it becomes active/inactive so the shared window
    /// is shown while at least one layer needs it and hidden otherwise.
    func layerActivated(_ active: Bool, screen: NSScreen?) {
        if active {
            if let screen = screen ?? NSScreen.main { ensureWindow(for: screen) }
            activeLayers += 1
            window?.orderFrontRegardless()
        } else {
            activeLayers = max(0, activeLayers - 1)
            if activeLayers == 0 { window?.orderOut(nil) }
        }
    }
}
