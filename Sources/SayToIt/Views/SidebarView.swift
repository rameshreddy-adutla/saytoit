import SwiftUI

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case transcription
    case postProcessing
    case apiKeys
    case shortcuts
    case permissions
    case about

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "General"
        case .transcription: return "Transcription"
        case .postProcessing: return "Post-Processing"
        case .apiKeys: return "API Keys"
        case .shortcuts: return "Shortcuts"
        case .permissions: return "Permissions"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .transcription: return "waveform"
        case .postProcessing: return "text.badge.sparkles"
        case .apiKeys: return "key.fill"
        case .shortcuts: return "command"
        case .permissions: return "checkmark.shield"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case dashboard
    case transcription
    case history
    case voiceOutput
    case corrections
    case settings(SettingsTab)

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .transcription: return "Transcription"
        case .history: return "History"
        case .voiceOutput: return "Voice Output"
        case .corrections: return "Corrections"
        case .settings(let tab): return tab.label
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .transcription: return "waveform.circle"
        case .history: return "clock.arrow.circlepath"
        case .voiceOutput: return "speaker.wave.2"
        case .corrections: return "text.badge.checkmark"
        case .settings(let tab): return tab.icon
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return Color.brandAccent
        case .transcription: return Color.brandLagoon
        case .history: return Color.brandAccentWarm
        case .voiceOutput: return Color.purple
        case .corrections: return Color.brandAccentDeep
        case .settings: return Color.secondary
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(selection: $selection) {
            Section("SayToIt") {
                sidebarRow(.dashboard)
                sidebarRow(.transcription)
                sidebarRow(.history)
                sidebarRow(.voiceOutput)
                sidebarRow(.corrections)
            }

            Section("Settings") {
                ForEach(SettingsTab.allCases) { tab in
                    sidebarRow(.settings(tab))
                }
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func sidebarRow(_ item: SidebarItem) -> some View {
        Label {
            Text(item.label)
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
        }
        .tag(item)
    }
}
