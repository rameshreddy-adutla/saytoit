import SwiftUI
import AVFoundation

/// Settings view reorganized into tabs for the main window.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var tab: SettingsTab = .general
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false
    @State private var showLiveTranscript = true
    @State private var postProcessingEnabled = false
    @State private var postProcessingModel = "GPT-4"
    @State private var systemPrompt = "Improve grammar and clarity while preserving meaning."
    @State private var temperature = 0.3
    @State private var micPermissionStatus = "Unknown"
    @State private var accessibilityPermissionStatus = "Unknown"

    var body: some View {
        Form {
            switch tab {
            case .general:
                generalSection
            case .transcription:
                transcriptionSection
            case .postProcessing:
                postProcessingSection
            case .apiKeys:
                apiKeysSection
            case .shortcuts:
                shortcutsSection
            case .permissions:
                permissionsSection
            case .about:
                aboutSection
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            apiKeyInput = appState.getAPIKey()
            checkPermissions()
        }
    }

    // MARK: - General

    @ViewBuilder
    private var generalSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: .constant("System")) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .disabled(true)
            
            Text("Theme customization coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        Section("App Visibility") {
            Picker("Show in", selection: .constant("Dock & Menu Bar")) {
                Text("Dock & Menu Bar").tag("Dock & Menu Bar")
                Text("Menu Bar Only").tag("Menu Bar Only")
            }
            .disabled(true)
            
            Toggle("Run at login", isOn: .constant(false))
                .disabled(true)
            
            Text("Visibility options coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }

        Section("Preferences") {
            Toggle("Auto-copy transcript to clipboard", isOn: $appState.autoCopyEnabled)
            Toggle("Auto-paste to frontmost app", isOn: $appState.autoPasteEnabled)
                .disabled(!appState.autoCopyEnabled)
        }
    }
    
    // MARK: - Transcription
    
    @ViewBuilder
    private var transcriptionSection: some View {
        Section("Model") {
            Picker("Transcription Model", selection: .constant("Deepgram Nova-2")) {
                Text("Deepgram Nova-2").tag("Deepgram Nova-2")
            }
            .disabled(true)
            
            Text("More models coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        Section("Language") {
            Picker("Language", selection: .constant("English")) {
                Text("English").tag("English")
            }
            .disabled(true)
            
            Text("Multi-language support coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        Section("Display") {
            Toggle("Show live transcript in HUD", isOn: $showLiveTranscript)
                .disabled(true)
            
            Text("HUD customization coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Post-Processing
    
    @ViewBuilder
    private var postProcessingSection: some View {
        Section("Post-Processing") {
            Toggle("Enable post-processing", isOn: $postProcessingEnabled)
                .disabled(true)
            
            Text("AI-powered grammar and clarity improvements")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        if postProcessingEnabled {
            Section("Model Configuration") {
                Picker("Model", selection: $postProcessingModel) {
                    Text("GPT-4").tag("GPT-4")
                    Text("GPT-3.5 Turbo").tag("GPT-3.5 Turbo")
                    Text("Claude 3").tag("Claude 3")
                }
                .disabled(true)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 80)
                        .font(.body)
                        .disabled(true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                            .font(.caption)
                        Spacer()
                    }
                    Slider(value: $temperature, in: 0...1, step: 0.1)
                        .disabled(true)
                }
            }
        }
        
        Text("Post-processing features coming soon")
            .font(.caption)
            .foregroundStyle(Color.secondary)
    }
    
    // MARK: - Shortcuts
    
    @ViewBuilder
    private var shortcutsSection: some View {
        Section("Hotkeys") {
            HStack {
                Text("Toggle recording:")
                Spacer()
                Text("⌘⇧S")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(6)
            }
            Text("Hotkey customization coming soon")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Permissions
    
    @ViewBuilder
    private var permissionsSection: some View {
        Section("Microphone Access") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Microphone")
                        .font(.headline)
                    Text("Required for voice transcription")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                statusBadge(micPermissionStatus)
                
                if micPermissionStatus != "Granted" {
                    Button("Grant Access") {
                        AVCaptureDevice.requestAccess(for: .audio) { _ in
                            checkPermissions()
                        }
                    }
                }
            }
        }
        
        Section("Accessibility Access") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility")
                        .font(.headline)
                    Text("Required for auto-paste functionality")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                statusBadge(accessibilityPermissionStatus)
                
                if accessibilityPermissionStatus != "Granted" {
                    Button("Open Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        let color: Color = status == "Granted" ? Color.green : (status == "Denied" ? Color.red : Color.secondary)
        
        Text(status)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(6)
    }
    
    private func checkPermissions() {
        // Check microphone
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            micPermissionStatus = "Granted"
        case .denied, .restricted:
            micPermissionStatus = "Denied"
        case .notDetermined:
            micPermissionStatus = "Not Requested"
        @unknown default:
            micPermissionStatus = "Unknown"
        }
        
        // Check accessibility (simplified check)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        accessibilityPermissionStatus = trusted ? "Granted" : "Not Granted"
    }

    // MARK: - API Keys

    @ViewBuilder
    private var apiKeysSection: some View {
        Section("Deepgram (Active)") {
            HStack {
                if showAPIKey {
                    TextField("Paste your API key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Paste your API key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                }
                Button {
                    showAPIKey.toggle()
                } label: {
                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
            }

            HStack {
                Button("Save") {
                    guard !apiKeyInput.isEmpty else { return }
                    appState.saveAPIKey(apiKeyInput)
                }
                .disabled(apiKeyInput.isEmpty)

                if appState.hasAPIKey {
                    Button("Remove", role: .destructive) {
                        appState.deleteAPIKey()
                        apiKeyInput = ""
                    }
                }

                Spacer()

                Link("Get API key →", destination: URL(string: "https://console.deepgram.com/signup")!)
                    .font(.caption)
            }

            if appState.hasAPIKey {
                Label("API key stored securely in Keychain", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color.green)
            }
        }
        
        Section("OpenAI (Coming Soon)") {
            SecureField("OpenAI API Key", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
            
            Text("For post-processing features")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        Section("OpenRouter (Coming Soon)") {
            SecureField("OpenRouter API Key", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
            
            Text("Alternative model provider")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - About

    @ViewBuilder
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("SayToIt")
                    .font(.headline)
                Spacer()
                Text("v0.1.0")
                    .foregroundStyle(Color.secondary)
            }
            
            Text("Voice transcription powered by Deepgram")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        
        Section("Links") {
            Link("GitHub Repository", destination: URL(string: "https://github.com/rameshreddy-adutla/saytoit")!)
            Link("saytoit.is-a.dev", destination: URL(string: "https://saytoit.is-a.dev")!)
            Link("Report an Issue", destination: URL(string: "https://github.com/rameshreddy-adutla/saytoit/issues")!)
        }
        
        Section("Credits") {
            Text("Built with SwiftUI and Deepgram API")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
}
