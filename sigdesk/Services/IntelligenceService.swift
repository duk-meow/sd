//
//  IntelligenceService.swift
//  sigdesk
//

import Foundation

class IntelligenceService {
    static let shared = IntelligenceService()
    private init() {}
    
    // Fetch summary for a specific group
    func fetchSummary(groupId: String) async throws -> Summary? {
        let response: SummaryResponse = try await APIClient.shared.request(endpoint: "/api/summary?groupId=\(groupId)")
        return response.summary
    }
    
    // Extract action items/tasks for a specific group
    func extractTasks(groupId: String) async throws -> ActionData {
        // First get recent messages for the group
        let messagesResponse: MessagesResponse = try await APIClient.shared.request(endpoint: "/api/groups/\(groupId)/messages?limit=50")
        
        let formattedMessages = messagesResponse.messages.map { m in
            return [
                "user": m.userName ?? "Member",
                "message": m.content,
                "timestamp": m.createdAt
            ]
        }
        
        // Get prior actions for context (Signals of category ACTION)
        let contextsResponse: ContextResponse = try await APIClient.shared.request(endpoint: "/api/context?category=ACTION&groupId=\(groupId)&limit=20")
        let priorActions = contextsResponse.contexts.map { $0.content }
        
        let body: [String: AnyEncodable] = [
            "messages": AnyEncodable(formattedMessages),
            "context": AnyEncodable(["prior_actions": priorActions])
        ]
        
        return try await APIClient.shared.request(
            endpoint: "/ai/action",
            method: "POST",
            body: body,
            baseURL: Config.aiServiceURL
        )
    }
    
    // Fetch all context signals
    func fetchContexts(groupId: String? = nil, category: String? = nil) async throws -> [ContextItem] {
        var params: [String] = []
        
        if let category = category {
            params.append("category=\(category)")
        }
        if let groupId = groupId {
            params.append("groupId=\(groupId)")
        }
        
        let query = params.isEmpty ? "" : "?" + params.joined(separator: "&")
        let endpoint = "/api/context" + query
        
        let response: ContextResponse = try await APIClient.shared.request(endpoint: endpoint)
        return response.contexts
    }
    
    // AI Ask command handler
    func askCommand(queryType: String, history: [[String: Any]], query: String) async throws -> AIAskResponse {
        // Construct payload exactly as React does
        let body: [String: AnyEncodable] = [
            "query_type": AnyEncodable(queryType),
            "messages": AnyEncodable(history),
            "query": AnyEncodable(query)
        ]
        
        return try await APIClient.shared.request(
            endpoint: "/ai/ask",
            method: "POST",
            body: body,
            baseURL: Config.aiServiceURL
        )
    }
}

// Helper to encode mixed types in body
struct AnyEncodable: Encodable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String {
            try container.encode(str)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyEncodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyEncodable($0) })
        }
    }
}
