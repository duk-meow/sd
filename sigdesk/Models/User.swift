//
//  User.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatar
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct VerifyResponse: Codable {
    let user: User
}

struct ErrorResponse: Codable {
    let message: String
}
