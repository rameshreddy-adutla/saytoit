import SwiftUI

/// Dashboard with hero header, stats, and live transcription preview.
struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroHeader
                statsRow
                livePreview
                recentSession
                Spacer()
            }
            .padding(24)
        }
        .background(Color.brandNavy.opacity(0.3))
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.brandNavy, .brandNavyLight, .brandTeal.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)

            VStack(spacing: 16) {
                Button(action: appState.toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(appState.isRecording ? Color.red.opacity(0.2) : Color.brandTeal.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(appState.isRecording ? .red : .brandTeal)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!appState.hasAPIKey)

                Text(appState.isRecording ? "Recording..." : "Tap to Record")
                    .font(.headline)
                    .foregroundStyle(.white)

                if !appState.hasAPIKey {
                    Text("Add an API key in Settings to get started")
                        .font(.caption)
                        .foregroundStyle(.brandCoral)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(title: "Sessions", value: "\(appState.totalSessions)", icon: "waveform", color: .brandTeal)
            statCard(title: "Recording Time", value: formattedTime(appState.totalRecordingTime), icon: "clock", color: .brandCoral)
            statCard(title: "Microphone", value: micStatus, icon: micIcon, color: micColor)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var micStatus: String {
        appState.isRecording ? "Active" : "Ready"
    }

    private var micIcon: String {
        appState.isRecording ? "mic.fill" : "mic"
    }

    private var micColor: Color {
        appState.isRecording ? .green : .secondary
    }

    // MARK: - Live Preview

    @ViewBuilder
    private var livePreview: some View {
        if appState.isRecording || !appState.currentTranscript.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Live Transcription", systemImage: "text.bubble")
                    .font(.headline)

                TranscriptionView()
                    .environmentObject(appState)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Recent Session

    @ViewBuilder
    private var recentSession: some View {
        if let last = appState.history.last {
            VStack(alignment: .leading, spacing: 8) {
                Label("Recent Session", systemImage: "clock")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text(last.text)
                        .lineLimit(3)
                        .font(.body)

                    HStack {
                        Text(last.date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formattedTime(last.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }
}
