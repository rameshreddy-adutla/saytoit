import SwiftUI
import SayToItCore
import Combine

/// Central app state managing recording, transcription, and services.
@MainActor
public final class AppState: ObservableObject {
    // MARK: - Session State
    
    enum SessionState: Equatable {
        case idle
        case recording
        case processing
        case delivering
        case completed(HistoryItem)
        case failed(String)
    }
    
    // MARK: - Published State

    @Published private(set) var state: SessionState = .idle
    @Published private(set) var livePreview: String = ""
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var currentTranscript = ""
    @Published private(set) var interimText = ""
    @Published var statusMessage = "Ready — Press ⌘⇧S to start"
    @Published var hasAPIKey = false
    @Published var autoCopyEnabled = true
    @Published var autoPasteEnabled = true

    // MARK: - Computed Properties
    
    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }
    
    var recordingStartTime: Date?

    // MARK: - Services

    private let audioCapture: AudioCaptureService
    private let secureStorage: SecureStorage
    private let clipboard: ClipboardService
    private let hotkeyManager: HotkeyManager
    private var deepgramClient: DeepgramClient?
    private var transcriptionTask: Task<Void, Never>?
    private var audioStreamTask: Task<Void, Never>?
    private let recordingHUD = RecordingHUD()
    private var hudTimerTask: Task<Void, Never>?
    private var sessionErrors: [HistoryError] = []

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

    func toggleRecordingFromUI() {
        toggleRecording()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard case .idle = state else { return }
        guard hasAPIKey else {
            statusMessage = "⚠️ No API key. Open Settings to add one."
            state = .failed("No API key configured")
            return
        }

        guard let apiKey = try? secureStorage.retrieve(key: SecureStorage.deepgramAPIKeyName) else {
            statusMessage = "⚠️ Failed to read API key"
            state = .failed("Failed to read API key")
            return
        }

        state = .recording
        sessionErrors = []
        currentTranscript = ""
        interimText = ""
        livePreview = ""
        statusMessage = "🎙️ Recording..."
        recordingStartTime = Date()

        // Show floating HUD
        recordingHUD.show(appState: self, phase: .recording)
        // Timer to keep HUD elapsed time updating
        hudTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                self?.objectWillChange.send()
            }
        }

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
                    updateLivePreview()
                }
            } catch {
                statusMessage = "❌ \(error.localizedDescription)"
                sessionErrors.append(HistoryError(phase: "transcription", message: error.localizedDescription))
                state = .failed(error.localizedDescription)
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
                sessionErrors.append(HistoryError(phase: "audio_capture", message: error.localizedDescription))
                state = .failed(error.localizedDescription)
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        state = .processing
        
        recordingHUD.updatePhase(.processing)
        statusMessage = "Processing..."

        // Calculate session duration
        let duration: TimeInterval
        if let start = recordingStartTime {
            duration = Date().timeIntervalSince(start)
        } else {
            duration = 0
        }
        recordingStartTime = nil

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
        
        if !finalText.isEmpty {
            state = .delivering
            recordingHUD.updatePhase(.delivering)
            statusMessage = "Delivering..."
            
            if autoCopyEnabled {
                clipboard.copyToClipboard(finalText)
                
                if autoPasteEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.clipboard.pasteToFrontmostApp()
                    }
                }
            }
            
            // Create history item
            let item = HistoryItem(
                rawTranscription: finalText,
                recordingDuration: duration,
                modelsUsed: ["deepgram/nova-2"],
                errors: sessionErrors
            )
            
            state = .completed(item)
            recordingHUD.updatePhase(.success)
            statusMessage = "✅ Completed"
            
            // Auto-hide HUD after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.recordingHUD.dismiss()
                self?.hudTimerTask?.cancel()
                self?.hudTimerTask = nil
                if case .completed = self?.state {
                    self?.state = .idle
                }
            }
        } else {
            state = .failed("No transcription captured")
            recordingHUD.updatePhase(.failure("No audio detected"))
            statusMessage = "❌ No transcription"
            
            // Auto-hide HUD after failure
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.recordingHUD.dismiss()
                self?.hudTimerTask?.cancel()
                self?.hudTimerTask = nil
                self?.state = .idle
            }
        }
        
        sessionErrors = []
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
    
    private func updateLivePreview() {
        var text = currentTranscript
        if !interimText.isEmpty {
            if !text.isEmpty { text += " " }
            text += interimText
        }
        livePreview = text
    }
}
