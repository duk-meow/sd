import SwiftUI

struct JoinProjectModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    
    @State private var projectId = ""
    @State private var isJoining = false
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Join Workspace")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        Text("Enter a workspace ID to join your team")
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
                
                VStack(spacing: 24) {
                    // Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WORKSPACE ID")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(SignalDeskTheme.textMuted)
                            .tracking(1.5)
                        
                        TextField("Paste ID here...", text: $projectId)
                            .padding()
                            .background(SignalDeskTheme.baseBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
                            )
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.none)
                    }
                    .padding(20)
                    .glassCard(cornerRadius: 20)
                    
                    // Action Button
                    Button {
                        handleJoin()
                    } label: {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(isJoining ? "Joining..." : "Join Workspace")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(projectId.isEmpty ? SignalDeskTheme.accent.opacity(0.3) : SignalDeskTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: SignalDeskTheme.accent.opacity(projectId.isEmpty ? 0 : 0.3), radius: 10, y: 5)
                    }
                    .disabled(projectId.isEmpty || isJoining)
                    
                    if let error = projectStore.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func handleJoin() {
        guard !projectId.isEmpty else { return }
        isJoining = true
        
        Task {
            await projectStore.join(projectId: projectId)
            isJoining = false
            if projectStore.errorMessage == nil {
                dismiss()
            }
        }
    }
}
