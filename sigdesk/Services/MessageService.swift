//
//  MessageService.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

class MessageService {
    static let shared = MessageService()
    private let api = APIClient.shared
    
    private init() {}
    
    func getByGroup(groupId: String, page: Int = 1, limit: Int = 50) async throws -> [Message] {
        let response: MessagesResponse = try await api.request(
            endpoint: "/api/groups/\(groupId)/messages?page=\(page)&limit=\(limit)"
        )
        return response.messages
    }
}
