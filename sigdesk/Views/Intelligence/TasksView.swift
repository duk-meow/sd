//
//  TasksView.swift
//  sigdesk
//
//  AI-extracted action items screen
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var groupStore: GroupStore
    @State private var actionData: ActionData?
    @State private var loading = false
    @State private var extracting = false
    @State private var completedTasks: Set<String> = []
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
                    Text("Action Items")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    
                    Text("AI-extracted tasks from conversation")
                        .font(.system(size: 12))
                        .foregroundColor(SignalDeskTheme.textMuted)
                }
                
                Spacer()
                
                Button {
                    Task { await extractActions() }
                } label: {
                    HStack(spacing: 8) {
                        if extracting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        }
                        Text(extracting ? "Extracting..." : "Extract")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [SignalDeskTheme.accent, Color(hex: "5B21B6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .opacity((extracting || groupStore.activeGroupId == nil) ? 0.5 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(extracting || groupStore.activeGroupId == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(SignalDeskTheme.baseBg)
            
            Divider()
                .background(SignalDeskTheme.baseBorder)
            
            // Content
            if groupStore.activeGroupId == nil {
                emptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Group Selected",
                    message: "Select a channel to extract action items from the conversation"
                )
            } else if loading && actionData == nil {
                loadingView(message: "Extracting Tasks")
            } else if let data = actionData {
                tasksContentView(data: data)
            } else {
                emptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "Ready to Extract",
                    message: "Tap \"Extract\" to analyze the conversation and identify tasks"
                )
            }
        }
        .background(SignalDeskTheme.baseBg)
        .task {
            loadCachedData()
        }
        .onChange(of: groupStore.activeGroupId) { _, _ in
            loadCachedData()
        }
    }
    
    private func tasksContentView(data: ActionData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                if !data.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OVERVIEW")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.5)
                        
                        Text(data.summary)
                            .font(.system(size: 14))
                            .foregroundColor(SignalDeskTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(SignalDeskTheme.baseSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // Tasks
                if data.actions.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Actions Found",
                        message: "No actionable tasks were identified in the recent conversation"
                    )
                } else {
                    ForEach(Array(data.actions.enumerated()), id: \.offset) { index, action in
                        TaskCard(
                            action: action,
                            index: index,
                            isCompleted: completedTasks.contains(getTaskId(action, index)),
                            onToggle: {
                                toggleTaskCompletion(action, index)
                            }
                        )
                    }
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
    
    private func getTaskId(_ action: ActionItem, _ index: Int) -> String {
        return "\(index)_\(action.task.prefix(50))"
    }
    
    private func toggleTaskCompletion(_ action: ActionItem, _ index: Int) {
        let taskId = getTaskId(action, index)
        if completedTasks.contains(taskId) {
            completedTasks.remove(taskId)
        } else {
            completedTasks.insert(taskId)
        }
        saveCachedData()
    }
    
    private func loadCachedData() {
        guard let groupId = groupStore.activeGroupId else { return }
        
        // Load completed tasks
        if let data = UserDefaults.standard.data(forKey: "tasks_completed_\(groupId)"),
           let tasks = try? JSONDecoder().decode([String].self, from: data) {
            completedTasks = Set(tasks)
        }
        
        // Load action data
        if let data = UserDefaults.standard.data(forKey: "tasks_data_\(groupId)"),
           let cached = try? JSONDecoder().decode(ActionData.self, from: data) {
            actionData = cached
        }
    }
    
    private func saveCachedData() {
        guard let groupId = groupStore.activeGroupId else { return }
        
        // Save completed tasks
        if let data = try? JSONEncoder().encode(Array(completedTasks)) {
            UserDefaults.standard.set(data, forKey: "tasks_completed_\(groupId)")
        }
        
        // Save action data
        if let data = actionData, let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "tasks_data_\(groupId)")
        }
    }
    
    private func extractActions() async {
        guard let groupId = groupStore.activeGroupId else { return }
        
        extracting = true
        if actionData == nil {
            loading = true
        }
        
        do {
            actionData = try await IntelligenceService.shared.extractTasks(groupId: groupId)
            saveCachedData()
        } catch {
            print("Failed to extract actions: \(error)")
        }
        
        loading = false
        extracting = false
    }
}

struct TaskCard: View {
    let action: ActionItem
    let index: Int
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    onToggle()
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isCompleted ? SignalDeskTheme.accent : SignalDeskTheme.textMuted)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Priority and assignee
                    HStack(spacing: 8) {
                        Text(action.priority.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(priorityColor(action.priority))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor(action.priority).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(priorityColor(action.priority).opacity(0.3), lineWidth: 1)
                            )
                        
                        Rectangle()
                            .fill(SignalDeskTheme.baseBorder)
                            .frame(width: 1, height: 16)
                        
                        Text(action.assignee)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                    
                    // Task title
                    Text(action.task)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                        .strikethrough(isCompleted)
                        .opacity(isCompleted ? 0.6 : 1.0)
                    
                    // Deadline
                    HStack(spacing: 6) {
                        Text("DEADLINE:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.2)
                        
                        Text(action.deadline)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SignalDeskTheme.textSecondary)
                    }
                    
                    // Reasoning
                    if !action.reasoning.isEmpty {
                        Divider()
                            .background(SignalDeskTheme.baseBorder.opacity(0.5))
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("CONTEXT:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(SignalDeskTheme.accent)
                                .tracking(1.0)
                            
                            Text(action.reasoning)
                                .font(.system(size: 12))
                                .foregroundColor(SignalDeskTheme.textMuted)
                                .italic()
                                .lineSpacing(3)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(SignalDeskTheme.baseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .opacity(isCompleted ? 0.7 : 1.0)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}
