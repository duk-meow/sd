//
//  ContextItem.swift
//  sigdesk
//
//  AI-classified context signals model
//

import Foundation

enum ContextCategory: String, Codable, CaseIterable {
    case decision = "DECISION"
    case action = "ACTION"
    case suggestion = "SUGGESTION"
    case question = "QUESTION"
    case constraint = "CONSTRAINT"
    case assumption = "ASSUMPTION"
    
    var displayName: String {
        switch self {
        case .decision: return "Decisions"
        case .action: return "Actions"
        case .suggestion: return "Suggestions"
        case .question: return "Questions"
        case .constraint: return "Constraints"
        case .assumption: return "Assumptions"
        }
    }
}

struct ContextConfidence: Codable {
    let score: Double
    let reason: String
}

struct ContextUser: Codable {
    let id: String
    let name: String
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case avatar
    }
}

struct ContextGroup: Codable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }
}

struct ContextItem: Codable, Identifiable {
    let id: String
    let messageId: String
    let groupId: ContextGroup
    let userId: ContextUser
    let content: String
    let category: [String]
    let confidence: ContextConfidence
    let classifiedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case messageId
        case groupId
        case userId
        case content
        case category
        case confidence
        case classifiedAt
    }
}

struct ContextResponse: Codable {
    let contexts: [ContextItem]
}
