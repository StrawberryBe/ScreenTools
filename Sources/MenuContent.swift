import SwiftUI

/// The menu-bar panel (window style): toggles for every tool plus live size
/// sliders for the three visual tools (halo, magnifier, spotlight).
struct MenuContent: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Screen Tools")
                .font(.headline)

            toolRow(.halo, "Mouse Halo", "1")
            sizeSlider(app.haloSize, range: 40...200)

            toolRow(.magnifier, "Magnifier", "2")
            sizeSlider(app.magnifierSize, range: 120...480)

            toolRow(.spotlight, "Spotlight", "3")
            sizeSlider(app.spotlightSize, range: 60...400)

            Divider()

            toolRow(.countdown, "Countdown", "4")

            Divider()

            Button("Turn Everything Off") { app.turnEverythingOff() }
                .frame(maxWidth: .infinity)

            HStack {
                SettingsLink { Text("Settings…") }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func toolRow(_ tool: Tool, _ name: String, _ key: String) -> some View {
        HStack {
            Toggle(isOn: app.binding(for: tool)) { Text(name) }
                .toggleStyle(.switch)
            Spacer()
            Text("⌥⌘\(key)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sizeSlider(_ value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle").font(.caption2).foregroundStyle(.secondary)
            Slider(value: value, in: range)
            Image(systemName: "circle.fill").font(.body).foregroundStyle(.secondary)
        }
        .padding(.leading, 6)
    }
}
