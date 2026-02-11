import AVFoundation
import Foundation

/// Protocol for audio capture services.
public protocol AudioCaptureServiceProtocol: AnyObject, Sendable {
    /// Start capturing audio. Returns a stream of raw PCM audio data buffers.
    func startCapture() throws -> AsyncStream<Data>
    /// Stop capturing audio.
    func stopCapture()
    /// Whether the capture is currently active.
    var isCapturing: Bool { get }
}

/// Captures microphone audio via AVAudioEngine and converts to Linear16 PCM.
public final class AudioCaptureService: AudioCaptureServiceProtocol, @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var continuation: AsyncStream<Data>.Continuation?
    private let targetSampleRate: Double
    private let targetChannels: AVAudioChannelCount

    public private(set) var isCapturing = false

    public init(sampleRate: Double = 16000, channels: AVAudioChannelCount = 1) {
        self.targetSampleRate = sampleRate
        self.targetChannels = channels
    }

    public func startCapture() throws -> AsyncStream<Data> {
        guard !isCapturing else {
            throw TranscriptionError.audioError("Already capturing audio")
        }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw TranscriptionError.audioError("No audio input device available")
        }

        // Target format: Linear16 PCM, mono, 16kHz
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: true
        ) else {
            throw TranscriptionError.audioError("Failed to create target audio format")
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw TranscriptionError.audioError("Failed to create audio converter")
        }

        let stream = AsyncStream<Data> { continuation in
            self.continuation = continuation

            continuation.onTermination = { @Sendable _ in
                self.stopCapture()
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, self.isCapturing else { return }
            if let data = self.convertBuffer(buffer, using: converter, targetFormat: targetFormat) {
                self.continuation?.yield(data)
            }
        }

        try engine.start()
        isCapturing = true

        return stream
    }

    public func stopCapture() {
        guard isCapturing else { return }
        isCapturing = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Private

    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) -> Data? {
        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate
        )
        guard frameCapacity > 0 else { return nil }

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: frameCapacity
        ) else { return nil }

        var error: NSError?
        var hasData = false

        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            if hasData {
                outStatus.pointee = .noDataNow
                return nil
            }
            hasData = true
            outStatus.pointee = .haveData
            return buffer
        }

        if let error {
            print("[SayToIt] Audio conversion error: \(error.localizedDescription)")
            return nil
        }

        guard convertedBuffer.frameLength > 0 else { return nil }

        let byteCount = Int(convertedBuffer.frameLength) * Int(targetFormat.streamDescription.pointee.mBytesPerFrame)
        guard let int16Data = convertedBuffer.int16ChannelData else { return nil }

        return Data(bytes: int16Data[0], count: byteCount)
    }
}
