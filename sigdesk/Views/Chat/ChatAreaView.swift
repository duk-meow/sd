//
//  ChatAreaView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct ChatAreaView: View {
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var authStore: AuthStore
    var onBackTapped: () -> Void

    var body: some View {
        if let groupId = groupStore.activeGroupId {
            VStack(spacing: 0) {
                ChatHeaderView(onBackTapped: onBackTapped)
                MessageListView(groupId: groupId)
                ChatInputView(groupId: groupId)
            }
            .background(SignalDeskTheme.chatMessageBg.opacity(0.8))
        } else {
            ChatEmptyStateView(onBackTapped: onBackTapped)
        }
    }
}

struct ChatEmptyStateView: View {
    @EnvironmentObject var authStore: AuthStore
    var onBackTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with back button
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
                
                Text("SignalDesk")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                
                Spacer()
                
                Button { 
                    authStore.logout() 
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            
            Divider()
                .background(SignalDeskTheme.baseBorder)

            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 56))
                    .foregroundColor(SignalDeskTheme.accent.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("Welcome to SignalDesk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    
                    Text("Select a channel to start messaging")
                        .font(.system(size: 15))
                        .foregroundColor(SignalDeskTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SignalDeskTheme.chatMessageBg.opacity(0.8))
    }
}

struct ChatHeaderView: View {
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var authStore: AuthStore
    var onBackTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                onBackTapped()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            // Channel info
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SignalDeskTheme.whiteOver5)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "number")
                        .font(.system(size: 16))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let group = groupStore.activeGroup {
                        Text(group.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        
                        if let groupId = groupStore.activeGroupId,
                           !chatStore.getTypingUsers(for: groupId).isEmpty {
                            Text("typing...")
                                .font(.system(size: 13))
                                .foregroundColor(SignalDeskTheme.accent)
                        } else {
                            Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                    }
                }
            }

            Spacer()

            // More options
            Button {
                // TODO: Show channel info/settings
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(SignalDeskTheme.textMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(SignalDeskTheme.baseBg.opacity(0.8))
        .overlay(alignment: .bottom) {
            Divider()
                .background(SignalDeskTheme.baseBorder)
        }
    }
}
