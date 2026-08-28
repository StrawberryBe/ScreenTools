import AppKit
import ScreenCaptureKit
import CoreImage
import CoreMedia

/// A "looking glass" that captures the display and shows a zoomed circle of the
/// area under the cursor. Capture runs only while active.
final class MagnifierController: NSObject, SCStreamOutput {
    private let host: OverlayController
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let sampleQueue = DispatchQueue(label: "com.local.screentools.magnifier")

    private var stream: SCStream?
    private var active = false

    // Snapshotted on the main thread, read on the capture queue.
    private let stateLock = NSLock()
    private var cursorGlobal: CGPoint = .zero
    private var screenFrame: NSRect = .zero
    private var scale: CGFloat = 2
    private var zoom: CGFloat = 2
    private var cropPoints: CGFloat = 120

    init(host: OverlayController) {
        self.host = host
        super.init()
    }

    func setActive(_ on: Bool, settings: AppState, screen: NSScreen?) {
        active = on
        let layer = host.magnifierLayer
        if on {
            host.layerActivated(true, screen: screen) // create the window/layers first

            let diameter = settings.magnifierDiameter
            layer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            layer.cornerRadius = diameter / 2
            layer.masksToBounds = true
            layer.borderWidth = 4
            layer.borderColor = NSColor(hex: settings.haloColorHex).cgColor
            layer.backgroundColor = NSColor.black.cgColor
            layer.contentsGravity = .resizeAspectFill
            layer.isHidden = false

            stateLock.lock()
            zoom = settings.magnifierZoom
            cropPoints = diameter / max(1.2, settings.magnifierZoom)
            stateLock.unlock()

            if let screen { Task { await start(screen: screen) } }
        } else {
            layer.isHidden = true
            host.layerActivated(false, screen: nil)
            Task { await stop() }
        }
    }

    /// Re-apply diameter/zoom to the live layer (called from the menu-bar slider
    /// and the zoom hotkeys).
    func applySize(_ settings: AppState) {
        let d = settings.magnifierDiameter
        stateLock.lock()
        zoom = settings.magnifierZoom
        cropPoints = d / max(1.2, settings.magnifierZoom)
        stateLock.unlock()
        guard active else { return }
        let layer = host.magnifierLayer
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.bounds = CGRect(x: 0, y: 0, width: d, height: d)
        layer.cornerRadius = d / 2
        CATransaction.commit()
    }

    func reconfigure(for screen: NSScreen, settings: AppState) {
        guard active else { return }
        Task {
            await stop()
            await start(screen: screen)
        }
    }

    func update(globalPoint: CGPoint, localPoint: CGPoint, screen: NSScreen) {
        guard active else { return }
        stateLock.lock()
        cursorGlobal = globalPoint
        screenFrame = screen.frame
        scale = screen.backingScaleFactor
        stateLock.unlock()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        host.magnifierLayer.position = localPoint
        CATransaction.commit()
    }

    // MARK: Capture lifecycle

    private func start(screen: NSScreen) async {
        guard ensurePermission() else {
            await MainActor.run { self.failPermission() }
            return
        }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            guard let displayID = screen.displayID,
                  let display = content.displays.first(where: { $0.displayID == displayID }) else { return }

            let myApp = content.applications.first { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
            let filter = SCContentFilter(display: display,
                                         excludingApplications: myApp.map { [$0] } ?? [],
                                         exceptingWindows: [])

            let scaleFactor = screen.backingScaleFactor
            let config = SCStreamConfiguration()
            config.width = Int(screen.frame.width * scaleFactor)
            config.height = Int(screen.frame.height * scaleFactor)
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.queueDepth = 5
            config.showsCursor = false
            config.pixelFormat = kCVPixelFormatType_32BGRA

            let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
            try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            try await newStream.startCapture()
            stream = newStream
        } catch {
            NSLog("Magnifier capture failed: \(error)")
        }
    }

    private func stop() async {
        guard let stream else { return }
        self.stream = nil
        try? await stream.stopCapture()
    }

    private func ensurePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        return CGRequestScreenCaptureAccess()
    }

    private func failPermission() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = "Enable Screen Tools under System Settings → Privacy & Security → Screen Recording, then toggle the magnifier again."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, active,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        stateLock.lock()
        let cursor = cursorGlobal
        let frame = screenFrame
        let s = scale
        let crop = cropPoints
        stateLock.unlock()

        let ci = CIImage(cvImageBuffer: pixelBuffer)
        let extent = ci.extent

        // CIImage and Cocoa both use a bottom-left origin with y increasing up.
        let cx = (cursor.x - frame.minX) * s
        let cy = (cursor.y - frame.minY) * s
        let side = crop * s
        var rect = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
        rect = rect.intersection(extent)
        guard !rect.isNull, rect.width > 2, rect.height > 2 else { return }

        guard let cgImage = ciContext.createCGImage(ci, from: rect) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, self.active else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.host.magnifierLayer.contents = cgImage
            CATransaction.commit()
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
