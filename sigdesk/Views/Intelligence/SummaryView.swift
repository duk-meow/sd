//
//  SummaryView.swift
//  sigdesk
//
//  AI-generated conversation summary screen
//

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var groupStore: GroupStore
    @State private var summary: Summary?
    @State private var loading = true
    @State private var refreshing = false
    var onBackTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button {
                    onBackTapped()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intelligence Report")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    
                    Text("Live conversation analysis")
                        .font(.system(size: 12))
                        .foregroundColor(SignalDeskTheme.textMuted)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await fetchSummary(isManual: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(refreshing ? SignalDeskTheme.accent : SignalDeskTheme.textMuted)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(refreshing ? 360 : 0))
                        .animation(refreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: refreshing)
                }
                .buttonStyle(.plain)
                .disabled(refreshing || groupStore.activeGroupId == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(SignalDeskTheme.baseBg)
            
            Divider()
                .background(SignalDeskTheme.baseBorder)
            
            // Content
            if groupStore.activeGroupId == nil {
                emptyStateView(
                    icon: "tray.fill",
                    title: "No Discussion Selected",
                    message: "Select a channel to view AI-generated insights"
                )
            } else if loading {
                loadingView(message: "Analyzing History")
            } else if let summary = summary {
                summaryContentView(summary: summary)
            } else {
                emptyStateView(
                    icon: "doc.text.fill",
                    title: "Analysis Pending",
                    message: "Insufficient data to generate a high-fidelity report"
                )
            }
        }
        .background(SignalDeskTheme.baseBg)
        .task {
            await fetchSummary()
        }
        .onChange(of: groupStore.activeGroupId) { _, _ in
            Task { await fetchSummary() }
        }
    }
    
    private func summaryContentView(summary: Summary) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Updated timestamp
                if let updatedAt = summary.updatedAt, !updatedAt.isEmpty {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SignalDeskTheme.accent)
                            .frame(width: 6, height: 6)
                        
                        Text("Updated \(formatTime(updatedAt))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Main content box
                if let content = summary.content, !content.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Strategic Overview")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            
                            Rectangle()
                                .fill(SignalDeskTheme.accent.opacity(0.5))
                                .frame(width: 48, height: 4)
                                .clipShape(Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { paragraph in
                                Text(paragraph)
                                    .font(.system(size: 16))
                                    .foregroundColor(SignalDeskTheme.textSecondary)
                                    .lineSpacing(6)
                            }
                        }
                    }
                    .padding(24)
                    .background(SignalDeskTheme.baseSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)
                }
                
                // Key points
                if let keyPoints = summary.keyPoints, !keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CRITICAL POINTS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.2)
                        
                        VStack(spacing: 16) {
                            ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: 16) {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(SignalDeskTheme.accent)
                                    
                                    Text(point)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SignalDeskTheme.textSecondary)
                                        .italic()
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(SignalDeskTheme.baseSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 20)
                }
                
                if (summary.content?.isEmpty ?? true) && (summary.keyPoints?.isEmpty ?? true) {
                    emptyStateView(
                        icon: "doc.text.fill",
                        title: "Analysis Pending",
                        message: "Insufficient data to generate a high-fidelity report"
                    )
                    .padding(.top, 40)
                } else {
                    // AI Context footer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Context")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        
                        Text("Derived from cross-referencing team velocity and historical decision tokens within this conversation stream.")
                            .font(.system(size: 13))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .lineSpacing(4)
                        
                        Divider()
                            .background(SignalDeskTheme.baseBorder)
                            .padding(.vertical, 8)
                        
                        Text("VERIFIED OUTPUT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SignalDeskTheme.accent)
                            .tracking(1.5)
                    }
                    .padding(24)
                    .background(SignalDeskTheme.baseSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(SignalDeskTheme.accent.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(SignalDeskTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadingView(message: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: SignalDeskTheme.accent))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(SignalDeskTheme.textMuted)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func fetchSummary(isManual: Bool = false) async {
        guard let groupId = groupStore.activeGroupId else {
            loading = false
            return
        }
        
        if isManual {
            refreshing = true
        } else {
            loading = true
        }
        
        do {
            summary = try await IntelligenceService.shared.fetchSummary(groupId: groupId)
        } catch {
            print("Failed to fetch summary: \(error)")
        }
        
        loading = false
        refreshing = false
    }
    
    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
}
