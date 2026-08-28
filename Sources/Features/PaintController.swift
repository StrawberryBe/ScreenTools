import AppKit
import SwiftUI

/// Full-screen borderless window that hosts BOTH the drawing canvas and the
/// toolbar. A regular window (not a non-activating panel) owns clicks across its
/// whole frame — including the transparent canvas area — so drawing works
/// everywhere; a non-activating panel would let the window server route clicks
/// over transparent regions through to the app underneath.
final class PaintWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Container that routes clicks deterministically: anything inside the toolbar
/// rectangle goes to the toolbar (and never falls through to the canvas, even on
/// the toolbar's transparent corners); everything else goes to the canvas.
final class PaintContainerView: NSView {
    weak var canvasView: PaintCanvasView?
    weak var toolbarHostView: NSView?

    override func hitTest(_ point: NSPoint) -> NSView? {
        // `point` is in this view's superview coordinates.
        let local = superview != nil ? convert(point, from: superview) : point
        if let toolbar = toolbarHostView, toolbar.frame.contains(local) {
            return toolbar.hitTest(local) ?? toolbar
        }
        return canvasView?.hitTest(local) ?? canvasView
    }
}

final class PaintController: ObservableObject {
    @Published var colorHex: String = "#FF375F" { didSet { pushSettings() } }
    @Published var width: Double = 6 { didSet { pushSettings() } }
    @Published var isEraser = false { didSet { pushSettings() } }

    /// Preset colors shown as swatches in the toolbar.
    static let palette: [String] = [
        "#FF2D95", "#FF3B30", "#FF9500", "#FFD60A",
        "#34C759", "#0A84FF", "#AF52DE", "#FFFFFF", "#000000"
    ]

    private var panel: PaintWindow?
    private var container: PaintContainerView?
    private var canvas: PaintCanvasView?
    private var toolbarHost: NSView?
    private var toolbarDragStart: CGPoint?

    private let toolbarSize = NSSize(width: 470, height: 128)

    func setActive(_ on: Bool, settings: AppState) {
        if on {
            colorHex = settings.paintColorHex
            width = settings.paintWidth
            isEraser = false
            showPaint()
            pushSettings()
        } else {
            panel?.orderOut(nil)
        }
    }

    private func targetScreen() -> NSScreen {
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private func showPaint() {
        let screen = targetScreen()
        if panel == nil {
            let p = PaintWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = .screenSaver
            p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

            let cont = PaintContainerView(frame: NSRect(origin: .zero, size: screen.frame.size))
            cont.autoresizesSubviews = true

            let cv = PaintCanvasView(frame: cont.bounds)
            cv.autoresizingMask = [.width, .height]
            cv.onChange = { [weak self] in self?.objectWillChange.send() }
            cont.addSubview(cv)

            // Toolbar on top; pinned bottom-centre by default (draggable after).
            let tb = NSHostingView(rootView: PaintToolbar(controller: self))
            tb.frame = NSRect(x: (cont.bounds.width - toolbarSize.width) / 2,
                              y: 48,
                              width: toolbarSize.width,
                              height: toolbarSize.height)
            tb.autoresizingMask = [.minXMargin, .maxXMargin, .maxYMargin]
            cont.addSubview(tb)

            cont.canvasView = cv
            cont.toolbarHostView = tb

            p.contentView = cont
            panel = p
            container = cont
            canvas = cv
            toolbarHost = tb
        }
        panel?.setFrame(screen.frame, display: true)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func pushSettings() {
        canvas?.strokeColor = NSColor(hex: colorHex)
        canvas?.strokeWidth = width
        canvas?.isEraser = isEraser
    }

    // MARK: Toolbar dragging

    func dragToolbar(translation: CGSize) {
        guard let host = toolbarHost, let cont = container else { return }
        if toolbarDragStart == nil { toolbarDragStart = host.frame.origin }
        let start = toolbarDragStart!
        var o = CGPoint(x: start.x + translation.width, y: start.y - translation.height) // SwiftUI y is inverted
        o.x = max(0, min(cont.bounds.width - host.frame.width, o.x))
        o.y = max(0, min(cont.bounds.height - host.frame.height, o.y))
        host.autoresizingMask = []
        host.setFrameOrigin(o)
    }

    func endToolbarDrag() { toolbarDragStart = nil }

    // MARK: Actions

    func undo() { canvas?.undo(); objectWillChange.send() }
    func redo() { canvas?.redo(); objectWillChange.send() }
    func clear() { canvas?.clearAll(); objectWillChange.send() }
    var canUndo: Bool { canvas?.canUndo ?? false }
    var canRedo: Bool { canvas?.canRedo ?? false }
}

struct PaintToolbar: View {
    @ObservedObject var controller: PaintController

    private func isSelected(_ hex: String) -> Bool {
        !controller.isEraser && controller.colorHex.caseInsensitiveCompare(hex) == .orderedSame
    }

    var body: some View {
        VStack(spacing: 8) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 44, height: 5)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { controller.dragToolbar(translation: $0.translation) }
                        .onEnded { _ in controller.endToolbarDrag() }
                )

            HStack(spacing: 9) {
                ForEach(PaintController.palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected(hex) ? Color.accentColor : Color.white.opacity(0.35),
                                lineWidth: isSelected(hex) ? 3 : 1)
                        )
                        .contentShape(Circle())
                        .onTapGesture {
                            controller.isEraser = false
                            controller.colorHex = hex
                        }
                }
            }

            HStack(spacing: 14) {
                Image(systemName: "scribble.variable").foregroundStyle(.secondary)
                Slider(value: $controller.width, in: 1...40).frame(width: 120)

                Toggle(isOn: $controller.isEraser) { Image(systemName: "eraser") }
                    .toggleStyle(.button)

                Button { controller.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(!controller.canUndo)
                Button { controller.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                    .disabled(!controller.canRedo)
                Button { controller.clear() } label: { Image(systemName: "trash") }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
