//
//  SocketService.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation
import SocketIO

/// Socket.IO-based socket service. Add the Socket.IO Swift package in Xcode:
/// File → Add Package Dependencies → https://github.com/socketio/socket.io-client-swift
/// then add the "SocketIO" product to the sigdesk target.
class SocketService {
    static let shared = SocketService()
    
    /// Posted on the main queue when the socket has connected (server accepted connection).
    static let didConnectNotification = Notification.Name("SocketServiceDidConnect")
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var messageHandlers: [String: [(Any) -> Void]] = [:]
    private var token: String?
    
    var isConnected: Bool {
        socket?.status == .connected
    }
    
    private init() {}
    
    // MARK: - Connection
    
    /// Socket.IO expects http/https base URL (not ws/wss). Normalize so polling uses HTTPS and ATS is satisfied.
    private static func socketManagerURL(from urlString: String) -> URL? {
        var s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased().hasPrefix("wss://") {
            s = "https://" + s.dropFirst(6)
        } else if s.lowercased().hasPrefix("ws://") {
            s = "http://" + s.dropFirst(5)
        }
        return URL(string: s)
    }
    
    func connect(token: String) {
        guard socket?.status != .connected else { return }
        
        self.token = token
        
        guard let url = SocketService.socketManagerURL(from: Config.socketURL) else {
            print("❌ Invalid socket URL: \(Config.socketURL)")
            return
        }
        
        print("🔌 Socket.IO connecting to \(url.absoluteString)...")
        
        // Backend expects token in handshake; Swift client sends it via connectParams (query) or extraHeaders.
        // Backend should accept token from auth.token or query.token (see backend-socket/server.js).
        manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .connectParams(["token": token]),
                .extraHeaders(["Authorization": "Bearer \(token)"])
            ]
        )
        socket = manager?.defaultSocket
        
        setupSocketHandlers()
        socket?.connect()
    }
    
    private func setupSocketHandlers() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Socket.IO connected")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: SocketService.didConnectNotification, object: nil)
            }
            if let token = self?.token {
                self?.sendAuth(token: token)
            }
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            print("🔌 Socket.IO disconnected")
        }
        
        socket.on(clientEvent: .error) { data, _ in
            if let err = data.first as? String {
                print("❌ Socket.IO error: \(err)")
            }
        }
        
        // Forward any custom event we've registered to our handlers
        for (eventName, handlers) in messageHandlers {
            let name = eventName
            socket.off(name)
            socket.on(name) { [weak self] data, _ in
                let payload: Any = data.isEmpty ? [:] : (data.count == 1 ? data[0] : data)
                DispatchQueue.main.async {
                    self?.messageHandlers[name]?.forEach { $0(payload) }
                }
            }
        }
    }
    
    private func sendAuth(token: String) {
        emit(event: "authenticate", data: ["token": token])
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        print("🔌 Socket disconnected")
    }
    
    // MARK: - Emit Events
    
    func emit(event: String, data: [String: Any]) {
        guard isConnected else {
            print("⚠️ Socket not connected, cannot send: \(event)")
            return
        }
        socket?.emit(event, data)
    }
    
    // MARK: - Listen Events
    
    func on(event: String, handler: @escaping (Any) -> Void) {
        if messageHandlers[event] == nil {
            messageHandlers[event] = []
        }
        messageHandlers[event]?.append(handler)
        // If socket already exists, register this event once (setupSocketHandlers runs at connect)
        guard let socket = socket else { return }
        socket.off(event)
        socket.on(event) { [weak self] data, _ in
            let payload: Any = data.isEmpty ? [:] : (data.count == 1 ? data[0] : data)
            DispatchQueue.main.async {
                self?.messageHandlers[event]?.forEach { $0(payload) }
            }
        }
    }
    
    func off(event: String) {
        messageHandlers[event] = nil
        socket?.off(event)
    }
    
    // MARK: - Convenience Methods
    
    func joinGroup(groupId: String) {
        emit(event: "join-group", data: ["groupId": groupId])
        print("📥 Joined group: \(groupId)")
    }
    
    func leaveGroup(groupId: String) {
        emit(event: "leave-group", data: ["groupId": groupId])
        print("📤 Left group: \(groupId)")
    }
    
    func sendMessage(groupId: String, content: String, type: String = "text") {
        emit(event: "send-message", data: [
            "groupId": groupId,
            "content": content,
            "type": type
        ])
    }
    
    func sendTyping(groupId: String, isTyping: Bool) {
        emit(event: "typing", data: [
            "groupId": groupId,
            "isTyping": isTyping
        ])
    }
    
    func joinProject(projectId: String) {
        emit(event: "join-project", data: ["projectId": projectId])
    }
}
