//
//  ActionItem.swift
//  sigdesk
//
//  AI-extracted action items model
//

import Foundation

enum TaskPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

struct ActionItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    let task: String
    let assignee: String
    let deadline: String
    let priority: TaskPriority
    let reasoning: String
    
    enum CodingKeys: String, CodingKey {
        case task, assignee, deadline, priority, reasoning
    }
}

struct ActionData: Codable {
    let actions: [ActionItem]
    let summary: String
}
