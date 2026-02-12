import Foundation
import SwiftUI

/// Manages persistent history storage for transcription sessions.
@MainActor
public final class HistoryManager: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []
    
    private let storageURL: URL
    
    // MARK: - Statistics
    
    var totalSessions: Int {
        items.count
    }
    
    var totalRecordingTime: TimeInterval {
        items.reduce(0) { $0 + $1.recordingDuration }
    }
    
    var averageSessionLength: TimeInterval {
        guard !items.isEmpty else { return 0 }
        return totalRecordingTime / Double(items.count)
    }
    
    // MARK: - Init
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SayToIt", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        self.storageURL = appDir.appendingPathComponent("history.json")
        loadFromDisk()
    }
    
    // MARK: - Persistence
    
    func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([HistoryItem].self, from: data)
            self.items = decoded.sorted { $0.createdAt < $1.createdAt }
        } catch {
            print("[HistoryManager] Failed to load history: \(error)")
        }
    }
    
    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("[HistoryManager] Failed to save history: \(error)")
        }
    }
    
    // MARK: - Mutations
    
    func append(_ item: HistoryItem) {
        items.append(item)
        saveToDisk()
    }
    
    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        saveToDisk()
    }
    
    func clear() {
        items.removeAll()
        saveToDisk()
    }
    
    // MARK: - Filtering
    
    func filtered(searchText: String, errorsOnly: Bool) -> [HistoryItem] {
        var result = items
        
        if errorsOnly {
            result = result.filter { !$0.errors.isEmpty }
        }
        
        if !searchText.isEmpty {
            result = result.filter { item in
                item.displayText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
}
