//
//  CreateGroupModal.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct CreateGroupModal: View {
    let projectId: String
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var groupStore: GroupStore
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Channel")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        Text("Set up a new space for your team")
                            .font(.system(size: 14))
                            .foregroundColor(SignalDeskTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form Card
                        VStack(spacing: 20) {
                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CHANNEL NAME")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.5)
                                
                                TextField("e.g. general-discussions", text: $name)
                                    .padding()
                                    .background(SignalDeskTheme.baseBg)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
                                    )
                                    .foregroundColor(SignalDeskTheme.textPrimary)
                            }
                            
                            // Description Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DESCRIPTION (OPTIONAL)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .tracking(1.5)
                                
                                TextField("What is this channel about?", text: $description, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(SignalDeskTheme.baseBg)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
                                    )
                                    .foregroundColor(SignalDeskTheme.textPrimary)
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                        
                        // Action Button
                        Button {
                            handleCreate()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 8)
                                }
                                Text(isCreating ? "Creating..." : "Create Channel")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(name.isEmpty ? SignalDeskTheme.accent.opacity(0.3) : SignalDeskTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: SignalDeskTheme.accent.opacity(name.isEmpty ? 0 : 0.3), radius: 10, y: 5)
                        }
                        .disabled(name.isEmpty || isCreating)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    private func handleCreate() {
        guard !name.isEmpty else { return }
        isCreating = true
        
        Task {
            await groupStore.create(
                projectId: projectId,
                name: name,
                description: description.isEmpty ? nil : description
            )
            isCreating = false
            dismiss()
        }
    }
}
