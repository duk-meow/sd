//
//  ChatViewExample.swift
//  sigdesk
//
//  Example SwiftUI chat view using SocketIOService: connection status,
//  messages by groupId, typing indicator, join/leave on appear/disappear.
//

import SwiftUI

struct ChatViewExample: View {
    let projectId: String
    let groupId: String
    
    @ObservedObject private var socketService = SocketIOService.shared
    @State private var inputText = ""
    @State private var isTyping = false
    
    private var messages: [ChatMessage] {
        socketService.getMessages(for: groupId)
    }
    
    private var typingUsers: [String] {
        socketService.getTypingUsers(for: groupId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(socketService.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(socketService.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                        if !typingUsers.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.blue.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                }
                                Text("typing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input + send
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Type a message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
                    .lineLimit(1...4)
                    .onChange(of: inputText) { _, newValue in
                        let typing = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        if typing != isTyping {
                            isTyping = typing
                            socketService.sendTyping(groupId: groupId, isTyping: typing)
                        }
                    }
                    .onSubmit { sendMessage() }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(inputText.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .onAppear {
            socketService.joinProject(projectId: projectId)
            socketService.joinGroup(groupId: groupId)
        }
        .onDisappear {
            socketService.leaveGroup(groupId: groupId)
            if isTyping {
                socketService.sendTyping(groupId: groupId, isTyping: false)
            }
        }
    }
    
    private func messageRow(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.userName ?? "Member")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(message.content)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(12)
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        socketService.sendMessage(groupId: groupId, content: text, type: "text")
        inputText = ""
        if isTyping {
            isTyping = false
            socketService.sendTyping(groupId: groupId, isTyping: false)
        }
    }
}

#Preview {
    NavigationStack {
        ChatViewExample(projectId: "preview-project", groupId: "preview-group")
            .environmentObject(AuthStore())
    }
}
