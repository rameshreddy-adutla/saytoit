import Foundation

/// Result from a transcription service.
public struct TranscriptionResult: Sendable, Equatable {
    /// The transcribed text.
    public let text: String
    /// Whether this is a final (committed) result or an interim (partial) one.
    public let isFinal: Bool
    /// Confidence score (0.0–1.0), if available.
    public let confidence: Double?
    /// Duration of the audio segment in seconds, if available.
    public let duration: TimeInterval?

    public init(text: String, isFinal: Bool, confidence: Double? = nil, duration: TimeInterval? = nil) {
        self.text = text
        self.isFinal = isFinal
        self.confidence = confidence
        self.duration = duration
    }
}

/// Errors that can occur during transcription.
public enum TranscriptionError: Error, LocalizedError, Sendable {
    case noAPIKey
    case connectionFailed(String)
    case invalidResponse(String)
    case audioError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your Deepgram API key in Settings."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .invalidResponse(let reason):
            return "Invalid response: \(reason)"
        case .audioError(let reason):
            return "Audio error: \(reason)"
        case .serverError(let reason):
            return "Server error: \(reason)"
        }
    }
}
