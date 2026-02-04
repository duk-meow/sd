//
//  SignupView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authStore: AuthStore
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch && agreedToTerms
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    
                    Text("Join thousands of teams collaborating on SignalDesk")
                        .font(.system(size: 15))
                        .foregroundColor(SignalDeskTheme.textMuted)
                        .multilineTextAlignment(.center)
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
                
                // Name Field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Full Name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .frame(width: 20)
                        
                        TextField("John Doe", text: $name)
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .name)
                            .disabled(authStore.isLoading)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    .padding(16)
                    .background(SignalDeskTheme.chatInputFieldBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focusedField == .name ? SignalDeskTheme.accent : SignalDeskTheme.baseBorder,
                                lineWidth: focusedField == .name ? 2 : 1
                            )
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
                        
                        TextField("you@company.com", text: $email)
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textPrimary)
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
                    Text("Password")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .frame(width: 20)
                        
                        if showPassword {
                            TextField("At least 8 characters", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .password)
                                .disabled(authStore.isLoading)
                                .onSubmit {
                                    focusedField = .confirmPassword
                                }
                        } else {
                            SecureField("At least 8 characters", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                                .focused($focusedField, equals: .password)
                                .disabled(authStore.isLoading)
                                .onSubmit {
                                    focusedField = .confirmPassword
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
                    
                    // Password strength indicator
                    if !password.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Rectangle()
                                    .fill(passwordStrengthColor(for: index))
                                    .frame(height: 4)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(passwordStrengthText())
                            .font(.system(size: 12))
                            .foregroundColor(passwordStrengthColor(for: 0))
                    }
                }
                
                // Confirm Password Field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Confirm Password")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .frame(width: 20)
                        
                        if showConfirmPassword {
                            TextField("Re-enter password", text: $confirmPassword)
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .confirmPassword)
                                .disabled(authStore.isLoading)
                                .onSubmit {
                                    handleSignup()
                                }
                        } else {
                            SecureField("Re-enter password", text: $confirmPassword)
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                                .focused($focusedField, equals: .confirmPassword)
                                .disabled(authStore.isLoading)
                                .onSubmit {
                                    handleSignup()
                                }
                        }
                        
                        Button {
                            showConfirmPassword.toggle()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                        
                        if !confirmPassword.isEmpty {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(passwordsMatch ? .green : .red)
                        }
                    }
                    .padding(16)
                    .background(SignalDeskTheme.chatInputFieldBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focusedField == .confirmPassword ? SignalDeskTheme.accent : SignalDeskTheme.baseBorder,
                                lineWidth: focusedField == .confirmPassword ? 2 : 1
                            )
                    )
                }
                
                // Terms and conditions
                Button {
                    agreedToTerms.toggle()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(agreedToTerms ? SignalDeskTheme.accent : SignalDeskTheme.baseBorder, lineWidth: 2)
                                .frame(width: 22, height: 22)
                            
                            if agreedToTerms {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SignalDeskTheme.accent)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text("I agree to the")
                                .font(.system(size: 14))
                                .foregroundColor(SignalDeskTheme.textSecondary)
                            
                            Text("Terms")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.accent)
                            
                            Text("and")
                                .font(.system(size: 14))
                                .foregroundColor(SignalDeskTheme.textSecondary)
                            
                            Text("Privacy Policy")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SignalDeskTheme.accent)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                // Signup Button
                Button(action: handleSignup) {
                    HStack(spacing: 12) {
                        if authStore.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Text("Create Account")
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
                            colors: (authStore.isLoading || !isFormValid) ? [Color.gray, Color.gray] : [SignalDeskTheme.accent, Color(hex: "5B21B6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: (authStore.isLoading || !isFormValid) ? .clear : SignalDeskTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(authStore.isLoading || !isFormValid)
                .opacity((authStore.isLoading || !isFormValid) ? 0.6 : 1.0)
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(32)
        }
    }
    
    private func passwordStrength() -> Int {
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { strength += 1 }
        return strength
    }
    
    private func passwordStrengthColor(for index: Int) -> Color {
        let strength = passwordStrength()
        if index < strength {
            switch strength {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            default: return SignalDeskTheme.baseBorder
            }
        }
        return SignalDeskTheme.baseBorder
    }
    
    private func passwordStrengthText() -> String {
        switch passwordStrength() {
        case 1: return "Weak password"
        case 2: return "Fair password"
        case 3: return "Good password"
        case 4: return "Strong password"
        default: return ""
        }
    }
    
    private func handleSignup() {
        focusedField = nil
        Task {
            await authStore.signup(name: name, email: email, password: password, confirmPassword: confirmPassword)
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthStore())
        .background(SignalDeskTheme.baseSurface)
}
