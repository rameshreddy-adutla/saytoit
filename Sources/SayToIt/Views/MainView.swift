import SwiftUI

/// Primary full-window view with sidebar navigation.
struct MainView: View {
    @EnvironmentObject var appState: AppState
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
                Button(action: appState.toggleRecording) {
                    HStack(spacing: 6) {
                        Image(systemName: appState.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title3)
                            .foregroundStyle(appState.isRecording ? .red : .brandTeal)
                        Text(appState.isRecording ? "Stop" : "Record")
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!appState.hasAPIKey)
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .history:
            HistoryView()
        case .settings(let tab):
            SettingsView(tab: tab)
        }
    }
}
