//
//  Project.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

/// Matches backend populated owner: .populate("owner", "name email avatar")
struct ProjectOwner: Codable, Equatable, Hashable {
    let id: String?
    let name: String?
    let email: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, avatar
    }
}

private struct MemberRef: Codable {
    let id: String
    let name: String?
    let email: String?
    let avatar: String?
    
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            id = s
            name = nil
            email = nil
            avatar = nil
        } else {
            let obj = try c.decode(MemberObject.self)
            id = obj._id
            name = obj.name
            email = obj.email
            avatar = obj.avatar
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(id)
    }
}

private struct MemberObject: Codable {
    let _id: String
    let name: String?
    let email: String?
    let avatar: String?
}

struct ProjectMember: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let email: String
    let avatar: String?
}

struct Project: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let projectId: String
    let name: String
    let description: String?
    let owner: ProjectOwner?
    let members: [String]
    let populatedMembers: [ProjectMember]?
    let accentColor: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case projectId, name, description, owner, members, accentColor, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectId = try c.decode(String.self, forKey: .projectId)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        owner = try c.decodeIfPresent(ProjectOwner.self, forKey: .owner)
        
        let refs = try c.decode([MemberRef].self, forKey: .members)
        members = refs.map(\.id)
        
        let populated = refs.compactMap { ref -> ProjectMember? in
            guard let name = ref.name, let email = ref.email else { return nil }
            return ProjectMember(id: ref.id, name: name, email: email, avatar: ref.avatar)
        }
        populatedMembers = populated.isEmpty ? nil : populated
        
        accentColor = try c.decodeIfPresent(String.self, forKey: .accentColor)
        createdAt = try c.decode(String.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(projectId, forKey: .projectId)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(owner, forKey: .owner)
        try c.encode(members, forKey: .members)
        try c.encodeIfPresent(accentColor, forKey: .accentColor)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct ProjectsResponse: Codable {
    let projects: [Project]
}

struct ProjectResponse: Codable {
    let project: Project
}
