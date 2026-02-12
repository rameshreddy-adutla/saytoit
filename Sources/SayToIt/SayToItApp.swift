import SwiftUI
import SayToItCore

@main
struct SayToItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var historyManager = HistoryManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(appState)
            .environmentObject(historyManager)
        }
        .defaultSize(width: 1080, height: 720)
        .onChange(of: appState.state) { _, newValue in
            // Save completed sessions to history
            if case .completed(let item) = newValue {
                historyManager.append(item)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(historyManager)
        } label: {
            Image(systemName: appState.isRecording ? "waveform" : "mic.fill")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Makes the app appear in the Dock as a regular app.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
