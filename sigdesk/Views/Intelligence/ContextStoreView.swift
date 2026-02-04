//
//  ContextStoreView.swift
//  sigdesk
//
//  AI-classified conversation signals screen
//

import SwiftUI

struct ContextStoreView: View {
    @EnvironmentObject var groupStore: GroupStore
    @State private var contexts: [ContextItem] = []
    @State private var loading = true
    @State private var refreshing = false
    @State private var activeTab: ContextCategory = .decision
    var onBackTapped: () -> Void
    
    var filteredContexts: [ContextItem] {
        contexts.filter { context in
            context.category.contains { $0.uppercased() == activeTab.rawValue }
        }
    }
    
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
                    Text("Context Store")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    
                    Text("AI-extracted conversation signals")
                        .font(.system(size: 12))
                        .foregroundColor(SignalDeskTheme.textMuted)
                }
                
                Spacer()
                
                Button {
                    Task { await fetchContexts(isManual: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(refreshing ? SignalDeskTheme.accent : SignalDeskTheme.textMuted)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(refreshing ? 360 : 0))
                        .animation(refreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: refreshing)
                }
                .buttonStyle(.plain)
                .disabled(refreshing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(SignalDeskTheme.baseBg)
            
            Divider()
                .background(SignalDeskTheme.baseBorder)
            
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(ContextCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            count: contexts.filter { $0.category.contains { $0.uppercased() == category.rawValue } }.count,
                            isActive: activeTab == category,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    activeTab = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(SignalDeskTheme.baseBg)
            
            Divider()
                .background(SignalDeskTheme.baseBorder)
            
            // Content
            if loading {
                loadingView(message: "Scanning Signals")
            } else if filteredContexts.isEmpty {
                emptyStateView(
                    icon: "message.fill",
                    title: "Clear Horizon",
                    message: "SignalDesk hasn't identified any critical \(activeTab.displayName.lowercased()) in recent discussions"
                )
            } else {
                contextListView()
            }
        }
        .background(SignalDeskTheme.baseBg)
        .task {
            await fetchContexts()
        }
    }
    
    private func contextListView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(filteredContexts) { context in
                    ContextCard(context: context, category: activeTab)
                }
            }
            .padding(20)
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
    
    private func fetchContexts(isManual: Bool = false) async {
        if isManual {
            refreshing = true
        }
        
        do {
            contexts = try await IntelligenceService.shared.fetchContexts(groupId: groupStore.activeGroupId)
        } catch {
            print("Failed to fetch context store: \(error)")
        }
        
        loading = false
        refreshing = false
    }
}

struct CategoryTab: View {
    let category: ContextCategory
    let count: Int
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(category.displayName)
                        .font(.system(size: 14, weight: isActive ? .bold : .medium))
                        .foregroundColor(isActive ? SignalDeskTheme.textPrimary : SignalDeskTheme.textMuted)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SignalDeskTheme.accent.opacity(0.7))
                    }
                }
                
                Rectangle()
                    .fill(isActive ? SignalDeskTheme.accent : Color.clear)
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

struct ContextCard: View {
    let context: ContextItem
    let category: ContextCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(category.rawValue)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(SignalDeskTheme.accent)
                            .tracking(1.5)
                        
                        Rectangle()
                            .fill(SignalDeskTheme.baseBorder)
                            .frame(width: 1, height: 16)
                        
                        Text(formatDate(context.classifiedAt))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.2)
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SignalDeskTheme.accent.opacity(0.2))
                            .frame(width: 16, height: 16)
                        
                        Text(context.userId.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                        
                        Text("in")
                            .font(.system(size: 12))
                            .foregroundColor(SignalDeskTheme.textMuted.opacity(0.5))
                        
                        Text(context.groupId.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CONFIDENCE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(SignalDeskTheme.textMuted.opacity(0.5))
                    
                    Text("\(Int(context.confidence.score * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                }
            }
            
            // Content
            Text(context.content)
                .font(.system(size: 16))
                .foregroundColor(SignalDeskTheme.textSecondary)
                .lineSpacing(6)
            
            // AI reasoning
            if !context.confidence.reason.isEmpty {
                Divider()
                    .background(SignalDeskTheme.baseBorder.opacity(0.5))
                
                HStack(alignment: .top, spacing: 8) {
                    Text("AI CONTEXT:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SignalDeskTheme.accent)
                        .tracking(1.0)
                    
                    Text(context.confidence.reason)
                        .font(.system(size: 12))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .italic()
                        .lineSpacing(3)
                }
            }
        }
        .padding(20)
        .background(SignalDeskTheme.baseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}
