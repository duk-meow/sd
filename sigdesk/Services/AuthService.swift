//
//  AuthService.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(String)
    case decodingError
    case unauthorized
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return error.localizedDescription
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized"
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        }
    }
}

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // Token storage
    @TokenStorage private var token: String?
    
    // Configure URLSession with timeout
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0 // 30 seconds
        config.timeoutIntervalForResource = 60.0 // 60 seconds
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.apiURL)/api/auth/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode == 401 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Invalid email or password")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Login failed")
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store token
            self.token = authResponse.token
            
            return authResponse
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw AuthError.timeout
            }
            throw AuthError.networkError(urlError)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Signup
    func signup(name: String, email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.apiURL)/api/auth/signup") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let body = ["name": name, "email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode == 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Signup failed")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Signup failed")
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store token
            self.token = authResponse.token
            
            return authResponse
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw AuthError.timeout
            }
            throw AuthError.networkError(urlError)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Verify Token
    func verifyToken() async throws -> User {
        guard let token = self.token else {
            throw AuthError.unauthorized
        }
        
        guard let url = URL(string: "\(Config.apiURL)/api/auth/verify") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode == 401 {
                self.token = nil
                throw AuthError.unauthorized
            }
            
            if httpResponse.statusCode != 200 {
                throw AuthError.serverError("Verification failed")
            }
            
            let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)
            return verifyResponse.user
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw AuthError.timeout
            }
            throw AuthError.networkError(urlError)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
    
    // MARK: - Logout
    func logout() {
        self.token = nil
    }
    
    // MARK: - Get Token
    func getToken() -> String? {
        return token
    }
}

// MARK: - Token Storage Property Wrapper
@propertyWrapper
struct TokenStorage {
    private let key = "auth_token"
    
    init(wrappedValue: String? = nil) {
        if let value = wrappedValue {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
    
    var wrappedValue: String? {
        get {
            UserDefaults.standard.string(forKey: key)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
