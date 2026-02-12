import AppKit
import SwiftUI

// MARK: - HUD Phase

enum HUDPhase: Equatable {
    case recording
    case processing
    case delivering
    case success
    case failure(String)

    var color: Color {
        switch self {
        case .recording: return .red
        case .processing: return Color.brandAccent
        case .delivering: return .green
        case .success: return .green
        case .failure: return Color.brandCoral
        }
    }

    var headline: String {
        switch self {
        case .recording: return "Recording"
        case .processing: return "Transcribing…"
        case .delivering: return "Pasting…"
        case .success: return "Done"
        case .failure: return "Failed"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .success, .failure: return true
        default: return false
        }
    }
}

// MARK: - HUD Window Presenter

/// Full-screen transparent NSPanel — the SwiftUI overlay floats at the bottom.
/// This approach prevents bouncing because the window never resizes.
@MainActor
final class RecordingHUD {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<HUDWindowContent>?

    func show(appState: AppState, phase: HUDPhase) {
        if panel != nil {
            // Already showing — just update the view
            hostingController?.rootView = HUDWindowContent(appState: appState, phase: phase)
            return
        }

        let content = HUDWindowContent(appState: appState, phase: phase)
        let hosting = NSHostingController(rootView: content)

        // Use the FULL screen frame so the panel never needs to resize
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentViewController = hosting

        panel.orderFrontRegardless()
        self.panel = panel
        self.hostingController = hosting
    }

    func updatePhase(_ phase: HUDPhase) {
        guard let hosting = hostingController else { return }
        let currentRoot = hosting.rootView
        hosting.rootView = HUDWindowContent(appState: currentRoot.appState, phase: phase)
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        hostingController = nil
    }
}

// MARK: - Window Content (full-screen transparent container)

struct HUDWindowContent: View {
    @ObservedObject var appState: AppState
    let phase: HUDPhase

    var body: some View {
        ZStack {
            Color.clear
            HUDOverlayView(appState: appState, phase: phase)
                .padding(.horizontal, 72)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

// MARK: - HUD Overlay (the visible pill)

struct HUDOverlayView: View {
    @ObservedObject var appState: AppState
    let phase: HUDPhase

    private var hasTranscript: Bool {
        !appState.currentTranscript.isEmpty || !appState.interimText.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            animatedGlyph

            VStack(spacing: 4) {
                Text(phase.headline)
                    .font(.headline)
                    .foregroundStyle(headlineColor)

                if case .failure(let msg) = phase {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // Audio level meter during recording
            if case .recording = phase {
                AudioLevelMeter(level: appState.audioLevel)
                    .frame(width: 120, height: 4)
                    .padding(.top, 2)
            }

            // Elapsed timer (not on terminal phases)
            if !phase.isTerminal {
                Text(elapsedText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // Live transcript during recording
            if case .recording = phase, hasTranscript {
                liveTranscriptView
                    .padding(.top, 4)
            }

            // Stop hint during recording
            if case .recording = phase {
                Text("⌘⇧S to stop")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(hudBackground)
        .overlay(hudStroke)
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: phase)
        .frame(maxWidth: hasTranscript ? 420 : 280)
    }

    // MARK: - Background + Stroke

    private var hudBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.thickMaterial)
            .overlay(phaseTint)
    }

    private var hudStroke: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(phase.color.opacity(0.45), lineWidth: phase.isTerminal ? 2 : 1)
    }

    @ViewBuilder
    private var phaseTint: some View {
        if case .failure = phase {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(phase.color.opacity(0.15))
        }
    }

    private var headlineColor: Color {
        if case .failure = phase { return phase.color }
        return .primary
    }

    // MARK: - Animated Glyph

    @ViewBuilder
    private var animatedGlyph: some View {
        switch phase {
        case .failure:
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                let s = 0.9 + (t < 0.5 ? t : 1 - t) * 0.35
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(phase.color.gradient)
                    .scaleEffect(s)
                    .shadow(color: phase.color.opacity(0.45), radius: 10, x: 0, y: 6)
            }
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.green)
                .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 4)
        default:
            // Pulsing colored dot for recording/processing/delivering
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                let s = 0.9 + (t < 0.5 ? t : 1 - t) * 0.4
                Circle()
                    .fill(phase.color.gradient)
                    .frame(width: 18, height: 18)
                    .scaleEffect(s)
                    .shadow(color: phase.color.opacity(0.4), radius: 6, x: 0, y: 4)
            }
        }
    }

    // MARK: - Live Transcript

    private var liveTranscriptView: some View {
        let text = liveText
        let isFinal = appState.interimText.isEmpty && !appState.currentTranscript.isEmpty
        return Text(text)
            .font(isFinal ? .callout : .callout.italic())
            .fontWeight(isFinal ? .regular : .light)
            .foregroundStyle(isFinal ? .primary : .secondary)
            .lineLimit(2)
            .truncationMode(.head)
            .frame(maxWidth: 360)
            .animation(.easeInOut(duration: 0.2), value: text)
    }

    private var liveText: String {
        var text = appState.currentTranscript
        if !appState.interimText.isEmpty {
            if !text.isEmpty { text += " " }
            text += appState.interimText
        }
        if text.count > 200 {
            return "…" + String(text.suffix(200))
        }
        return text
    }

    // MARK: - Timer

    private var elapsedText: String {
        guard let start = appState.recordingStartTime else { return "00:00" }
        let elapsed = max(Date().timeIntervalSince(start), 0)
        let totalHundredths = Int((elapsed * 100).rounded())
        let minutes = totalHundredths / 6000
        let seconds = (totalHundredths / 100) % 60
        let hundredths = totalHundredths % 100
        if minutes > 0 {
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        }
        return String(format: "%02d.%02ds", seconds, hundredths)
    }
}

// MARK: - Audio Level Meter

struct AudioLevelMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(level, 0.02), 1)))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
    }
}
