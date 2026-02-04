//
//  AuthContainerView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct AuthContainerView: View {
    @State private var showingLogin = true
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo and branding
                    VStack(spacing: 10) {
                       
                        
                        VStack(spacing: 0) {
                            Text("SignalDesk")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                            
                            Text("Team collaboration made simple")
                                .font(.system(size: 15))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Auth Form Card
                    VStack(spacing: 0) {
                        // Tab switcher
                        HStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingLogin = true
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: showingLogin ? .semibold : .medium))
                                        .foregroundColor(showingLogin ? SignalDeskTheme.textPrimary : SignalDeskTheme.textMuted)
                                    
                                    Rectangle()
                                        .fill(showingLogin ? SignalDeskTheme.accent : Color.clear)
                                        .frame(height: 3)
                                        .clipShape(Capsule())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingLogin = false
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text("Sign Up")
                                        .font(.system(size: 16, weight: !showingLogin ? .semibold : .medium))
                                        .foregroundColor(!showingLogin ? SignalDeskTheme.textPrimary : SignalDeskTheme.textMuted)
                                    
                                    Rectangle()
                                        .fill(!showingLogin ? SignalDeskTheme.accent : Color.clear)
                                        .frame(height: 3)
                                        .clipShape(Capsule())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(SignalDeskTheme.baseSurface)
                        
                        Divider()
                            .background(SignalDeskTheme.baseBorder)
                        
                        // Form content
                        if showingLogin {
                            LoginView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            SignupView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .glassCard(cornerRadius: 24)
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                    .padding(.horizontal, 24)
                    
                    // Footer
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SignalDeskTheme.textMuted)
                            Text("Your data is encrypted and secure")
                                .font(.system(size: 13))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                        
                        HStack(spacing: 16) {
                            Button("Privacy Policy") {}
                                .font(.system(size: 13))
                                .foregroundColor(SignalDeskTheme.textMuted)
                            
                            Text("•")
                                .foregroundColor(SignalDeskTheme.textMuted)
                            
                            Button("Terms of Service") {}
                                .font(.system(size: 13))
                                .foregroundColor(SignalDeskTheme.textMuted)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthStore())
}
