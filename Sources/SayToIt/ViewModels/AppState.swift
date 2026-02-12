import SwiftUI
import SayToItCore
import Combine

/// Central app state managing recording, transcription, and services.
@MainActor
public final class AppState: ObservableObject {
    // MARK: - Published State

    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var interimText = ""
    @Published var statusMessage = "Ready — Press ⌘⇧S to start"
    @Published var hasAPIKey = false
    @Published var autoCopyEnabled = true
    @Published var autoPasteEnabled = false

    // MARK: - Services

    private let audioCapture: AudioCaptureService
    private let secureStorage: SecureStorage
    private let clipboard: ClipboardService
    private let hotkeyManager: HotkeyManager
    private var deepgramClient: DeepgramClient?
    private var transcriptionTask: Task<Void, Never>?
    private var audioStreamTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        self.audioCapture = AudioCaptureService()
        self.secureStorage = SecureStorage()
        self.clipboard = ClipboardService()
        self.hotkeyManager = HotkeyManager()

        checkAPIKey()
        setupHotkey()
    }

    // MARK: - Recording Control

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        guard hasAPIKey else {
            statusMessage = "⚠️ No API key. Open Settings to add one."
            return
        }

        guard let apiKey = try? secureStorage.retrieve(key: SecureStorage.deepgramAPIKeyName) else {
            statusMessage = "⚠️ Failed to read API key"
            return
        }

        isRecording = true
        currentTranscript = ""
        interimText = ""
        statusMessage = "🎙️ Recording..."

        let config = DeepgramClient.Configuration(apiKey: apiKey)
        let client = DeepgramClient(configuration: config)
        self.deepgramClient = client

        // Start transcription and audio capture
        transcriptionTask = Task {
            do {
                try await client.startTranscription()

                // Listen for results
                for await result in client.results {
                    if result.isFinal {
                        if !result.text.isEmpty {
                            if !currentTranscript.isEmpty {
                                currentTranscript += " "
                            }
                            currentTranscript += result.text
                        }
                        interimText = ""
                    } else {
                        interimText = result.text
                    }
                }
            } catch {
                statusMessage = "❌ \(error.localizedDescription)"
                isRecording = false
            }
        }

        audioStreamTask = Task {
            do {
                let audioStream = try audioCapture.startCapture()
                for await data in audioStream {
                    client.sendAudioData(data)
                }
            } catch {
                statusMessage = "❌ Audio: \(error.localizedDescription)"
                isRecording = false
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        audioCapture.stopCapture()

        Task {
            await deepgramClient?.stopTranscription()
            deepgramClient = nil
        }

        transcriptionTask?.cancel()
        audioStreamTask?.cancel()
        transcriptionTask = nil
        audioStreamTask = nil

        // Copy final transcript
        let finalText = buildFinalTranscript()
        if !finalText.isEmpty && autoCopyEnabled {
            clipboard.copyToClipboard(finalText)
            statusMessage = "✅ Copied to clipboard"

            if autoPasteEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                    clipboard.pasteToFrontmostApp()
                }
            }
        } else if finalText.isEmpty {
            statusMessage = "Ready — Press ⌘⇧S to start"
        }
    }

    // MARK: - API Key Management

    func saveAPIKey(_ key: String) {
        do {
            try secureStorage.store(key: SecureStorage.deepgramAPIKeyName, value: key)
            hasAPIKey = true
            statusMessage = "✅ API key saved"
        } catch {
            statusMessage = "❌ Failed to save API key: \(error.localizedDescription)"
        }
    }

    func deleteAPIKey() {
        do {
            try secureStorage.delete(key: SecureStorage.deepgramAPIKeyName)
            hasAPIKey = false
            statusMessage = "API key removed"
        } catch {
            statusMessage = "❌ Failed to delete API key: \(error.localizedDescription)"
        }
    }

    func getAPIKey() -> String {
        (try? secureStorage.retrieve(key: SecureStorage.deepgramAPIKeyName)) ?? ""
    }

    // MARK: - Private

    private func checkAPIKey() {
        hasAPIKey = (try? secureStorage.retrieve(key: SecureStorage.deepgramAPIKeyName)) != nil
    }

    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed { [weak self] in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.toggleRecording()
            }
        }
        do {
            try hotkeyManager.start()
        } catch {
            print("[SayToIt] Hotkey registration failed: \(error.localizedDescription)")
        }
    }

    private func buildFinalTranscript() -> String {
        var text = currentTranscript
        if !interimText.isEmpty {
            if !text.isEmpty { text += " " }
            text += interimText
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
