//
//  MainDashboardView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26. dfg
//

import SwiftUI

enum NavigationLevel {
    case projects      // Show project dock drawer
    case groups        // Show groups list for selected project
    case chat          // Show chat for selected group
    case summary       // AI summary screen
    case tasks         // AI tasks screen
    case contextStore  // Context store screen
}

struct MainDashboardView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var chatStore: ChatStore
    @ObservedObject private var socketService = SocketIOService.shared

    @State private var showCreateProject = false
    @State private var showCreateGroup = false
    @State private var selectedProject: Project?
    @State private var selectedGroup: Group?
    
    // Navigation state
    @Binding var navigationLevel: NavigationLevel
    @State private var showProjectDrawer = false
    @State private var showJoinProject = false
    @State private var showCreateDM = false

    var body: some View {
        ZStack {
            // Main Content Area
            VStack(spacing: 0) {
                switch navigationLevel {
                case .groups:
                    GroupsListView(
                        showCreateGroup: $showCreateGroup,
                        selectedGroup: $selectedGroup,
                        onGroupSelected: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                navigationLevel = .chat
                            }
                        },
                        onMenuTapped: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showProjectDrawer = true
                            }
                        },
                        onSummaryTapped: { navigationLevel = .summary },
                        onTasksTapped: { navigationLevel = .tasks },
                        onContextStoreTapped: { navigationLevel = .contextStore },
                        onInviteTapped: { showJoinProject = true },
                        onDMAddTapped: { showCreateDM = true }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .chat:
                    ChatAreaView(onBackTapped: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            navigationLevel = .groups
                        }
                    })
                    .transition(.move(edge: .trailing))
                    
                case .summary:
                    SummaryView(onBackTapped: { navigationLevel = .groups })
                        .transition(.move(edge: .bottom))
                        
                case .tasks:
                    TasksView(onBackTapped: { navigationLevel = .groups })
                        .transition(.move(edge: .bottom))
                        
                case .contextStore:
                    ContextStoreView(onBackTapped: { navigationLevel = .groups })
                        .transition(.move(edge: .bottom))
                        
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, (navigationLevel == .groups) ? 64 : 0) // Remove padding in chat/focus modes
            
            // Project Drawer Overlay
            if showProjectDrawer {
                // Dimming Layer
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showProjectDrawer = false
                        }
                    }
                
                HStack(spacing: 0) {
                    ProjectDrawerView(
                        showCreateProject: $showCreateProject,
                        selectedProject: $selectedProject,
                        onProjectSelected: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showProjectDrawer = false
                                navigationLevel = .groups
                            }
                        },
                        onJoinTapped: {
                            showProjectDrawer = false
                            showJoinProject = true
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showProjectDrawer = false
                            }
                        }
                    )
                    .frame(width: min(UIScreen.main.bounds.width * 0.85, 320))
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
                .zIndex(100)
            }
        }
        .task {
            await projectStore.fetchProjects()
            if let pid = projectStore.activeProjectId {
                selectedProject = projectStore.activeProject
                await groupStore.fetchGroups(projectId: pid)
                socketService.joinProject(projectId: pid)
                selectedGroup = groupStore.activeGroup
            }
        }
        .onChange(of: projectStore.activeProjectId) { _, newId in
            selectedProject = projectStore.activeProject
            if let id = newId {
                socketService.joinProject(projectId: id)
            }
        }
        .onChange(of: groupStore.activeGroupId) { _, _ in
            selectedGroup = groupStore.activeGroup
        }
        .onAppear {
            selectedProject = projectStore.activeProject
            selectedGroup = groupStore.activeGroup
        }
        .sheet(isPresented: $showCreateProject) {
            CreateProjectModal()
        }
        .sheet(isPresented: $showCreateGroup) {
            if let projectId = projectStore.activeProjectId {
                CreateGroupModal(projectId: projectId)
            }
        }
        .sheet(isPresented: $showJoinProject) {
            JoinProjectModal()
        }
        .sheet(isPresented: $showCreateDM) {
            if let projectId = projectStore.activeProjectId {
                CreateDMModal(projectId: projectId)
            }
        }
        .background(PremiumBackground())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainDashboardView(navigationLevel: .constant(.groups))
        .environmentObject(AuthStore())
        .environmentObject(ProjectStore())
        .environmentObject(GroupStore())
        .environmentObject(ChatStore())
}
