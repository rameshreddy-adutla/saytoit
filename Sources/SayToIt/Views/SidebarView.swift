import SwiftUI

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case apiKeys
    case about

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: "General"
        case .apiKeys: "API Keys"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .apiKeys: "key.fill"
        case .about: "info.circle"
        }
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case dashboard
    case history
    case settings(SettingsTab)

    var label: String {
        switch self {
        case .dashboard: "Dashboard"
        case .history: "History"
        case .settings(let tab): tab.label
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .history: "clock.arrow.circlepath"
        case .settings: "gear"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: .brandTeal
        case .history: .brandCoral
        case .settings: .secondary
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(selection: $selection) {
            Section("Main") {
                sidebarRow(.dashboard)
                sidebarRow(.history)
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
