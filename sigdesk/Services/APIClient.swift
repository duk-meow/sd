//
//  APIClient.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        baseURL: String = Config.apiURL
    ) async throws -> T {
        let urlString = baseURL.hasSuffix("/") ? "\(baseURL)\(endpoint)" : "\(baseURL)\(endpoint)"
        guard let url = URL(string: urlString) else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(body)
            request.httpBody = data
            
            print("🚀 [API REQUEST] \(method) \(url)")
            if let bodyString = String(data: data, encoding: .utf8) {
                print("📦 Payload: \(bodyString)")
            }
        } else {
            print("🚀 [API REQUEST] \(method) \(url)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }
        
        print("📥 [API RESPONSE] \(httpResponse.statusCode) from \(url)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Body: \(responseString)")
        }
        
        if httpResponse.statusCode == 401 {
            AuthService.shared.logout()
            throw AuthError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthError.serverError(errorResponse.message)
            }
            throw AuthError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
