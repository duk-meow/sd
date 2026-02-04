//
//  LoginView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                
                Text("Sign in to continue to your workspace")
                    .font(.system(size: 15))
                    .foregroundColor(SignalDeskTheme.textMuted)
            }
            .padding(.top, 8)
            
            // Error Message
            if let errorMessage = authStore.errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 10) {
                Text("Email Address")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SignalDeskTheme.textSecondary)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .frame(width: 20)
                    
                    TextField(
                        "",
                        text: $email,
                        prompt: Text("Email here...")
                    )
                    .font(.system(size: 16))
                    .foregroundColor(.white)   // text color when typing
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .disabled(authStore.isLoading)
                    .onSubmit {
                        focusedField = .password
                    }

                }
                .padding(16)
                .background(SignalDeskTheme.chatInputFieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .email ? SignalDeskTheme.accent : SignalDeskTheme.baseBorder,
                            lineWidth: focusedField == .email ? 2 : 1
                        )
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Password")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                    
                    Spacer()
                    
                    Button("Forgot?") {
                        // TODO: Handle forgot password
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SignalDeskTheme.accent)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .password)
                            .disabled(authStore.isLoading)
                            .onSubmit {
                                handleLogin()
                            }
                    } else {
                        SecureField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .focused($focusedField, equals: .password)
                            .disabled(authStore.isLoading)
                            .onSubmit {
                                handleLogin()
                            }
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(SignalDeskTheme.chatInputFieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .password ? SignalDeskTheme.accent : SignalDeskTheme.baseBorder,
                            lineWidth: focusedField == .password ? 2 : 1
                        )
                )
            }
            
            // Login Button
            Button(action: handleLogin) {
                HStack(spacing: 12) {
                    if authStore.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: authStore.isLoading ? [Color.gray, Color.gray] : [SignalDeskTheme.accent, Color(hex: "5B21B6")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: authStore.isLoading ? .clear : SignalDeskTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .disabled(authStore.isLoading || email.isEmpty || password.isEmpty)
            .opacity((authStore.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            // Divider with text
            HStack(spacing: 16) {
                Rectangle()
                    .fill(SignalDeskTheme.baseBorder)
                    .frame(height: 1)
                
                Text("or")
                    .font(.system(size: 13))
                    .foregroundColor(SignalDeskTheme.textMuted)
                
                Rectangle()
                    .fill(SignalDeskTheme.baseBorder)
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Social login buttons
            VStack(spacing: 12) {
                SocialLoginButton(
                    icon: "apple.logo",
                    title: "Continue with Apple",
                    action: { /* TODO */ }
                )
                
                SocialLoginButton(
                    icon: "g.circle.fill",
                    title: "Continue with Google",
                    action: { /* TODO */ }
                )
            }
        }
        .padding(32)
    }
    
    private func handleLogin() {
        focusedField = nil
        Task {
            await authStore.login(email: email, password: password)
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SignalDeskTheme.textPrimary)
                
                Spacer()
            }
            .padding(16)
            .background(SignalDeskTheme.whiteOver5)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
        .background(SignalDeskTheme.baseSurface)
}
