//
//  GroupSidebarView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct GroupSidebarView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var authStore: AuthStore
    @Binding var showCreateGroup: Bool
    @Binding var selectedGroup: Group?

    var currentProjectGroups: [Group] {
        guard let projectId = projectStore.activeProjectId else { return [] }
        return groupStore.getGroupsByProject(projectId: projectId)
    }

    var body: some View {
        VStack(spacing: 0) {
            if projectStore.activeProjectId == nil {
                VStack(spacing: 16) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 32))
                        .foregroundColor(SignalDeskTheme.accent.opacity(0.5))
                    Text("Select a project")
                        .font(.headline)
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    Text("Choose a workspace from the dock to get started.")
                        .font(.subheadline)
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SignalDeskTheme.baseBg)
            } else {
                VStack(spacing: 0) {
                    // Project Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(projectStore.activeProject?.name ?? "")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: .green.opacity(0.5), radius: 4)
                            Text("Online")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SignalDeskTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Section Header
                            HStack {
                                Text("CHANNELS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.0)
                                Spacer()
                                Button {
                                    showCreateGroup = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                        .padding(4)
                                        .background(SignalDeskTheme.whiteOver5)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)

                            ForEach(currentProjectGroups) { group in
                                let isSelected = groupStore.activeGroupId == group.id
                                Button {
                                    selectedGroup = group
                                    groupStore.setActiveGroup(id: group.id)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: (group.isPrivate == true) ? "lock.fill" : "number")
                                            .font(.system(size: 15))
                                            .foregroundColor(isSelected ? .white : SignalDeskTheme.textMuted)
                                            .frame(width: 20)
                                        
                                        Text(group.name)
                                            .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                                            .foregroundColor(isSelected ? .white : SignalDeskTheme.textSecondary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? SignalDeskTheme.accent : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.horizontal, 8)
                                }
                                .buttonStyle(.plain)
                            }

                            // Add Channel Button
                            Button {
                                showCreateGroup = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                    Text("Add Channel")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // User Profile / Status at bottom
                    HStack(spacing: 12) {
                        Circle()
                            .fill(SignalDeskTheme.accent)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(authStore.user?.name.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authStore.user?.name ?? "User")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            Text("Active now")
                                .font(.system(size: 11))
                                .foregroundColor(Color.green)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                    .padding(16)
                    .background(SignalDeskTheme.whiteOver5)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(12)
                }
                .background(SignalDeskTheme.baseBg)
            }
        }
        .frame(minWidth: 240, maxWidth: 240)
        .background(SignalDeskTheme.baseBg)
    }
}
