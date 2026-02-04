//
//  ProjectSidebarView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct ProjectSidebarView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var authStore: AuthStore
    @Binding var showCreateProject: Bool
    @Binding var selectedProject: Project?
    
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
            // Container for the "Dock"
            VStack {
                // SD Logo - fixed at top
                VStack(spacing: 0) {
                    Text("SD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7C3AED"), Color(hex: "5B21B6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color(hex: "7C3AED").opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Scrollable Projects - The Dock Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(projectStore.projects) { project in
                            let isSelected = projectStore.activeProjectId == project.id
                            let isHovered = hoveredProjectId == project.id
                            
                            Button {
                                selectedProject = project
                                projectStore.setActiveProject(id: project.id)
                                Task { await groupStore.fetchGroups(projectId: project.id) }
                                
                                // Bouncy selection feedback
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                                    hoveredProjectId = nil // Reset hover to allow bounce to be visible
                                }
                            } label: {
                                ProjectDockIcon(
                                    initials: initials(for: project.name),
                                    accentColor: project.accentColor ?? "7C3AED",
                                    isSelected: isSelected,
                                    isHovered: isHovered
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    hoveredProjectId = hovering ? project.id : nil
                                }
                            }
                        }

                        // Separator
                        Rectangle()
                            .fill(SignalDeskTheme.baseBorder)
                            .frame(height: 1)
                            .frame(width: 24)
                            .padding(.vertical, 4)

                        // Add Project Button
                        Button {
                            showCreateProject = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.textMuted)
                                .frame(width: 48, height: 48)
                                .background(SignalDeskTheme.baseSurface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        .foregroundColor(SignalDeskTheme.baseBorder)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
                
                Spacer(minLength: 0)

                // Bottom Utilities
                VStack(spacing: 12) {
                    UtilityIcon(systemName: "checklist")
                    UtilityIcon(systemName: "chart.line.uptrend.xyaxis")
                    
                    Rectangle()
                        .fill(SignalDeskTheme.baseBorder)
                        .frame(height: 1)
                        .frame(width: 24)
                        .padding(.vertical, 4)
                    
                    Button {
                        authStore.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .frame(width: 40, height: 40)
                            .background(SignalDeskTheme.baseHover.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)
            }
            .frame(width: 72)
            .background(
                ZStack {
                    // Glass effect
                    BlurView()
                    SignalDeskTheme.baseBg.opacity(0.4)
                }
            )
            .clipShape(RoundedCorner(radius: 24, corners: [.topRight, .bottomRight]))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 5, y: 0)
        }
        .frame(width: 84) // Slightly wider to give breathing room
        .background(Color.clear)
    }
}

struct ProjectDockIcon: View {
    let initials: String
    let accentColor: String
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            // Background / Shape
            RoundedRectangle(cornerRadius: isSelected || isHovered ? 14 : 18)
                .fill(isSelected ? Color(hex: accentColor) : SignalDeskTheme.baseSurface)
                .frame(width: 48, height: 48)
                .shadow(color: isSelected ? Color(hex: accentColor).opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
            
            Text(initials)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : SignalDeskTheme.textSecondary)
            
            // Selection Indicator (Mac style dot)
            if isSelected {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .offset(x: -32) // Positioned to the left like Mac dock
            }
        }
        .scaleEffect(isHovered ? 1.15 : (isSelected ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct UtilityIcon: View {
    let systemName: String
    @State private var isHovered = false
    
    var body: some View {
        Button {} label: {
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundColor(isHovered ? .white : SignalDeskTheme.textMuted)
                .frame(width: 40, height: 40)
                .background(isHovered ? SignalDeskTheme.baseHover : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { h in isHovered = h }
    }
}

// Color hex extension (shared with Theme)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

