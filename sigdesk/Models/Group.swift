//
//  Group.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

/// Backend can return members as [id] (list) or populated [{ _id, name, email, avatar }] (single group).
private struct GroupMemberRef: Codable {
    let id: String
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            id = s
        } else {
            let obj = try c.decode(MemberObject.self)
            id = obj._id
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(id)
    }
}
private struct MemberObject: Codable {
    let _id: String
}

struct Group: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let projectId: String
    let name: String
    let description: String?
    let isDefault: Bool?
    let isPrivate: Bool?
    let type: String? // "channel" or "dm"
    let members: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case projectId, name, description, isDefault, isPrivate, type, members, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectId = try c.decode(String.self, forKey: .projectId)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault)
        isPrivate = try c.decodeIfPresent(Bool.self, forKey: .isPrivate)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        let refs = try c.decode([GroupMemberRef].self, forKey: .members)
        members = refs.map(\.id)
        createdAt = try c.decode(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(projectId, forKey: .projectId)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(isDefault, forKey: .isDefault)
        try c.encodeIfPresent(isPrivate, forKey: .isPrivate)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encode(members, forKey: .members)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct GroupsResponse: Codable {
    let groups: [Group]
}

struct GroupResponse: Codable {
    let group: Group
}
