//
//  MessageListView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct MessageListView: View {
    let groupId: String

    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var authStore: AuthStore

    var messages: [Message] {
        chatStore.getMessages(for: groupId)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if messages.isEmpty {
                        VStack(spacing: 16) {
                            Text("👋")
                                .font(.system(size: 48))
                            Text("No messages yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.textSecondary)
                            Text("Say hello to start the conversation! Or just say meow.")
                                .font(.system(size: 14))
                                .foregroundColor(SignalDeskTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(messages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.clear)
            .safeAreaInset(edge: .bottom) {
                if chatStore.isAIThinking(for: groupId) || !chatStore.getTypingUsers(for: groupId).isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if chatStore.isAIThinking(for: groupId) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: SignalDeskTheme.accent))
                                    .scaleEffect(0.6)
                                
                                Text("SignalDesk is thinking...")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(SignalDeskTheme.accent)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        if !chatStore.getTypingUsers(for: groupId).isEmpty {
                            HStack(spacing: 4) {
                                TypingDot()
                                TypingDot(delay: 0.2)
                                TypingDot(delay: 0.4)
                                
                                Text("Someone is typing...")
                                    .font(.system(size: 13))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: SignalDeskTheme.chatMessageBg.opacity(0.8), location: 0.2),
                                .init(color: SignalDeskTheme.chatMessageBg, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .task {
                await chatStore.fetchMessages(groupId: groupId)
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(SignalDeskTheme.chatMessageBg)
        .overlay(alignment: .topTrailing) {
            IntelligenceSyncIndicator(pendingCount: chatStore.getPendingAIItems(for: groupId))
        }
    }
}

struct TypingDot: View {
    var delay: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(SignalDeskTheme.textMuted)
            .frame(width: 4, height: 4)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
                }
            }



struct IntelligenceSyncIndicator: View {
    let pendingCount: Int
    @State private var pulse = false
    
    var body: some View {
        if pendingCount > 0 {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(SignalDeskTheme.accent.opacity(0.2), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(SignalDeskTheme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: pulse)
                }
                
                Text("\(pendingCount) in queue")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(SignalDeskTheme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SignalDeskTheme.baseSurface.opacity(0.9))
            .glassCard(cornerRadius: 12)
            .padding(16)
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .onAppear { pulse = true }
        }
    }
}

struct MessageRow: View {
    let message: Message
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var chatStore: ChatStore

    var isCurrentUser: Bool {
        message.userId == authStore.user?.id
    }

    var isMessagePending: Bool {
        guard !isCurrentUser && message.type == "text" && message.userId != "ai-system" else { return false }
        let lastSync = chatStore.lastAIUpdate[message.groupId] ?? Date.distantPast
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: message.createdAt) {
            return date > lastSync
        }
        return false
    }

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 0) {
            if message.type == "system" {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(message.content)
                            .font(.system(size: 12))
                            .foregroundColor(SignalDeskTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SignalDeskTheme.whiteOver5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(SignalDeskTheme.whiteOver5, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    if !isCurrentUser {
                        if message.userId == "ai-system" {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(SignalDeskTheme.accent.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundColor(SignalDeskTheme.accent)
                            }
                        } else {
                            Circle()
                                .fill(SignalDeskTheme.baseHover)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String((message.userName ?? "Member").prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(SignalDeskTheme.textSecondary)
                                )
                        }
                    }

                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                        if !isCurrentUser {
                            Text(message.userName ?? "Member")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(message.userId == "ai-system" ? SignalDeskTheme.accent : SignalDeskTheme.textSecondary)
                        }
                        
                        Text(message.content)
                            .font(.system(size: 15))
                            .foregroundColor(isCurrentUser ? .white : SignalDeskTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                isCurrentUser
                                    ? SignalDeskTheme.accent
                                    : (message.userId == "ai-system" ? SignalDeskTheme.baseSurface : SignalDeskTheme.baseSurface.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(message.userId == "ai-system" ? SignalDeskTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                if isMessagePending {
                                    Circle()
                                        .fill(SignalDeskTheme.accent)
                                        .frame(width: 6, height: 6)
                                        .padding(6)
                                        .shadow(color: SignalDeskTheme.accent, radius: 2)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text(formatDate(message.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }

                    if isCurrentUser {
                        Spacer(minLength: 0)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            let d = fallback.date(from: dateString) ?? date
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: d)
        }
        return ""
    }
}
