import AppKit
import CoreVideo

/// Drives a per-frame callback (synced to the display refresh) carrying the
/// current global cursor location. Uses `NSEvent.mouseLocation` polling, which
/// requires no Accessibility permission.
final class CursorTracker {
    var onTick: ((CGPoint) -> Void)?

    private var link: CVDisplayLink?

    func start() {
        guard link == nil else { return }
        var newLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&newLink)
        guard let newLink else { return }
        link = newLink

        let context = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(newLink, { (_, _, _, _, _, ctx) -> CVReturn in
            guard let ctx else { return kCVReturnSuccess }
            let tracker = Unmanaged<CursorTracker>.fromOpaque(ctx).takeUnretainedValue()
            let location = NSEvent.mouseLocation
            DispatchQueue.main.async { tracker.onTick?(location) }
            return kCVReturnSuccess
        }, context)

        CVDisplayLinkStart(newLink)
    }

    func stop() {
        if let link {
            CVDisplayLinkStop(link)
            self.link = nil
        }
    }

    deinit { stop() }
}
