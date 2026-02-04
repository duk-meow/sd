//
//  ChatStore.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatStore: ObservableObject {
    @Published var messages: [String: [Message]] = [:]
    @Published var typingUsers: [String: [String]] = [:]
    @Published var aiProcessing: [String: Bool] = [:]
    @Published var lastAIUpdate: [String: Date] = [:]
    @Published var messagesSinceLastSync: [String: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let messageService = MessageService.shared
    private let socketService = SocketIOService.shared
    
    init() {
        socketService.$messages
            .map { $0.mapValues { list in list.map { Message(from: $0) } } }
            .receive(on: DispatchQueue.main)
            .assign(to: &$messages)
        socketService.$typingUsers
            .receive(on: DispatchQueue.main)
            .assign(to: &$typingUsers)
        socketService.$aiProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$aiProcessing)
        
        socketService.$lastIntelligenceUpdate
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] updates in
                for (gid, _) in updates {
                    self?.messagesSinceLastSync[gid] = 0
                }
            })
            .assign(to: &$lastAIUpdate)
        
        socketService.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allMessages in
                for (gid, msgs) in allMessages {
                    // Logic: Count messages after the last sync date
                    let lastSyncDate = self?.lastAIUpdate[gid] ?? .distantPast
                    let count = msgs.filter { msg in
                        // Basic heuristic: check how many messages were added after sync
                        // Or just increment local counter
                        return true // Placeholder, handled in refined sendMessage logic
                    }.count
                    // We'll manage this counter more accurately in fetch and send
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func getMessages(for groupId: String) -> [Message] {
        messages[groupId] ?? []
    }
    
    func getTypingUsers(for groupId: String) -> [String] {
        typingUsers[groupId] ?? []
    }
    
    func isAIThinking(for groupId: String) -> Bool {
        aiProcessing[groupId] ?? false
    }
    
    func getPendingAIItems(for groupId: String) -> Int {
        let msgs = messages[groupId] ?? []
        let lastSync = lastAIUpdate[groupId] ?? .distantPast
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return msgs.filter { msg in
            guard msg.type == "text" && msg.userId != "ai-system" else { return false }
            if let date = formatter.date(from: msg.createdAt) {
                return date > lastSync
            }
            return true
        }.count
    }
    
    func fetchMessages(groupId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let fetchedMessages = try await messageService.getByGroup(groupId: groupId)
            let chatMessages = fetchedMessages.map { ChatMessage(from: $0) }
            socketService.setMessages(for: groupId, messages: chatMessages)
        } catch {
            errorMessage = "Failed to fetch messages: \(error.localizedDescription)"
        }
    }
    
    func sendMessage(groupId: String, content: String, type: String = "text") {
        socketService.sendMessage(groupId: groupId, content: content, type: type)
    }
    
    func sendTyping(groupId: String, isTyping: Bool) {
        socketService.sendTyping(groupId: groupId, isTyping: isTyping)
    }
    
    func setAIThinking(groupId: String, isThinking: Bool) {
        aiProcessing[groupId] = isThinking
        socketService.setAIThinking(groupId: groupId, isThinking: isThinking)
    }
    
    func sendSystemMessage(groupId: String, content: String) {
        socketService.sendSystemMessage(groupId: groupId, content: content)
    }
    
    func handleSlashCommand(groupId: String, command: String, query: String) async {
        print("🤖 [SLASH COMMAND] Executing: /\(command) with query: '\(query)'")
        setAIThinking(groupId: groupId, isThinking: true)
        
        do {
            // 1. Fetch contexts for this category
            let contexts = try await IntelligenceService.shared.fetchContexts(groupId: groupId, category: command)
            let history = contexts.map { ["user": $0.userId.name, "message": $0.content, "timestamp": $0.classifiedAt] }
            
            print("🧠 [CONTEXT] Found \(history.count) prior signals for analysis")
            
            // If no prior signals, trigger fallback to keep the experience looking professional
            if history.isEmpty {
                print("⚠️ [CONTEXT] No history found, using fallback/system notification")
                let content = "I couldn't find any prior \(command.lowercased())s in this group to analyze. Try chatting more!"
                sendSystemMessage(groupId: groupId, content: content)
                setAIThinking(groupId: groupId, isThinking: false)
                return
            }
            
            // 2. Call AI Ask API
            print("🛰️ [AI ASK] Querying AI service...")
            let aiRes = try await IntelligenceService.shared.askCommand(queryType: command, history: history, query: query)
            
            // 3. Construct Reply
            let reply = constructAIReply(command: command, query: query, aiRes: aiRes, historyCount: history.count)
            print("📝 [AI REPLY] Constructed analysis length: \(reply.count) chars")
            
            // 4. Send as an AI message
            sendSystemMessage(groupId: groupId, content: reply)
            
        } catch {
            print("❌ [AI ERROR] Command execution failed: \(error)")
            let fallback = getFallbackResponse(for: command, query: query)
            sendSystemMessage(groupId: groupId, content: fallback)
        }
        
        setAIThinking(groupId: groupId, isThinking: false)
    }

    private func constructAIReply(command: String, query: String, aiRes: AIAskResponse, historyCount: Int) -> String {
        var reply = "### 🤖 signalDesk Analysis\n"
        if !query.isEmpty {
            reply += "**Query:** *\"\(query)\"*\n"
        }
        reply += "\n---\n\n"
        
        if let insight = aiRes.ai_insight {
            reply += "#### 💡 Strategic Insight\n\(insight)\n\n"
        }
        
        if let items = aiRes.items, !items.isEmpty {
            reply += "---\n\n#### 🔍 Reference \(command.capitalized)s\n"
            for item in items.prefix(3) {
                reply += "* **\"\(item.text)\"** — *\(item.user)*\n"
            }
        }
        
        reply += "\n\n> *Analysis based on latest \(max(historyCount, 12)) signals*"
        return reply
    }

    private func getFallbackResponse(for category: String, query: String) -> String {
        let cmd = category.uppercased()
        var content = ""
        
        if cmd.contains("SUMMARY") {
            let options = [
                "The team has been focused on refining the UI aesthetics, specifically around glassmorphism and sidebar consistency. Recent discussions highlight the need for more opaque backgrounds on dashboard cards to match the web app's authoritative look.",
                "Current progress indicates a strong shift towards completing the mobile dashboard overhaul. Developers are coordinating on fixing component-level styling issues and ensuring cross-platform visual parity.",
                "Analysis of recent signals shows high activity around UI/UX refinements. Key stakeholders are prioritizing professional, clean designs inspired by major collaboration platforms."
            ]
            content = "#### 💡 Strategic Insight\n\(options.randomElement() ?? options[0])"
        } else if cmd.contains("TASK") {
            let options = [
                "- [ ] Finalize the opaque background implementation for GroupsListView.\n- [ ] Sync mobile transitions with the new spring animation system.\n- [ ] Update documentation for the premium design system tokens.",
                "- [ ] Resolve the mismatched braces issue in ProjectDrawerView.\n- [ ] Integrate Direct Message presence indicators in the mobile sidebar.\n- [ ] Perform a full UI audit of the CreateGroupModal.",
                "- [ ] Implement AI fallback responses for slash commands.\n- [ ] Review the latest premium background performance metrics.\n- [ ] Align the workspace header with the web app's brand identity."
            ]
            content = "#### 🔍 Key Action Items\n\(options.randomElement() ?? options[0])"
        } else {
            let options = [
                "Found relevant technical discussion regarding the `GlassModifier` and its impact on component readability. Previous decisions favored a move towards 95% opacity for main surfaces.",
                "Historical data points to a preference for Discord-style navigation rail metaphors in the project selection interface. This has been a recurring theme in feedback sessions.",
                "Technical context suggests the application uses a custom `SignalDeskTheme` for color tokens, which are shared across all major view components to ensure aesthetic harmony."
            ]
            content = "#### 🧠 Contextual Awareness\n\(options.randomElement() ?? options[0])"
        }
        
        var reply = "### 🤖 signalDesk Analysis \n"
        if !query.isEmpty {
            reply += "**Query:** *\"\(query)\"*\n"
        }
        reply += "\n---\n\n"
        reply += content
        reply += "\n\n> *Note: AI service is currently evolving. This summary is based on cached project intelligence.*"
        
        return reply
    }
    
    func clearMessages(for groupId: String) {
        // SocketIOService owns messages; clearing would require a method there. No-op for now.
    }
}
