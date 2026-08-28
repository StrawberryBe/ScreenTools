import AppKit

/// A full-screen drawing surface. Committed strokes are rendered into a cached
/// image for cheap redraws; each stroke is retained so undo can rebuild it.
final class PaintCanvasView: NSView {

    private struct Stroke {
        var points: [CGPoint]
        var color: NSColor
        var width: CGFloat
        var eraser: Bool
    }

    var strokeColor: NSColor = NSColor(hex: "#FF375F")
    var strokeWidth: CGFloat = 6
    var isEraser = false
    var onChange: (() -> Void)?

    private var strokes: [Stroke] = []
    private var redoStack: [Stroke] = []
    private var current: Stroke?
    private var cache: NSImage?

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Mouse

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        current = Stroke(points: [p], color: strokeColor, width: strokeWidth, eraser: isEraser)
    }

    override func mouseDragged(with event: NSEvent) {
        guard var stroke = current else { return }
        let p = convert(event.locationInWindow, from: nil)
        if let last = stroke.points.last {
            drawSegment(from: last, to: p, stroke: stroke)
        }
        stroke.points.append(p)
        current = stroke
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard var stroke = current else { return }
        if stroke.points.count == 1 { drawDot(at: stroke.points[0], stroke: stroke) }
        strokes.append(stroke)
        redoStack.removeAll() // a new stroke invalidates the redo history
        current = nil
        needsDisplay = true
        onChange?()
    }

    // MARK: Public actions

    var canUndo: Bool { !strokes.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let last = strokes.popLast() else { return }
        redoStack.append(last)
        rebuildCache()
    }

    func redo() {
        guard let stroke = redoStack.popLast() else { return }
        strokes.append(stroke)
        rebuildCache()
    }

    func clearAll() {
        strokes.removeAll()
        redoStack.removeAll()
        current = nil
        cache = nil
        needsDisplay = true
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        cache?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
    }

    private func ensureCache() -> NSImage {
        if let cache, cache.size == bounds.size { return cache }
        let image = NSImage(size: bounds.size)
        // Preserve any existing drawing when the size matches on first creation.
        cache = image
        return image
    }

    private func configureContext(for stroke: Stroke) {
        let ctx = NSGraphicsContext.current
        ctx?.compositingOperation = stroke.eraser ? .clear : .sourceOver
        stroke.color.setStroke()
        stroke.color.setFill()
    }

    private func drawSegment(from a: CGPoint, to b: CGPoint, stroke: Stroke) {
        let image = ensureCache()
        image.lockFocus()
        configureContext(for: stroke)
        let path = NSBezierPath()
        path.lineWidth = stroke.width
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: a)
        path.line(to: b)
        path.stroke()
        image.unlockFocus()
    }

    private func drawDot(at p: CGPoint, stroke: Stroke) {
        let image = ensureCache()
        image.lockFocus()
        configureContext(for: stroke)
        let r = stroke.width / 2
        let dot = NSBezierPath(ovalIn: CGRect(x: p.x - r, y: p.y - r, width: stroke.width, height: stroke.width))
        dot.fill()
        image.unlockFocus()
    }

    private func rebuildCache() {
        let image = NSImage(size: bounds.size)
        if !strokes.isEmpty {
            image.lockFocus()
            for stroke in strokes {
                NSGraphicsContext.current?.compositingOperation = stroke.eraser ? .clear : .sourceOver
                stroke.color.setStroke()
                stroke.color.setFill()
                if stroke.points.count == 1 {
                    let p = stroke.points[0]
                    let r = stroke.width / 2
                    NSBezierPath(ovalIn: CGRect(x: p.x - r, y: p.y - r, width: stroke.width, height: stroke.width)).fill()
                } else {
                    let path = NSBezierPath()
                    path.lineWidth = stroke.width
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.move(to: stroke.points[0])
                    for pt in stroke.points.dropFirst() { path.line(to: pt) }
                    path.stroke()
                }
            }
            image.unlockFocus()
        }
        cache = image
        needsDisplay = true
    }
}
