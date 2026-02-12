import AppKit
import SwiftUI

// MARK: - Fixed-size constants

private let hudWidth: CGFloat = 520
private let hudHeight: CGFloat = 220

// MARK: - HUD Phase

enum HUDPhase {
    case recording
    case processing
    case delivering
    case success
    case failure(String)
    
    var color: Color {
        switch self {
        case .recording: return Color.red
        case .processing: return Color.brandAccent
        case .delivering: return Color.green
        case .success: return Color.green
        case .failure: return Color.brandCoral
        }
    }
    
    var icon: String {
        switch self {
        case .recording: return "waveform"
        case .processing: return "waveform.circle"
        case .delivering: return "arrow.up.doc"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .recording: return "Recording"
        case .processing: return "Transcribing..."
        case .delivering: return "Pasting..."
        case .success: return "Success"
        case .failure: return "Failed"
        }
    }
}

/// Floating HUD window that appears during recording — shows different phases
/// with appropriate visuals for recording, processing, delivering, success, and failure.
@MainActor
final class RecordingHUD {
    private var panel: NSPanel?
    private var hostingController: NSHostingController<RecordingHUDView>?
    private var currentPhase: HUDPhase = .recording

    func show(appState: AppState, phase: HUDPhase) {
        currentPhase = phase
        
        if panel != nil {
            // Update existing view
            hostingController?.rootView = RecordingHUDView(appState: appState, phase: phase)
            return
        }

        let view = RecordingHUDView(appState: appState, phase: phase)
        let hosting = NSHostingController(rootView: view)
        // Lock the hosting view to a fixed size — prevents layout shifts
        hosting.view.setFrameSize(NSSize(width: hudWidth, height: hudHeight))
        hosting.view.autoresizingMask = []

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: hudWidth, height: hudHeight),
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
        // Lock panel size
        panel.minSize = NSSize(width: hudWidth, height: hudHeight)
        panel.maxSize = NSSize(width: hudWidth, height: hudHeight)

        // Position at bottom center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - hudWidth / 2
            let y = screenFrame.minY + 80
            panel.setFrame(NSRect(x: x, y: y, width: hudWidth, height: hudHeight), display: true)
        }

        panel.orderFrontRegardless()
        self.panel = panel
        self.hostingController = hosting
    }
    
    func updatePhase(_ phase: HUDPhase) {
        currentPhase = phase
        guard let hosting = hostingController else { return }
        
        // Update the view with new phase
        if let appState = (hosting.rootView as? RecordingHUDView)?.appState {
            hosting.rootView = RecordingHUDView(appState: appState, phase: phase)
        }
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
    let phase: HUDPhase

    var body: some View {
        VStack(spacing: 0) {
            // Header: phase indicator + title + timer/spinner
            HStack(spacing: 14) {
                phaseIndicator
                
                Text(phase.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                trailingContent
            }
            .padding(.bottom, 16)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
                .padding(.bottom, 14)

            // Content area
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Bottom hint
            if case .recording = phase {
                HStack {
                    Spacer()
                    Text("⌘⇧S to stop")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(24)
        .frame(width: hudWidth, height: hudHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.92)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(phase.color.opacity(0.5), lineWidth: 1.5)
        )
    }
    
    @ViewBuilder
    private var phaseIndicator: some View {
        switch phase {
        case .recording:
            BlinkingDot()
        case .processing, .delivering:
            ProgressView()
                .controlSize(.small)
                .tint(.white)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.green)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.brandCoral)
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        switch phase {
        case .recording:
            Text(elapsedText)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        case .processing, .delivering:
            EmptyView()
        case .success, .failure:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        switch phase {
        case .recording:
            // Live transcript area
            VStack(spacing: 12) {
                AudioLevelBar(level: appState.audioLevel)
                    .frame(height: 8)
                    .padding(.bottom, 4)
                
                Text(liveText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(liveText == "Listening…" ? 0.4 : 0.9))
                    .italic(liveText == "Listening…")
                    .lineLimit(3)
                    .truncationMode(.head)
                    .animation(.easeInOut(duration: 0.15), value: liveText)
            }
        case .processing:
            Text("Processing your transcription...")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
        case .delivering:
            Text("Pasting to frontmost app...")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
        case .success:
            Text("Transcription complete!")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)
        case .failure(let message):
            Text(message)
                .font(.system(size: 16))
                .foregroundStyle(Color.brandCoral.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var liveText: String {
        var text = appState.currentTranscript
        if !appState.interimText.isEmpty {
            if !text.isEmpty { text += " " }
            text += appState.interimText
        }
        if text.isEmpty { return "Listening…" }
        if text.count > 200 {
            return "…" + String(text.suffix(200))
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

/// Classic blinking red recording dot — larger and more visible.
struct BlinkingDot: View {
    @State private var isOn = true

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 18, height: 18)
            .shadow(color: Color.red.opacity(0.7), radius: 10)
            .opacity(isOn ? 1 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isOn = false
                }
            }
    }
}

/// Audio level bar that animates based on input level.
struct AudioLevelBar: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.1))
                
                // Active level
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.yellow, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(max(level, 0), 1)))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }
}
