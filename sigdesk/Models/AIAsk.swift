//
//  AIAsk.swift
//  sigdesk
//
//  AI Ask command models
//

import Foundation

struct AIAskRequest: Codable {
    let query_type: String
    let messages: [[String: String]]
    let query: String?
    let context: [String]?
}

struct AIAskResponse: Codable {
    let items: [AIAskItem]?
    let ai_insight: String?
}

struct AIAskItem: Codable {
    let text: String
    let user: String
}
