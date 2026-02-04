//
//  AuthStore.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthStore: ObservableObject {
    
    // Published properties that views will observe
    @Published var user: User?
    @Published var token: String?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private let socketService = SocketIOService.shared
    
    init() {
        // Check for existing token on initialization
        checkAuthentication()
    }
    
    // MARK: - Check Authentication
    func checkAuthentication() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Check if we have a stored token
            guard let storedToken = authService.getToken() else {
                isAuthenticated = false
                return
            }
            
            do {
                // Verify the token with the backend
                let user = try await authService.verifyToken()
                self.user = user
                self.token = storedToken
                self.isAuthenticated = true
                self.errorMessage = nil
                socketService.connect(token: storedToken)
            } catch {
                // Token is invalid or expired
                self.isAuthenticated = false
                self.user = nil
                self.token = nil
            }
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        do {
            let response = try await authService.login(email: email, password: password)
            
            // Update state
            self.user = response.user
            self.token = response.token
            self.isAuthenticated = true
            self.errorMessage = nil
            socketService.connect(token: response.token)
            
        } catch let error as AuthError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Login failed. Please try again."
        }
    }
    
    // MARK: - Signup
    func signup(name: String, email: String, password: String, confirmPassword: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Validation
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        do {
            let response = try await authService.signup(name: name, email: email, password: password)
            
            // Update state
            self.user = response.user
            self.token = response.token
            self.isAuthenticated = true
            self.errorMessage = nil
            socketService.connect(token: response.token)
            
        } catch let error as AuthError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Signup failed. Please try again."
        }
    }
    
    // MARK: - Logout
    func logout() {
        socketService.disconnect()
        authService.logout()
        self.user = nil
        self.token = nil
        self.isAuthenticated = false
        self.errorMessage = nil
    }
}
