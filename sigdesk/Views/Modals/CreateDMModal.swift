import SwiftUI

struct CreateDMModal: View {
    let projectId: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var groupStore: GroupStore
    @EnvironmentObject var authStore: AuthStore
    
    @State private var members: [ProjectMember] = []
    @State private var searchTerm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredMembers: [ProjectMember] {
        if searchTerm.isEmpty {
            return members
        }
        return members.filter { 
            $0.name.localizedCaseInsensitiveContains(searchTerm) || 
            $0.email.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Message")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                        Text("Start a conversation with a teammate")
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
                .padding(.bottom, 20)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(SignalDeskTheme.textMuted)
                    
                    TextField("Search members...", text: $searchTerm)
                        .foregroundColor(SignalDeskTheme.textPrimary)
                }
                .padding()
                .background(SignalDeskTheme.baseBg.opacity(0.5))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SignalDeskTheme.baseBorder, lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(SignalDeskTheme.accent)
                    Spacer()
                } else if !filteredMembers.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(filteredMembers) { member in
                                memberRow(member)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    Spacer()
                    Text(searchTerm.isEmpty ? "No members found" : "No results for '\(searchTerm)'")
                        .foregroundColor(SignalDeskTheme.textMuted)
                    Spacer()
                }
            }
        }
        .task {
            await loadMembers()
        }
    }
    
    @ViewBuilder
    private func memberRow(_ member: ProjectMember) -> some View {
        Button {
            handleSelectMember(member)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SignalDeskTheme.accent.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(member.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                    Text(member.email)
                        .font(.system(size: 13))
                        .foregroundColor(SignalDeskTheme.textMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SignalDeskTheme.textMuted.opacity(0.5))
            }
            .padding(14)
            .background(SignalDeskTheme.baseSurface.opacity(0.4))
            .glassCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
    
    private func loadMembers() async {
        isLoading = true
        do {
            let project = try await ProjectService.shared.get(id: projectId)
            if let populated = project.populatedMembers {
                // Filter out current user
                self.members = populated.filter { $0.id != authStore.user?.id }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func handleSelectMember(_ member: ProjectMember) {
        guard let currentUser = authStore.user else { return }
        Task {
            await groupStore.createDM(
                projectId: projectId, 
                targetMemberId: member.id, 
                currentUserId: currentUser.id
            )
            dismiss()
        }
    }
}
