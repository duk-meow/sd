//
//  Message.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let groupId: String
    let userId: String
    let userName: String?
    let userAvatar: String?
    let content: String
    let type: String // "text", "image", "file", "system"
    let fileUrl: String?
    let fileName: String?
    let fileSize: Int?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case groupId, userId, userName, userAvatar, content, type
        case fileUrl, fileName, fileSize, createdAt
    }
    
    init(from chatMessage: ChatMessage) {
        id = chatMessage.id
        groupId = chatMessage.groupId
        userId = chatMessage.userId
        userName = chatMessage.userName
        userAvatar = chatMessage.userAvatar
        content = chatMessage.content
        type = chatMessage.type
        fileUrl = chatMessage.fileUrl
        fileName = chatMessage.fileName
        fileSize = chatMessage.fileSize
        createdAt = chatMessage.createdAt
    }
}

struct MessagesResponse: Codable {
    let messages: [Message]
}

struct SendMessageRequest: Codable {
    let content: String
    let type: String
}
