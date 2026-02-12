import SwiftUI

/// Main menu bar popover view — quick access panel.
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
                        NSApp.activate(ignoringOtherApps: true)
                        for window in NSApp.windows where window.canBecomeKey {
                            window.makeKeyAndOrderFront(nil)
                            break
                        }
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

                Button("Open Main Window") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("SayToIt") || $0.isKeyWindow || $0.canBecomeKey }) {
                        window.makeKeyAndOrderFront(nil)
                    } else {
                        // No window found — open a new one
                        NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
                    }
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
        .frame(width: 380, height: 320)
    }
}
