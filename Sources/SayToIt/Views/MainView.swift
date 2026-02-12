import SwiftUI

/// Primary full-window view with sidebar navigation.
struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @State private var selection: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // Mode capsule
                    modeCapsule
                    
                    // Record button
                    Button(action: appState.toggleRecordingFromUI) {
                        HStack(spacing: 6) {
                            Image(systemName: appState.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title3)
                                .foregroundStyle(appState.isRecording ? Color.red : Color.brandAccent)
                            Text(appState.isRecording ? "Stop" : "Record")
                        }
                    }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(!appState.hasAPIKey)
                }
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var modeCapsule: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.brandSurface.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        switch appState.state {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .processing: return "Processing"
        case .delivering: return "Delivering"
        case .completed: return "Completed"
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

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .transcription:
            TranscriptionView()
        case .history:
            HistoryView()
        case .voiceOutput:
            PlaceholderView(title: "Voice Output", icon: "speaker.wave.2")
        case .corrections:
            PlaceholderView(title: "Corrections", icon: "text.badge.checkmark")
        case .settings(let tab):
            SettingsView(tab: tab)
        }
    }
}

/// Placeholder view for features not yet implemented
struct PlaceholderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.secondary)
            Text(title)
                .font(.title)
                .foregroundStyle(Color.secondary)
            Text("Coming soon")
                .font(.body)
                .foregroundStyle(Color.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
