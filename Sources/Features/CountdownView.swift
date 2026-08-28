import SwiftUI

struct CountdownView: View {
    @ObservedObject var controller: CountdownController

    private var timeText: String {
        let m = controller.remaining / 60
        let s = controller.remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 28) {
            Text(timeText)
                .font(.system(size: 150, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(controller.finished ? Color.red : Color.primary)
                .contentTransition(.numericText())
                .animation(.default, value: controller.remaining)

            HStack(spacing: 18) {
                Button { controller.adjust(by: -60) } label: { Image(systemName: "minus") }
                Button {
                    controller.isRunning ? controller.pause() : controller.start()
                } label: {
                    Image(systemName: controller.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 28)
                }
                Button { controller.reset(to: controller.remaining == 0 ? 300 : controller.remaining) } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button { controller.adjust(by: 60) } label: { Image(systemName: "plus") }
            }
            .buttonStyle(.bordered)
            .controlSize(.extraLarge)
            .font(.title2)
        }
        .padding(44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(controller.finished ? Color.red : Color.white.opacity(0.15), lineWidth: 2)
        )
        .padding(10)
    }
}
