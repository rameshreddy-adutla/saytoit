import SwiftUI

/// List of past transcription sessions.
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @State private var selectedItem: HistoryItem?
    @State private var searchText = ""
    @State private var showErrorsOnly = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    TextField("Search history...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                
                // Errors filter
                Toggle(isOn: $showErrorsOnly) {
                    Label("Errors Only", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                }
                .toggleStyle(.button)
                
                Spacer()
                
                // Clear all
                if !filteredItems.isEmpty {
                    Button(role: .destructive) {
                        historyManager.clear()
                        selectedItem = nil
                    } label: {
                        Label("Clear All", systemImage: "trash")
                            .font(.caption)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Content
            Group {
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: showErrorsOnly ? "checkmark.circle" : "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondary)
            Text(showErrorsOnly ? "No errors found" : "No recordings yet")
                .font(.title2)
                .foregroundStyle(Color.secondary)
            Text(showErrorsOnly ? "All sessions completed successfully" : "Your transcription history will appear here.")
                .font(.body)
                .foregroundStyle(Color.tertiary)
        }
    }

    // MARK: - History List

    private var historyList: some View {
        HSplitView {
            List(filteredItems.reversed(), selection: $selectedItem) { item in
                historyRow(item)
                    .tag(item)
            }
            .listStyle(.inset)
            .frame(minWidth: 280, idealWidth: 320)

            detailPanel
                .frame(minWidth: 300)
        }
    }

    private func historyRow(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.displayText)
                    .lineLimit(2)
                    .font(.body)
                
                if !item.errors.isEmpty {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandCoral)
                }
            }

            HStack {
                Text(item.createdAt, style: .date)
                Text("·")
                Text(item.createdAt, style: .time)
                Spacer()
                Text(formattedDuration(item.recordingDuration))
                    .foregroundStyle(Color.secondary)
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Detail Panel

    @ViewBuilder
    private var detailPanel: some View {
        if let item = selectedItem {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.createdAt, style: .date)
                                .font(.title3.weight(.semibold))
                            Text(item.createdAt, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.displayText, forType: .string)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandAccent)
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        metadataRow(label: "Duration", value: formattedDuration(item.recordingDuration))
                        metadataRow(label: "Models", value: item.modelsUsed.joined(separator: ", "))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Transcription sections
                    if let raw = item.rawTranscription {
                        transcriptionSection(title: "Raw Transcription", text: raw, icon: "waveform")
                    }
                    
                    if let processed = item.postProcessedTranscription {
                        transcriptionSection(title: "Processed Text", text: processed, icon: "text.badge.sparkles")
                    }
                    
                    // Errors
                    if !item.errors.isEmpty {
                        errorsSection(item.errors)
                    }
                }
                .padding()
            }
        } else {
            VStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.secondary)
                Text("Select a session to view details")
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
    
    private func transcriptionSection(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Color.brandAccent)
            
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
    
    private func errorsSection(_ errors: [HistoryError]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Errors (\(errors.count))", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.brandCoral)
            
            VStack(spacing: 8) {
                ForEach(errors) { error in
                    errorRow(error)
                }
            }
        }
    }
    
    private func errorRow(_ error: HistoryError) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(error.phase.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.brandCoral)
                Spacer()
                Text(error.occurredAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            
            Text(error.message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(Color.brandCoral.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private var filteredItems: [HistoryItem] {
        historyManager.filtered(searchText: searchText, errorsOnly: showErrorsOnly)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
