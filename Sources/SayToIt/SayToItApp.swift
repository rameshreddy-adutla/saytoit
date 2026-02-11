import SwiftUI
import SayToItCore

@main
struct SayToItApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Label {
                Text("SayToIt")
            } icon: {
                Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
