import SwiftUI

/// Main menu bar popover view.
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("SayToIt")
                    .font(.headline)
                Spacer()
                Text(appState.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            // Transcription area
            TranscriptionView()
                .environmentObject(appState)

            Divider()

            // Controls
            HStack {
                if !appState.hasAPIKey {
                    Button {
                        openWindow(id: "settings")
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text("Add API Key")
                                .font(.body)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: appState.toggleRecording) {
                        HStack(spacing: 6) {
                            Image(systemName: appState.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundStyle(appState.isRecording ? .red : .accentColor)
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

                Button {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 380, height: 320)
    }
}
