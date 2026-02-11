import SwiftUI

/// Live transcription display with partial results.
struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if appState.currentTranscript.isEmpty && appState.interimText.isEmpty && !appState.isRecording {
                        Text("Press ⌘⇧S or tap Record to start speaking")
                            .foregroundStyle(.tertiary)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        // Final transcript
                        if !appState.currentTranscript.isEmpty {
                            Text(appState.currentTranscript)
                                .font(.body)
                                .textSelection(.enabled)
                        }

                        // Interim (partial) results — shown with reduced opacity
                        if !appState.interimText.isEmpty {
                            Text(appState.interimText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                                .id("interim")
                        }

                        // Recording indicator
                        if appState.isRecording && appState.currentTranscript.isEmpty && appState.interimText.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Listening...")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            .onChange(of: appState.interimText) {
                withAnimation {
                    proxy.scrollTo("interim", anchor: .bottom)
                }
            }
        }
    }
}
