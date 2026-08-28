import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppState

    private var haloColor: Binding<Color> {
        Binding(get: { Color(hex: app.haloColorHex) },
                set: { app.haloColorHex = NSColor($0).hexString })
    }
    private var paintColor: Binding<Color> {
        Binding(get: { Color(hex: app.paintColorHex) },
                set: { app.paintColorHex = NSColor($0).hexString })
    }

    var body: some View {
        TabView {
            Form {
                Section("Mouse Halo") {
                    ColorPicker("Color", selection: haloColor, supportsOpacity: false)
                    LabeledSlider(title: "Size", value: $app.haloDiameter, range: 40...200, unit: "pt")
                    LabeledSlider(title: "Opacity", value: $app.haloOpacity, range: 0.1...1.0, unit: "")
                }
                Section("Spotlight") {
                    LabeledSlider(title: "Radius", value: $app.spotlightRadius, range: 60...400, unit: "pt")
                    LabeledSlider(title: "Dimming", value: $app.spotlightDim, range: 0.2...0.9, unit: "")
                }
                Section("Magnifier") {
                    LabeledSlider(title: "Size", value: $app.magnifierDiameter, range: 120...480, unit: "pt")
                    LabeledSlider(title: "Zoom", value: $app.magnifierZoom, range: 1.2...8.0, unit: "×")
                }
                Section("Paint") {
                    ColorPicker("Color", selection: paintColor, supportsOpacity: false)
                    LabeledSlider(title: "Brush width", value: $app.paintWidth, range: 1...40, unit: "pt")
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Tools", systemImage: "slider.horizontal.3") }

            ShortcutsHelp()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 420, height: 460)
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Slider(value: $value, in: range)
            Text(unit.isEmpty ? String(format: "%.2f", value) : "\(Int(value))\(unit)")
                .monospacedDigit()
                .frame(width: 52, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ShortcutsHelp: View {
    private let rows: [(String, String)] = [
        ("Mouse Halo", "⌥⌘1"),
        ("Magnifier", "⌥⌘2"),
        ("Spotlight", "⌥⌘3"),
        ("Paint", "⌥⌘4"),
        ("Countdown", "⌥⌘5"),
        ("Zoom in / out (magnifier)", "⌥⌘=  /  ⌥⌘-"),
        ("Turn everything off", "Esc")
    ]

    var body: some View {
        Form {
            Section("Global shortcuts") {
                ForEach(rows, id: \.0) { row in
                    HStack {
                        Text(row.0)
                        Spacer()
                        Text(row.1).monospaced().foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                Text("Escape works only while a tool is active, so it never interferes with Escape in other apps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
