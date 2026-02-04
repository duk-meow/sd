//
//  SocketIOService.swift
//  sigdesk
//
//  Socket.IO client service for https://signaldesk-6xgf.onrender.com
//

import Foundation
import Combine
import SocketIO

// MARK: - ChatMessage (backend format)

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let groupId: String
    let userId: String
    let userName: String?
    let userAvatar: String?
    let content: String
    let type: String
    let fileUrl: String?
    let fileName: String?
    let fileSize: Int?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case groupId, userId, userName, userAvatar, content, type
        case fileUrl, fileName, fileSize, createdAt
    }

    init(from message: Message) {
        id = message.id
        groupId = message.groupId
        userId = message.userId
        userName = message.userName
        userAvatar = message.userAvatar
        content = message.content
        type = message.type
        fileUrl = message.fileUrl
        fileName = message.fileName
        fileSize = message.fileSize
        createdAt = message.createdAt
    }
}

// MARK: - SocketIOService

@MainActor
final class SocketIOService: ObservableObject {
    static let shared = SocketIOService()

    @Published private(set) var isConnected = false
    @Published private(set) var messages: [String: [ChatMessage]] = [:]
    @Published private(set) var onlineUsers: [String] = []
    @Published private(set) var typingUsers: [String: [String]] = [:]
    @Published private(set) var aiProcessing: [String: Bool] = [:]
    @Published private(set) var lastIntelligenceUpdate: [String: Date] = [:]
    @Published private(set) var lastError: String?

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let socketURLString = "https://signaldesk-6xgf.onrender.com"

    private init() {}

    // MARK: - Connection

    func connect(token: String) {
        guard socket?.status != .connected else { return }

        guard let url = URL(string: socketURLString) else {
            lastError = "Invalid socket URL"
            return
        }

        manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .forceWebsockets(true),
                .reconnects(true),
                .reconnectAttempts(-1),
                .reconnectWait(2),
                .connectParams(["token": token]),
                .extraHeaders(["Authorization": "Bearer \(token)"])
            ]
        )
        socket = manager?.defaultSocket
        setupListeners()
        socket?.connect(withPayload: ["token": token])
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
        messages = [:]
        onlineUsers = []
        typingUsers = [:]
        aiProcessing = [:]
    }

    // MARK: - Listeners

    private func setupListeners() {
        guard let socket = socket else { return }

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in
                self?.isConnected = true
                self?.lastError = nil
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            Task { @MainActor in
                self?.isConnected = false
            }
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            let msg = (data.first as? String) ?? "Connection error"
            Task { @MainActor in
                self?.lastError = msg
                self?.isConnected = false
            }
        }

        socket.on("new-message") { [weak self] data, _ in
            self?.handleNewMessage(data)
        }

        socket.on("users:online") { [weak self] data, _ in
            self?.handleOnlineUsers(data)
        }

        socket.on("user-typing") { [weak self] data, _ in
            self?.handleUserTyping(data)
        }

        socket.on("ai-status") { [weak self] data, _ in
            self?.handleAIStatus(data)
        }

        socket.on("signals-updated") { [weak self] data, _ in
            guard let first = data.first as? [String: Any],
                  let groupId = first["groupId"] as? String else { return }
            Task { @MainActor in
                self?.lastIntelligenceUpdate[groupId] = Date()
                print("📊 Intelligence sync for \(groupId)")
            }
        }

        socket.on("summary-updated") { [weak self] data, _ in
            guard let first = data.first as? [String: Any],
                  let groupId = first["groupId"] as? String else { return }
            Task { @MainActor in
                self?.lastIntelligenceUpdate[groupId] = Date()
                print("📋 Summary updated for \(groupId)")
            }
        }

        socket.on("notification") { [weak self] data, _ in
            Task { @MainActor in
                _ = self
                print("🔔 Notification: \(data)")
            }
        }

        socket.on("error") { [weak self] data, _ in
            let msg = (data.first as? [String: Any]).flatMap { $0["message"] as? String } ?? "Error"
            Task { @MainActor in
                self?.lastError = msg
            }
        }
    }

    private func handleNewMessage(_ data: [Any]) {
        guard let first = data.first,
              let dict = first as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let message = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) else { return }
        Task { @MainActor in
            if messages[message.groupId] == nil {
                messages[message.groupId] = []
            }
            messages[message.groupId]?.append(message)
        }
    }

    private func handleOnlineUsers(_ data: [Any]) {
        guard let list = data.first as? [String] else { return }
        Task { @MainActor in
            onlineUsers = list
        }
    }

    private func handleUserTyping(_ data: [Any]) {
        guard let first = data.first as? [String: Any],
              let groupId = first["groupId"] as? String,
              let userId = first["userId"] as? String,
              let isTyping = first["isTyping"] as? Bool else { return }
        Task { @MainActor in
            if typingUsers[groupId] == nil {
                typingUsers[groupId] = []
            }
            if isTyping {
                if !(typingUsers[groupId]?.contains(userId) ?? false) {
                    typingUsers[groupId]?.append(userId)
                }
            } else {
                typingUsers[groupId]?.removeAll { $0 == userId }
            }
        }
    }

    private func handleAIStatus(_ data: [Any]) {
        guard let first = data.first as? [String: Any],
              let groupId = first["groupId"] as? String,
              let isThinking = first["isThinking"] as? Bool else { return }
        Task { @MainActor in
            aiProcessing[groupId] = isThinking
        }
    }

    // MARK: - Methods (event names match backend)

    func joinProject(projectId: String) {
        socket?.emit("join-project", ["projectId": projectId])
    }

    func leaveProject(projectId: String) {
        socket?.emit("leave-project", ["projectId": projectId])
    }

    func joinGroup(groupId: String) {
        socket?.emit("join-group", ["groupId": groupId])
    }

    func leaveGroup(groupId: String) {
        socket?.emit("leave-group", ["groupId": groupId])
    }

    func sendMessage(groupId: String, content: String, type: String = "text") {
        socket?.emit("send-message", [
            "groupId": groupId,
            "content": content,
            "type": type
        ])
    }

    func sendTyping(groupId: String, isTyping: Bool) {
        socket?.emit("typing", [
            "groupId": groupId,
            "isTyping": isTyping
        ])
    }
    
    func setAIThinking(groupId: String, isThinking: Bool) {
        socket?.emit("ai-thinking", [
            "groupId": groupId,
            "isThinking": isThinking
        ])
    }
    
    func sendSystemMessage(groupId: String, content: String, userName: String = "signalDesk") {
        socket?.emit("send-system-message", [
            "groupId": groupId,
            "userName": userName,
            "content": content
        ])
    }

    // MARK: - Helpers

    /// Seed messages for a group (e.g. after fetching history from API).
    func setMessages(for groupId: String, messages newMessages: [ChatMessage]) {
        var m = messages
        m[groupId] = newMessages
        messages = m
    }

    func getMessages(for groupId: String) -> [ChatMessage] {
        messages[groupId] ?? []
    }

    func getTypingUsers(for groupId: String) -> [String] {
        typingUsers[groupId] ?? []
    }

    func isAIThinking(for groupId: String) -> Bool {
        aiProcessing[groupId] ?? false
    }
}
