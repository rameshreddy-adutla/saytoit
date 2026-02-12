import SwiftUI
import AVFoundation

/// Multi-step onboarding wizard.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var apiKeyInput = ""
    @State private var micPermissionGranted = false

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: permissionsStep
                case 2: apiKeyStep
                case 3: doneStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: 500)

            Spacer()

            // Progress dots and navigation
            VStack(spacing: 20) {
                progressDots

                HStack {
                    if currentStep > 0 && currentStep < totalSteps - 1 {
                        Button("Back") { withAnimation { currentStep -= 1 } }
                            .buttonStyle(.plain)
                    }

                    Spacer()

                    if currentStep < totalSteps - 1 {
                        Button(currentStep == 0 ? "Get Started" : "Next") {
                            withAnimation { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brandTeal)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.brandNavy)
        .preferredColorScheme(.dark)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.brandTeal)

            Text("Welcome to SayToIt")
                .font(.largeTitle.bold())

            Text("Voice transcription powered by Deepgram.\nSpeak naturally, get text instantly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.brandCoral)

            Text("Microphone Access")
                .font(.title.bold())

            Text("SayToIt needs microphone access to transcribe your speech.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Grant Microphone Access") {
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    Task { @MainActor in
                        micPermissionGranted = granted
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandTeal)

            if micPermissionGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 56))
                .foregroundStyle(.brandCoral)

            Text("Deepgram API Key")
                .font(.title.bold())

            Text("Enter your Deepgram API key to enable transcription.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            SecureField("Paste your API key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)

            HStack(spacing: 16) {
                Button("Save Key") {
                    guard !apiKeyInput.isEmpty else { return }
                    appState.saveAPIKey(apiKeyInput)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandTeal)
                .disabled(apiKeyInput.isEmpty)

                Link("Get a free API key →", destination: URL(string: "https://console.deepgram.com/signup")!)
                    .font(.callout)
            }

            if appState.hasAPIKey {
                Label("API key saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle.bold())

            Text("Press ⌘⇧S anytime to start recording.")
                .foregroundStyle(.secondary)

            Button("Open SayToIt") {
                hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandTeal)
            .controlSize(.large)
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.brandTeal : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
