import SwiftUI

/// Settings view reorganized into tabs for the main window.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var tab: SettingsTab = .general
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false

    var body: some View {
        Form {
            switch tab {
            case .general:
                generalSection
            case .apiKeys:
                apiKeysSection
            case .about:
                aboutSection
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            apiKeyInput = appState.getAPIKey()
        }
    }

    // MARK: - General

    @ViewBuilder
    private var generalSection: some View {
        Section("Preferences") {
            Toggle("Auto-copy transcript to clipboard", isOn: $appState.autoCopyEnabled)
            Toggle("Auto-paste to frontmost app", isOn: $appState.autoPasteEnabled)
                .disabled(!appState.autoCopyEnabled)
        }

        Section("Hotkey") {
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
            Text("Hotkey customisation coming in a future update")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - API Keys

    @ViewBuilder
    private var apiKeysSection: some View {
        Section("Deepgram API Key") {
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

                Link("Get a free API key →", destination: URL(string: "https://console.deepgram.com/signup")!)
                    .font(.caption)
            }

            if appState.hasAPIKey {
                Label("API key stored securely in Keychain", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
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
                    .foregroundStyle(.secondary)
            }
            Link("GitHub Repository", destination: URL(string: "https://github.com/rameshreddy-adutla/saytoit")!)
            Link("saytoit.is-a.dev", destination: URL(string: "https://saytoit.is-a.dev")!)
        }
    }
}
