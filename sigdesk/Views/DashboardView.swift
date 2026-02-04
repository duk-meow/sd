//
//  DashboardView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var chatStore: ChatStore
    @ObservedObject private var socketService = SocketIOService.shared
    
    enum Tab {
        case home
        case workspace
    }
    
    @State private var selectedTab: Tab = .home
    @State private var workspaceNavigationLevel: NavigationLevel = .groups
    @State private var showConnectedBanner = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            ZStack {
                switch selectedTab {
                case .home:
                    HomeDashboardView(
                        onNavigateToWorkspace: {
                            withAnimation {
                                selectedTab = .workspace
                                workspaceNavigationLevel = .groups
                            }
                        },
                        onNavigateToFeature: { level in
                            withAnimation {
                                selectedTab = .workspace
                                workspaceNavigationLevel = level
                            }
                        }
                    )
                    .transition(.opacity)
                    
                case .workspace:
                    MainDashboardView(navigationLevel: $workspaceNavigationLevel)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Connection Banner Overlay
            VStack {
                if showConnectedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Connected to chat")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.top, 40) // Below notch usually
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
                Spacer()
            }
            
            // Premium Bottom Navigation Bar
            if selectedTab == .home || (workspaceNavigationLevel == .groups) {
                ZStack {
                    // The Pill Container
                    HStack(spacing: 0) {
                        TabBarItem(
                            icon: "house.fill",
                            isSelected: selectedTab == .home
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTab = .home
                                hapticFeedback()
                            }
                        }
                        
                        TabBarItem(
                            icon: "rectangle.3.group.bubble.fill",
                            isSelected: selectedTab == .workspace
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTab = .workspace
                                workspaceNavigationLevel = .groups // Reset to groups when tapping tab
                                hapticFeedback()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // Background Material
                            RoundedRectangle(cornerRadius: 32)
                                .fill(SignalDeskTheme.baseSurface.opacity(0.8))
                                .background(.ultraThinMaterial)
                            
                            // Inner Border/Shine
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.05), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                            
                            // Active Indicator Background (Sliding pill)
                            GeometryReader { geo in
                                let width = geo.size.width / 2
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(SignalDeskTheme.accent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(SignalDeskTheme.accent.opacity(0.3), lineWidth: 0.5)
                                    )
                                    .frame(width: width - 12, height: geo.size.height - 16)
                                    .offset(x: selectedTab == .home ? 6 : width + 6, y: 8)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0), value: selectedTab)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: SignalDeskTheme.accent.opacity(0.15), radius: 15, x: 0, y: 8) // Subtle accent glow shadow
                    .frame(width: 200) // Increased width slightly (from 180)
                    .padding(.bottom, 8) // Reduced spacing from bottom (from 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: showConnectedBanner)
        .onChange(of: socketService.isConnected) { _, connected in
            if connected {
                showConnectedBanner = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showConnectedBanner = false
                }
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium) // Slightly firmer feedback
        generator.impactOccurred()
    }
}

struct TabBarItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? SignalDeskTheme.accent : SignalDeskTheme.textMuted)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .shadow(color: isSelected ? SignalDeskTheme.accent.opacity(0.5) : .clear, radius: 8)
                
                if isSelected {
                    Text(icon == "house.fill" ? "Home" : "Workspace")
                        .font(.system(size: 10, weight: .black)) // Thicker text for premium feel
                        .foregroundColor(SignalDeskTheme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48) // Reduced from 54
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthStore())
        .environmentObject(ProjectStore())
        .environmentObject(GroupStore())
        .environmentObject(ChatStore())
}
