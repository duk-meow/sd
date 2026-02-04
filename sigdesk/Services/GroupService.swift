//
//  GroupService.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

class GroupService {
    static let shared = GroupService()
    private let api = APIClient.shared
    
    private init() {}
    
    func getByProject(projectId: String) async throws -> [Group] {
        let response: GroupsResponse = try await api.request(
            endpoint: "/api/projects/\(projectId)/groups"
        )
        return response.groups
    }
    
    func create(projectId: String, name: String, description: String?, type: String? = "channel", isPrivate: Bool? = false, members: [String]? = nil) async throws -> Group {
        struct CreateRequest: Codable {
            let name: String
            let description: String?
            let type: String?
            let isPrivate: Bool?
            let members: [String]?
        }
        
        let response: GroupResponse = try await api.request(
            endpoint: "/api/projects/\(projectId)/groups",
            method: "POST",
            body: CreateRequest(name: name, description: description, type: type, isPrivate: isPrivate, members: members)
        )
        return response.group
    }
    
    func update(groupId: String, name: String?, description: String?) async throws -> Group {
        struct UpdateRequest: Codable {
            let name: String?
            let description: String?
        }
        
        let response: GroupResponse = try await api.request(
            endpoint: "/api/groups/\(groupId)",
            method: "PUT",
            body: UpdateRequest(name: name, description: description)
        )
        return response.group
    }
    
    func delete(groupId: String) async throws {
        struct MessageResponse: Codable { let message: String? }
        let _: MessageResponse = try await api.request(
            endpoint: "/api/groups/\(groupId)",
            method: "DELETE"
        )
    }
}
