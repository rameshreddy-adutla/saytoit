import AppKit
import SwiftUI

/// Floating HUD window that appears during recording — shows blinking red dot,
/// elapsed time, and live rolling transcript text.
@MainActor
final class RecordingHUD {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<RecordingHUDView>?

    func show(appState: AppState) {
        guard panel == nil else { return }

        let view = RecordingHUDView(appState: appState)
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(x: 0, y: 0, width: 340, height: 120)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentViewController = hosting

        // Position at bottom center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let hudWidth: CGFloat = 340
            let hudHeight: CGFloat = 120
            let x = screenFrame.midX - hudWidth / 2
            let y = screenFrame.minY + 60
            panel.setFrame(NSRect(x: x, y: y, width: hudWidth, height: hudHeight), display: true)
        }

        panel.orderFrontRegardless()
        self.panel = panel
        self.hostingController = hosting
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        hostingController = nil
    }
}

/// The SwiftUI view rendered inside the floating HUD panel.
struct RecordingHUDView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Top row: blinking dot + status + timer
            HStack(spacing: 10) {
                BlinkingDot()
                Text("Recording")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(elapsedText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Live transcript rolling text
            if !appState.currentTranscript.isEmpty || !appState.interimText.isEmpty {
                Text(liveText)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .truncationMode(.head)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.15), value: liveText)
            } else {
                Text("Listening...")
                    .font(.callout.italic())
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
    }

    private var liveText: String {
        var text = appState.currentTranscript
        if !appState.interimText.isEmpty {
            if !text.isEmpty { text += " " }
            text += appState.interimText
        }
        // Show last ~120 chars so it feels like rolling text
        if text.count > 120 {
            return "…" + String(text.suffix(120))
        }
        return text
    }

    private var elapsedText: String {
        guard let start = appState.recordingStartTime else { return "00:00" }
        let elapsed = Date().timeIntervalSince(start)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Classic blinking red recording dot.
struct BlinkingDot: View {
    @State private var isOn = true

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .shadow(color: .red.opacity(0.6), radius: 6)
            .opacity(isOn ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isOn = false
                }
            }
    }
}
