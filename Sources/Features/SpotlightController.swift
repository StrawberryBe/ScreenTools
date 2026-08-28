import AppKit

/// Dims the whole screen except a bright circle that follows the cursor.
/// Implemented as a full-screen dim layer masked with an even-odd path
/// (rectangle minus a circle → the circle becomes a hole).
final class SpotlightController {
    private let host: OverlayController
    private let mask = CAShapeLayer()
    private var active = false
    private var radius: CGFloat = 140
    private var lastPoint: CGPoint = .zero
    private var lastRadius: CGFloat?
    private var lastBounds: CGRect?

    init(host: OverlayController) {
        self.host = host
        mask.fillRule = .evenOdd
        mask.fillColor = NSColor.black.cgColor
    }

    func setActive(_ on: Bool, settings: AppState) {
        active = on
        if on {
            host.layerActivated(true, screen: nil) // create the window/layers first
            radius = settings.spotlightRadius
            let dim = host.spotlightLayer
            dim.backgroundColor = NSColor.black.withAlphaComponent(settings.spotlightDim).cgColor
            mask.frame = dim.bounds
            dim.mask = mask
            dim.isHidden = false
            update(localPoint: NSEvent.mouseLocation) // seed with something sensible
        } else {
            host.spotlightLayer.isHidden = true
            host.layerActivated(false, screen: nil)
        }
    }

    /// Re-apply radius to the live mask (called from the menu-bar slider).
    func applySize(_ settings: AppState) {
        radius = settings.spotlightRadius
        if active { update(localPoint: lastPoint) }
    }

    func update(localPoint: CGPoint) {
        guard active else { return }
        let dim = host.spotlightLayer
        guard localPoint != lastPoint || radius != lastRadius || dim.bounds != lastBounds else { return }
        lastPoint = localPoint
        lastRadius = radius
        lastBounds = dim.bounds

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.frame = dim.bounds
        let path = CGMutablePath()
        path.addRect(dim.bounds)
        path.addEllipse(in: CGRect(x: localPoint.x - radius,
                                   y: localPoint.y - radius,
                                   width: radius * 2,
                                   height: radius * 2))
        mask.path = path
        CATransaction.commit()
    }
}
