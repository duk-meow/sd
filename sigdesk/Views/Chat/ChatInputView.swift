//
//  ChatInputView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct AICommand: Identifiable {
    let id: String
    let label: String
    let icon: String
    let desc: String
    let color: Color
}

struct ChatInputView: View {
    let groupId: String

    @EnvironmentObject var chatStore: ChatStore
    @State private var messageText = ""
    @State private var isTyping = false
    @State private var showCommands = false
    @State private var commandIndex = 0
    @FocusState private var isFocused: Bool

    let commands: [AICommand] = [
        AICommand(id: "DECISION", label: "Decision", icon: "checkmark.circle.fill", desc: "Search through decisions", color: .emerald),
        AICommand(id: "ACTION", label: "Action", icon: "clipboard.fill", desc: "Find action items", color: .blue),
        AICommand(id: "SUGGESTION", label: "Suggestion", icon: "lightbulb.fill", desc: "Review suggestions", color: .orange),
        AICommand(id: "QUESTION", label: "Question", icon: "questionmark.circle.fill", desc: "Check unanswered questions", color: .purple),
        AICommand(id: "CONSTRAINT", label: "Constraint", icon: "exclamationmark.triangle.fill", desc: "Look for constraints", color: .rose),
        AICommand(id: "ASSUMPTION", label: "Assumption", icon: "layers.fill", desc: "Identify assumptions", color: .indigo),
        AICommand(id: "OTHER", label: "Other", icon: "bubble.left.fill", desc: "General search", color: .gray)
    ]

    init(groupId: String) {
        self.groupId = groupId
    }

    var filteredCommands: [AICommand] {
        if messageText.hasPrefix("/") {
            let query = messageText.dropFirst().lowercased().split(separator: " ").first ?? ""
            if query.isEmpty { return commands }
            return commands.filter { $0.id.lowercased().contains(query) || $0.label.lowercased().contains(query) }
        }
        return []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Command Menu Overlay
            if showCommands && !filteredCommands.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("COMMANDS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.0)
                        Spacer()
                        Text("ESC TO CLOSE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textMuted.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SignalDeskTheme.whiteOver5)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, cmd in
                                Button {
                                    selectCommand(cmd)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(cmd.color.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: cmd.icon)
                                                .font(.system(size: 14))
                                                .foregroundColor(cmd.color)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("/\(cmd.label)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(SignalDeskTheme.textPrimary)
                                            
                                            Text(cmd.desc)
                                                .font(.system(size: 11))
                                                .foregroundColor(SignalDeskTheme.textMuted)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(index == commandIndex ? SignalDeskTheme.whiteOver5 : Color.clear)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }
                .background(SignalDeskTheme.baseBg.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SignalDeskTheme.whiteOver5, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message #\(groupId.suffix(4))", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(SignalDeskTheme.chatInputFieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SignalDeskTheme.whiteOver5, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .onChange(of: messageText) { _, newValue in
                        handleTextChange(newValue)
                    }
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? SignalDeskTheme.textMuted
                                : SignalDeskTheme.accent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(SignalDeskTheme.chatInputFieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SignalDeskTheme.whiteOver5, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Return to send · Shift + Return to new line")
                .font(.system(size: 10))
                .foregroundColor(SignalDeskTheme.textMuted)
                .padding(.top, 8)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8) // Reduced but will be supplemented by safe area
        .background(SignalDeskTheme.chatInputBg.opacity(0.1))
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SignalDeskTheme.whiteOver5)
                .frame(height: 1)
        }
    }

    private func handleTextChange(_ text: String) {
        // Typing indicator
        let shouldBeTyping = !text.isEmpty
        if shouldBeTyping != isTyping {
            isTyping = shouldBeTyping
            chatStore.sendTyping(groupId: groupId, isTyping: shouldBeTyping)
        }

        // Command detection
        if text.hasPrefix("/") && !text.contains(" ") {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCommands = true
                commandIndex = 0
            }
        } else if !text.hasPrefix("/") {
            showCommands = false
        }
    }

    private func selectCommand(_ cmd: AICommand) {
        messageText = "/\(cmd.id) "
        showCommands = false
        isFocused = true
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("/") {
            let parts = trimmed.split(separator: " ", maxSplits: 1)
            let cmdStr = parts[0].dropFirst().uppercased()
            let query = parts.count > 1 ? String(parts[1]) : ""
            
            if commands.contains(where: { $0.id == cmdStr }) {
                messageText = ""
                showCommands = false
                Task {
                    await chatStore.handleSlashCommand(groupId: groupId, command: String(cmdStr), query: query)
                }
                return
            }
        }

        chatStore.sendMessage(groupId: groupId, content: trimmed)
        messageText = ""

        if isTyping {
            isTyping = false
            chatStore.sendTyping(groupId: groupId, isTyping: false)
        }
    }
}

extension Color {
    static let emerald = Color(red: 52/255, green: 211/255, blue: 153/255)
    static let rose = Color(red: 251/255, green: 113/255, blue: 133/255)
    static let indigo = Color(red: 129/255, green: 140/255, blue: 248/255)
}
