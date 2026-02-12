import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Deepgram streaming WebSocket client for real-time transcription.
public final class DeepgramClient: NSObject, TranscriptionServiceProtocol, @unchecked Sendable {
    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let apiKey: String
        public let model: String
        public let language: String
        public let sampleRate: Int
        public let channels: Int
        public let encoding: String
        public let punctuate: Bool
        public let interimResults: Bool
        public let endpointing: Int

        public init(
            apiKey: String,
            model: String = "nova-2",
            language: String = "en",
            sampleRate: Int = 16000,
            channels: Int = 1,
            encoding: String = "linear16",
            punctuate: Bool = true,
            interimResults: Bool = true,
            endpointing: Int = 300
        ) {
            self.apiKey = apiKey
            self.model = model
            self.language = language
            self.sampleRate = sampleRate
            self.channels = channels
            self.encoding = encoding
            self.punctuate = punctuate
            self.interimResults = interimResults
            self.endpointing = endpointing
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let resultsContinuation: AsyncStream<TranscriptionResult>.Continuation
    public let results: AsyncStream<TranscriptionResult>
    private var isConnected = false

    // MARK: - Init

    public init(configuration: Configuration) {
        self.configuration = configuration
        var continuation: AsyncStream<TranscriptionResult>.Continuation!
        self.results = AsyncStream { continuation = $0 }
        self.resultsContinuation = continuation
        super.init()
    }

    deinit {
        resultsContinuation.finish()
    }

    // MARK: - TranscriptionServiceProtocol

    public func startTranscription() async throws {
        guard !configuration.apiKey.isEmpty else {
            throw TranscriptionError.noAPIKey
        }

        let url = buildWebSocketURL()
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.urlSession = session

        var request = URLRequest(url: url)
        request.setValue("Token \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()
        isConnected = true
        receiveMessages()
    }

    public func stopTranscription() async {
        guard isConnected else { return }
        isConnected = false

        // Send close message to Deepgram
        let closeMessage = #"{"type": "CloseStream"}"#
        let message = URLSessionWebSocketTask.Message.string(closeMessage)
        try? await webSocketTask?.send(message)

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }

    // MARK: - Audio Data

    /// Send raw audio data (Linear16 PCM) to Deepgram.
    public func sendAudioData(_ data: Data) {
        guard isConnected, let task = webSocketTask else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        task.send(message) { error in
            if let error {
                self.resultsContinuation.yield(
                    TranscriptionResult(text: "", isFinal: true, confidence: nil)
                )
                print("[SayToIt] WebSocket send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func buildWebSocketURL() -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "api.deepgram.com"
        components.path = "/v1/listen"
        components.queryItems = [
            URLQueryItem(name: "model", value: configuration.model),
            URLQueryItem(name: "language", value: configuration.language),
            URLQueryItem(name: "sample_rate", value: "\(configuration.sampleRate)"),
            URLQueryItem(name: "channels", value: "\(configuration.channels)"),
            URLQueryItem(name: "encoding", value: configuration.encoding),
            URLQueryItem(name: "punctuate", value: "\(configuration.punctuate)"),
            URLQueryItem(name: "interim_results", value: "\(configuration.interimResults)"),
            URLQueryItem(name: "endpointing", value: "\(configuration.endpointing)"),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "filler_words", value: "false"),
            URLQueryItem(name: "diarize", value: "false"),
        ]
        return components.url!
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self, self.isConnected else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleTextMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessages()

            case .failure(let error):
                print("[SayToIt] WebSocket receive error: \(error.localizedDescription)")
            }
        }
    }

    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // Parse Deepgram streaming response
        guard let channel = (json["channel"] as? [String: Any]),
              let alternatives = channel["alternatives"] as? [[String: Any]],
              let first = alternatives.first,
              let transcript = first["transcript"] as? String,
              !transcript.isEmpty else {
            return
        }

        let isFinal = json["is_final"] as? Bool ?? false
        let confidence = first["confidence"] as? Double
        let duration = json["duration"] as? Double

        let result = TranscriptionResult(
            text: transcript,
            isFinal: isFinal,
            confidence: confidence,
            duration: duration
        )
        resultsContinuation.yield(result)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension DeepgramClient: URLSessionWebSocketDelegate {
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("[SayToIt] WebSocket connected")
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        isConnected = false
        print("[SayToIt] WebSocket closed: \(closeCode)")
    }
}
