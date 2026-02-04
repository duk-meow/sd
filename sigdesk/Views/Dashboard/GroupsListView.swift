//
//  GroupsListView.swift
//  sigdesk
//
//  Mobile-style groups list view
//

import SwiftUI
//jhwdfre

struct GroupsListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var authStore: AuthStore
    @Binding var showCreateGroup: Bool
    @Binding var selectedGroup: Group?
    var onGroupSelected: () -> Void
    var onMenuTapped: () -> Void
    var onSummaryTapped: (() -> Void)?
    var onTasksTapped: (() -> Void)?
    var onContextStoreTapped: (() -> Void)?
    var onInviteTapped: (() -> Void)?
    var onDMAddTapped: (() -> Void)?
    
    var currentProjectGroups: [Group] {
        guard let projectId = projectStore.activeProjectId else { return [] }
        return groupStore.getGroupsByProject(projectId: projectId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - Discord style
            Button {
                onMenuTapped()
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SignalDeskTheme.accent.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Text(projectStore.activeProject?.name.prefix(1).uppercased() ?? "W")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SignalDeskTheme.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(projectStore.activeProject?.name ?? "SignalDesk")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Online")
                                    .font(.system(size: 12))
                                    .foregroundColor(SignalDeskTheme.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            onInviteTapped?()
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.accent)
                                .padding(8)
                                .background(SignalDeskTheme.accent.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                        .background(SignalDeskTheme.baseBorder)
                }
                .background(SignalDeskTheme.baseSurface)
                .background(SignalDeskTheme.baseSurface.ignoresSafeArea(edges: .top))
            }
            .buttonStyle(.plain)
            
            if projectStore.activeProjectId == nil {
                // Empty state handled as before
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(SignalDeskTheme.accent.opacity(0.05))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "tray.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(SignalDeskTheme.accent.opacity(0.2))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Workspace")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        
                        Text("Select a project from the side menu")
                            .font(.system(size: 14))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Groups list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Intelligence Apps Section - Premium Tray Style
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("AI ASSISTANT")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.5)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                MiniIntelligenceCard(icon: "sparkles", title: "Summary", color: .purple, action: { onSummaryTapped?() })
                                MiniIntelligenceCard(icon: "checklist", title: "Tasks", color: .orange, action: { onTasksTapped?() })
                                MiniIntelligenceCard(icon: "brain.head.profile", title: "Context", color: .green, action: { onContextStoreTapped?() })
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)

                        // Channels section
                        let channels = currentProjectGroups.filter { $0.type == "channel" || $0.type == nil }
                        let dms = currentProjectGroups.filter { $0.type == "dm" }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("CHANNELS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.5)
                                
                                Spacer()
                                
                                Button {
                                    showCreateGroup = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14))
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 6)
                            
                            ForEach(channels) { group in
                                groupRow(group)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("DIRECT MESSAGES")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.5)
                                Spacer()
                                Button {
                                    onDMAddTapped?()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14))
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            
                            ForEach(dms) { group in
                                groupRow(group)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(SignalDeskTheme.baseBg.ignoresSafeArea())
        .zIndex(99)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(SignalDeskTheme.baseBorder.opacity(0.5))
                .frame(width: 1)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func groupRow(_ group: Group) -> some View {
        let isSelected = selectedGroup?.id == group.id
        
        Button {
            selectedGroup = group
            groupStore.setActiveGroup(id: group.id)
            onGroupSelected()
        } label: {
            HStack(spacing: 12) {
                if group.type == "dm" {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(SignalDeskTheme.accent.opacity(0.1))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(group.name.prefix(1).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SignalDeskTheme.accent)
                            )
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(SignalDeskTheme.baseBg, lineWidth: 1.5))
                            .offset(x: 2, y: 2)
                    }
                } else {
                    Image(systemName: (group.isPrivate == true) ? "lock.fill" : "number")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : SignalDeskTheme.textMuted)
                        .frame(width: 20)
                }
                
                Text(group.name)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : SignalDeskTheme.textSecondary)
                
                Spacer()
                
                if group.members.count > 1 && group.type != "dm" {
                    Text("\(group.members.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? SignalDeskTheme.accent.opacity(0.12) : SignalDeskTheme.baseSurface.opacity(0.6))
            .background(.ultraThinMaterial.opacity(isSelected ? 0.4 : 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SignalDeskTheme.accent.opacity(0.4) : SignalDeskTheme.baseBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.05), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}

struct MiniIntelligenceCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SignalDeskTheme.baseSurface.opacity(0.8))
                        .background(.ultraThinMaterial.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(SignalDeskTheme.baseBorder.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                        .shadow(color: color.opacity(0.3), radius: 4)
                }
                .frame(height: 60)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SignalDeskTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
