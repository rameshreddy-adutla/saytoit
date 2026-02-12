import SwiftUI
import AVFoundation

/// Dashboard with hero header, stats, and live transcription preview.
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroHeader
                
                HStack(spacing: 16) {
                    permissionsCard
                    insightsCard
                }
                
                if let lastItem = historyManager.items.last {
                    recentSessionCard(lastItem)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 1.0)),
                    Color(nsColor: NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.brandAccent.opacity(0.3),
                            Color.brandAccentDeep.opacity(0.4),
                            Color.brandLagoon.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)

            VStack(spacing: 20) {
                // Record button
                Button(action: appState.toggleRecordingFromUI) {
                    ZStack {
                        Circle()
                            .fill(appState.isRecording ? Color.red.opacity(0.2) : Color.brandAccent.opacity(0.2))
                            .frame(width: 88, height: 88)

                        Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(appState.isRecording ? Color.red : Color.brandAccent)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!appState.hasAPIKey)

                // Status text
                Text(appState.isRecording ? "Recording..." : "Tap to Record")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                // Live preview during recording
                if appState.isRecording && !appState.livePreview.isEmpty {
                    Text(appState.livePreview)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .animation(.easeInOut, value: appState.livePreview)
                }

                // Stats chips
                HStack(spacing: 12) {
                    statsChip(icon: "waveform", value: "\(historyManager.totalSessions)", color: Color.brandAccent)
                    statsChip(icon: "clock", value: formattedTime(historyManager.totalRecordingTime), color: Color.brandAccentWarm)
                    statsChip(icon: "chart.line.uptrend.xyaxis", value: formattedTime(historyManager.averageSessionLength), color: Color.brandLagoon)
                }
            }
            .padding(.vertical, 24)
        }
    }
    
    private func statsChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Permissions Card

    private var permissionsCard: some View {
        DashboardCard(
            title: "Permissions",
            systemImage: "checkmark.shield",
            tint: Color.green
        ) {
            VStack(alignment: .leading, spacing: 12) {
                permissionRow(
                    title: "Microphone",
                    icon: "mic.fill",
                    status: micPermissionStatus
                )
                
                Divider()
                
                permissionRow(
                    title: "Accessibility",
                    icon: "hand.raised.fill",
                    status: accessibilityPermissionStatus
                )
            }
        }
    }
    
    private func permissionRow(title: String, icon: String, status: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(status ? Color.green : Color.red)
        }
    }
    
    private var micPermissionStatus: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    private var accessibilityPermissionStatus: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        DashboardCard(
            title: "Insights",
            systemImage: "chart.bar.fill",
            tint: Color.brandAccent
        ) {
            VStack(alignment: .leading, spacing: 12) {
                insightRow(label: "Total Sessions", value: "\(historyManager.totalSessions)")
                Divider()
                insightRow(label: "Recording Time", value: formattedTime(historyManager.totalRecordingTime))
                Divider()
                insightRow(label: "Avg. Length", value: formattedTime(historyManager.averageSessionLength))
            }
        }
    }
    
    private func insightRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Recent Session Card

    private func recentSessionCard(_ item: HistoryItem) -> some View {
        DashboardCard(
            title: "Recent Session",
            systemImage: "clock.arrow.circlepath",
            tint: Color.brandAccentWarm
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.displayText)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                
                Divider()
                
                HStack {
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(formattedTime(item.recordingDuration))
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }
}

// MARK: - Dashboard Card Component

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content
    
    init(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

