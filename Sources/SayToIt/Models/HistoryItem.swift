import Foundation

struct HistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let rawTranscription: String?
    let postProcessedTranscription: String?
    let recordingDuration: TimeInterval
    let modelsUsed: [String]
    let errors: [HistoryError]
    
    // Convenience
    var displayText: String {
        postProcessedTranscription ?? rawTranscription ?? ""
    }
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawTranscription: String?,
        postProcessedTranscription: String? = nil,
        recordingDuration: TimeInterval,
        modelsUsed: [String] = ["deepgram/nova-2"],
        errors: [HistoryError] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawTranscription = rawTranscription
        self.postProcessedTranscription = postProcessedTranscription
        self.recordingDuration = recordingDuration
        self.modelsUsed = modelsUsed
        self.errors = errors
    }
}

struct HistoryError: Codable, Identifiable, Hashable {
    let id: UUID
    let phase: String
    let message: String
    let occurredAt: Date
    
    init(id: UUID = UUID(), phase: String, message: String, occurredAt: Date = Date()) {
        self.id = id
        self.phase = phase
        self.message = message
        self.occurredAt = occurredAt
    }
}
