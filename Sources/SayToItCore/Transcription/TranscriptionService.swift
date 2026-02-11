import Foundation

/// Protocol for transcription services, enabling testability and future backends.
public protocol TranscriptionServiceProtocol: AnyObject, Sendable {
    /// Start a transcription session.
    func startTranscription() async throws
    /// Stop the current transcription session.
    func stopTranscription() async
    /// Stream of transcription results. Yields results as they arrive.
    var results: AsyncStream<TranscriptionResult> { get }
}
