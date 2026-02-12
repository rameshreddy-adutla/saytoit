import SwiftUI

/// List of past transcription sessions.
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: HistoryItem?

    var body: some View {
        Group {
            if appState.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No recordings yet")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Your transcription history will appear here.")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - History List

    private var historyList: some View {
        HSplitView {
            List(appState.history.reversed(), selection: $selectedItem) { item in
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
        VStack(alignment: .leading, spacing: 4) {
            Text(item.text)
                .lineLimit(2)
                .font(.body)

            HStack {
                Text(item.date, style: .date)
                Text("·")
                Text(item.date, style: .time)
                Spacer()
                Text(formattedDuration(item.duration))
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Detail Panel

    @ViewBuilder
    private var detailPanel: some View {
        if let item = selectedItem {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.date, style: .date)
                            .font(.headline)
                        Text("Duration: \(formattedDuration(item.duration))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.text, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandTeal)
                }

                ScrollView {
                    Text(item.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        } else {
            VStack {
                Text("Select a session to view details")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Helpers

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension HistoryItem: Hashable {
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
