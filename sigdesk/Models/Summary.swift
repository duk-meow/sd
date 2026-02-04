//
//  Summary.swift
//  sigdesk
//
//  AI-generated conversation summary model
//

import Foundation

struct Summary: Codable {
    let content: String?
    let keyPoints: [String]?
    let updatedAt: String?
}

struct SummaryResponse: Codable {
    let summary: Summary?
}
