import SwiftUI
import AVFoundation

/// Multi-step onboarding wizard.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var apiKeyInput = ""
    @State private var micPermissionGranted = false
    @State private var accessibilityPermissionGranted = false

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
                        .tint(Color.brandAccent)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 1.0)),
                    Color(nsColor: NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.brandAccent)

            Text("Welcome to SayToIt")
                .font(.largeTitle.bold())

            Text("Voice transcription powered by Deepgram.\nSpeak naturally, get text instantly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 12)
            
            // Feature rows
            VStack(spacing: 16) {
                featureRow(
                    icon: "mic.fill",
                    title: "Real-time Transcription",
                    description: "Instant speech-to-text conversion"
                )
                featureRow(
                    icon: "keyboard.fill",
                    title: "Auto-Paste",
                    description: "Seamlessly paste into any app"
                )
                featureRow(
                    icon: "key.fill",
                    title: "Secure Storage",
                    description: "API keys stored in Keychain"
                )
            }
            .padding(.top, 8)
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandAccent)

            Text("Grant Permissions")
                .font(.title.bold())

            Text("SayToIt needs permissions to function properly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 8)
            
            // Permissions
            VStack(spacing: 16) {
                permissionCard(
                    icon: "mic.fill",
                    title: "Microphone Access",
                    description: "Required for voice input",
                    granted: micPermissionGranted
                ) {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        Task { @MainActor in
                            micPermissionGranted = granted
                        }
                    }
                }
                
                permissionCard(
                    icon: "hand.raised.fill",
                    title: "Accessibility Access",
                    description: "Required for auto-paste",
                    granted: accessibilityPermissionGranted
                ) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    // Check status after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        checkAccessibilityPermission()
                    }
                }
            }
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.title3)
            } else {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func checkPermissions() {
        micPermissionGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        checkAccessibilityPermission()
    }
    
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermissionGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandAccent)

            Text("API Key Setup")
                .font(.title.bold())

            Text("Enter your Deepgram API key to enable transcription.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 8)
            
            // Provider selector (only Deepgram active)
            HStack(spacing: 12) {
                providerButton(name: "Deepgram", icon: "waveform", isActive: true)
                providerButton(name: "OpenAI", icon: "sparkles", isActive: false)
                providerButton(name: "OpenRouter", icon: "arrow.triangle.swap", isActive: false)
            }
            .padding(.bottom, 8)

            SecureField("Paste your API key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Save Key") {
                    guard !apiKeyInput.isEmpty else { return }
                    appState.saveAPIKey(apiKeyInput)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandAccent)
                .disabled(apiKeyInput.isEmpty)

                Link("Get a free API key →", destination: URL(string: "https://console.deepgram.com/signup")!)
                    .font(.callout)
            }

            if appState.hasAPIKey {
                Label("API key saved successfully", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
            }
        }
    }
    
    private func providerButton(name: String, icon: String, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isActive ? Color.brandAccent : Color.secondary)
            Text(name)
                .font(.caption)
                .foregroundStyle(isActive ? .primary : Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isActive ? Color.brandAccent.opacity(0.2) : Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.brandAccent : Color.clear, lineWidth: 2)
        )
        .opacity(isActive ? 1.0 : 0.5)
    }

    private var doneStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.green)

            Text("You're All Set!")
                .font(.largeTitle.bold())

            Text("Press ⌘⇧S anytime to start recording.")
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 8)
            
            // Usage tips
            VStack(spacing: 12) {
                tipRow(icon: "command", text: "Use ⌘⇧S to toggle recording")
                tipRow(icon: "waveform", text: "Speak naturally for best results")
                tipRow(icon: "doc.on.clipboard", text: "Text is auto-copied to clipboard")
            }
            .padding(.top, 8)

            Button("Open SayToIt") {
                hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandAccent)
            .controlSize(.large)
            .padding(.top, 12)
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 24)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.brandAccent : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
