import SwiftUI
import SayToItCore

@main
struct SayToItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
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
        }
        .defaultSize(width: 1080, height: 720)
        .tint(.brandTeal)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isRecording ? "waveform" : "mic.fill")
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
