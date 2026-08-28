import AppKit

/// Draws a soft radial glow that follows the cursor, rendered into the shared
/// overlay's `haloLayer`.
final class HaloController {
    private let host: OverlayController
    private let gradient = CAGradientLayer()
    private var active = false

    init(host: OverlayController) {
        self.host = host
    }

    func setActive(_ on: Bool, settings: AppState) {
        active = on
        if on {
            host.layerActivated(true, screen: nil) // create the window/layers first
            configure(settings: settings)
            host.haloLayer.isHidden = false
        } else {
            host.haloLayer.isHidden = true
            host.layerActivated(false, screen: nil)
        }
    }

    private func configure(settings: AppState) {
        let diameter = settings.haloDiameter
        let color = NSColor(hex: settings.haloColorHex)
        let center = color.withAlphaComponent(settings.haloOpacity)
        let edge = color.withAlphaComponent(0)

        let layer = host.haloLayer
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        layer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)

        gradient.frame = layer.bounds
        gradient.type = .radial
        gradient.colors = [center.cgColor, center.cgColor, edge.cgColor]
        gradient.locations = [0.0, 0.35, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        if gradient.superlayer == nil { layer.addSublayer(gradient) }
    }

    /// Re-apply size/color to the live layer (called from the menu-bar sliders).
    func applySize(_ settings: AppState) {
        guard active else { return }
        configure(settings: settings)
    }

    func update(localPoint: CGPoint) {
        guard active else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        host.haloLayer.position = localPoint
        CATransaction.commit()
    }
}
