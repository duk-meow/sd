//
//  ProjectDrawerView.swift
//  sigdesk
//
//  Mobile-style project drawer (slides from left)
//

import SwiftUI

struct ProjectDrawerView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var authStore: AuthStore
    @Binding var showCreateProject: Bool
    @Binding var selectedProject: Project?
    var onProjectSelected: () -> Void
    var onJoinTapped: () -> Void
    var onClose: () -> Void
    
    @State private var hoveredProjectId: String? = nil
    
    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Workspaces")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .tracking(-0.5)
                        
                        Spacer()
                        
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textMuted)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SignalDeskTheme.accent)
                            .frame(width: 6, height: 6)
                            .shadow(color: SignalDeskTheme.accent.opacity(0.5), radius: 3)
                        
                        Text("\(projectStore.projects.count) ACTIVE NODES")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 20)
                
                // Projects list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(projectStore.projects) { project in
                            let isSelected = projectStore.activeProjectId == project.id
                            
                            Button {
                                selectedProject = project
                                projectStore.setActiveProject(id: project.id)
                                Task {
                                    await groupStore.fetchGroups(projectId: project.id)
                                    onProjectSelected()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    // Discord-style selector indicator
                                    Capsule()
                                        .fill(SignalDeskTheme.accent)
                                        .frame(width: 4, height: isSelected ? 20 : 0)
                                        .opacity(isSelected ? 1 : 0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                    
                                    // Project icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: isSelected ? 14 : 16)
                                            .fill(Color(hex: project.accentColor ?? "7C3AED").opacity(isSelected ? 1 : 0.8))
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color(hex: project.accentColor ?? "7C3AED").opacity(isSelected ? 0.3 : 0), radius: 8, y: 4)
                                        
                                        Text(initials(for: project.name))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .scaleEffect(isSelected ? 1.05 : 1.0)
                                    .animation(.spring(), value: isSelected)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                            .foregroundColor(isSelected ? .white : SignalDeskTheme.textSecondary)
                                        
                                        Text("\(project.members.count) members")
                                            .font(.system(size: 12))
                                            .foregroundColor(SignalDeskTheme.textMuted)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 8)
                            .buttonStyle(.plain)
                        }
                        
                        // Add workspace button
                        Button {
                            showCreateProject = true
                        } label: {
                            HStack(spacing: 12) {
                                Spacer().frame(width: 4)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(SignalDeskTheme.textSecondary)
                                }
                                Text("New Workspace")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SignalDeskTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 8)
                        .buttonStyle(.plain)
                        
                        // Join workspace button
                        Button {
                            onJoinTapped()
                        } label: {
                            HStack(spacing: 12) {
                                Spacer().frame(width: 4)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(SignalDeskTheme.accent.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "link")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(SignalDeskTheme.accent)
                                }
                                Text("Join Workspace")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SignalDeskTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 8)
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 12)
                }
                
                Spacer()
                
                // User profile at bottom
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    HStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(SignalDeskTheme.accent.opacity(0.2))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(authStore.user?.name.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(SignalDeskTheme.accent)
                                )
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(SignalDeskTheme.baseBg, lineWidth: 2))
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(authStore.user?.name ?? "User")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            Text("Online")
                                .font(.system(size: 11))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                        Spacer()
                        Button {
                            authStore.logout()
                        } label: {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                                .foregroundColor(SignalDeskTheme.textMuted)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }
            .background(SignalDeskTheme.baseBg)
            .ignoresSafeArea()
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 1)
            }
        }
    }
}
