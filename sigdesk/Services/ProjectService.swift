//
//  ProjectService.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

class ProjectService {
    static let shared = ProjectService()
    private let api = APIClient.shared
    
    private init() {}
    
    func getAll() async throws -> [Project] {
        print("[ProjectService] GET /api/projects")
        let response: ProjectsResponse = try await api.request(endpoint: "/api/projects")
        print("[ProjectService] Fetched \(response.projects.count) project(s)")
        return response.projects
    }
    
    func create(name: String, description: String?) async throws -> Project {
        struct CreateRequest: Codable {
            let name: String
            let description: String?
        }
        
        print("[ProjectService] POST /api/projects — name: \"\(name)\"")
        let response: ProjectResponse = try await api.request(
            endpoint: "/api/projects",
            method: "POST",
            body: CreateRequest(name: name, description: description)
        )
        let project = response.project
        print("[ProjectService] Project created — id: \(project.id), name: \(project.name)")
        return project
    }
    
    func update(id: String, name: String?, description: String?) async throws -> Project {
        struct UpdateRequest: Codable {
            let name: String?
            let description: String?
        }
        
        let response: ProjectResponse = try await api.request(
            endpoint: "/api/projects/\(id)",
            method: "PUT",
            body: UpdateRequest(name: name, description: description)
        )
        return response.project
    }
    
    func delete(id: String) async throws {
        let _: ProjectResponse = try await api.request(
            endpoint: "/api/projects/\(id)",
            method: "DELETE"
        )
    }
    
    func get(id: String) async throws -> Project {
        let response: ProjectResponse = try await api.request(
            endpoint: "/api/projects/\(id)"
        )
        return response.project
    }
    
    func join(projectId: String) async throws -> Project {
        struct JoinRequest: Codable {
            let projectId: String
        }
        
        let response: ProjectResponse = try await api.request(
            endpoint: "/api/projects/join",
            method: "POST",
            body: JoinRequest(projectId: projectId)
        )
        return response.project
    }
}
