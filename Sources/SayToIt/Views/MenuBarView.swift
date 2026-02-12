import SwiftUI

/// Main menu bar popover view — quick access panel.
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            // Header with mode badge
            HStack(spacing: 12) {
                Text("SayToIt")
                    .font(.headline)
                
                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 16) {
                quickStat(icon: "waveform", value: "\(historyManager.totalSessions)")
                quickStat(icon: "clock", value: formattedTime(historyManager.totalRecordingTime))
                quickStat(icon: "chart.line.uptrend.xyaxis", value: formattedTime(historyManager.averageSessionLength))
            }

            Divider()

            // Transcription area
            TranscriptionView()
                .environmentObject(appState)

            Divider()

            // Controls
            HStack(spacing: 8) {
                if !appState.hasAPIKey {
                    Button {
                        openMainWindow()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.body)
                                .foregroundStyle(Color.orange)
                            Text("Add API Key")
                                .font(.body)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: appState.toggleRecordingFromUI) {
                        HStack(spacing: 6) {
                            Image(systemName: appState.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.body)
                                .foregroundStyle(appState.isRecording ? Color.red : Color.brandAccent)
                            Text(appState.isRecording ? "Stop" : "Record")
                                .font(.body)
                        }
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                }

                Spacer()

                if !appState.currentTranscript.isEmpty && !appState.isRecording {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appState.currentTranscript, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button("Open") {
                    openMainWindow()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 380, height: 340)
    }
    
    private func quickStat(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.brandAccent)
            Text(value)
                .font(.caption2.weight(.medium))
        }
    }
    
    private var statusText: String {
        switch appState.state {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .processing: return "Processing"
        case .delivering: return "Delivering"
        case .completed: return "Done"
        case .failed: return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch appState.state {
        case .idle: return Color.secondary
        case .recording: return Color.red
        case .processing: return Color.brandAccent
        case .delivering: return Color.green
        case .completed: return Color.green
        case .failed: return Color.brandCoral
        }
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("SayToIt") || $0.isKeyWindow || $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
        }
    }
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

