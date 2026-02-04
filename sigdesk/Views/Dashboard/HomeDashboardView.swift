import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var projectStore: ProjectStore
    var onNavigateToWorkspace: () -> Void
    var onNavigateToFeature: (NavigationLevel) -> Void
    
    @State private var searchText = ""
    @State private var selectedTab = "All"
    @State private var isSearching = false
    
    let tabs = ["All", "Work & Studies", "Social"]
    
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return isSearching ? projectStore.projects : []
        }
        
        let query = searchText.lowercased()
        return projectStore.projects.filter {
            $0.name.lowercased().contains(query) ||
            ($0.description?.lowercased().contains(query) ?? false)
        }.sorted { p1, p2 in
            let s1 = p1.name.lowercased().hasPrefix(query)
            let s2 = p2.name.lowercased().hasPrefix(query)
            if s1 != s2 { return s1 }
            return p1.name < p2.name
        }
    }
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) { // Increased spacing
                    // Header
                    HStack {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(SignalDeskTheme.baseSurface)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(SignalDeskTheme.textSecondary)
                                )
                                .overlay(
                                    AsyncImage(url: URL(string: authStore.user?.avatar ?? "")) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        EmptyView()
                                    }
                                        .clipShape(Circle())
                                )
                                .overlay(Circle().stroke(SignalDeskTheme.baseBorder, lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good Morning!")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                Text(authStore.user?.name ?? "User")
                                    .font(.system(size: 22, weight: .bold)) // Bigger name
                                    .foregroundColor(SignalDeskTheme.textPrimary)
                                    .tracking(-0.5)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                        } label: {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(SignalDeskTheme.textSecondary)
                                .padding(12)
                                .background(SignalDeskTheme.baseSurface)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(SignalDeskTheme.baseBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Distinct Hero Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Daily Assistant for")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(SignalDeskTheme.textSecondary)
                            .tracking(-0.5)
                        
                        Text("Smarter Conversations!")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, SignalDeskTheme.accent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(-1.5)
                        
                        Text("AI-powered project chat management that beats 100 Slack daily")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SignalDeskTheme.accent)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // Unified Searchable Workspace Select
                    VStack(spacing: 0) {
                        // The Primary Select Box (Header)
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isSearching.toggle()
                                if !isSearching {
                                    searchText = ""
                                    hideKeyboard()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(SignalDeskTheme.accent.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "square.grid.2x2.fill")
                                        .foregroundColor(SignalDeskTheme.accent)
                                        .font(.system(size: 16, weight: .bold))
                                }
                                
                                Text(projectStore.activeProject?.name ?? "Select your workspace...")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(projectStore.activeProject != nil ? SignalDeskTheme.textPrimary : .white.opacity(0.7))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(SignalDeskTheme.textMuted)
                                    .rotationEffect(.degrees(isSearching ? 180 : 0))
                            }
                            .padding(18)
                        }
                        .buttonStyle(.plain)
                        
                        // Expanded Searchable Area
                        if isSearching {
                            VStack(spacing: 16) {
                                // Integrated Search Input
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(SignalDeskTheme.textMuted)
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    TextField("", text: $searchText, prompt: Text("Search or filter nodes...").foregroundColor(.white.opacity(0.4)))
                                        .foregroundColor(SignalDeskTheme.textPrimary)
                                        .font(.system(size: 16))
                                        .submitLabel(.search)
                                    
                                    if !searchText.isEmpty {
                                        Button {
                                            searchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(SignalDeskTheme.textMuted)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.25))
                                .cornerRadius(14)
                                .padding(.horizontal, 14)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                // Node Suggestions
                                if !filteredProjects.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(searchText.isEmpty ? "SUGGESTED NODES" : "MATCHING NODES")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(SignalDeskTheme.textMuted)
                                            .tracking(1.5)
                                            .padding(.leading, 18)
                                        
                                        VStack(spacing: 8) {
                                            ForEach(filteredProjects) { project in
                                                Button {
                                                    projectStore.setActiveProject(id: project.id)
                                                    withAnimation {
                                                        searchText = ""
                                                        isSearching = false
                                                        hideKeyboard()
                                                    }
                                                    onNavigateToWorkspace()
                                                } label: {
                                                    HStack(spacing: 14) {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color(hex: project.accentColor ?? "7C3AED"))
                                                            .frame(width: 36, height: 36)
                                                            .overlay(
                                                                Text(project.name.prefix(1).uppercased())
                                                                    .font(.system(size: 14, weight: .black))
                                                                    .foregroundColor(.white)
                                                            )
                                                            .shadow(color: Color(hex: project.accentColor ?? "7C3AED").opacity(0.4), radius: 6)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(project.name)
                                                                .font(.system(size: 15, weight: .bold))
                                                                .foregroundColor(SignalDeskTheme.textPrimary)
                                                            Text(project.description ?? "Active Node")
                                                                .font(.system(size: 12))
                                                                .foregroundColor(SignalDeskTheme.textMuted)
                                                                .lineLimit(1)
                                                        }
                                                        Spacer()
                                                        
                                                        if projectStore.activeProjectId == project.id {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(SignalDeskTheme.accent)
                                                        }
                                                    }
                                                    .padding(12)
                                                    .background(projectStore.activeProjectId == project.id ? SignalDeskTheme.accent.opacity(0.1) : Color.white.opacity(0.04))
                                                    .cornerRadius(16)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                    }
                                    .padding(.bottom, 14)
                                }
                            }
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                        }
                    }
                    .background(SignalDeskTheme.baseSurface.opacity(0.85))
                    .glassCard(cornerRadius: 28)
                    .padding(.horizontal, 24)
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tabs, id: \.self) { tab in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    Text(tab)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? .white : SignalDeskTheme.textSecondary)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 22)
                                        .background(selectedTab == tab ? SignalDeskTheme.accent : SignalDeskTheme.baseSurface)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(SignalDeskTheme.baseBorder, lineWidth: selectedTab == tab ? 0 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Premium Banner
                    Button {
                    } label: {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Pro Membership")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                                    .tracking(0.5)
                                Text("Unlock advanced AI features and\nunlimited collaborative nodes.")
                                    .font(.system(size: 13))
                                    .foregroundColor(SignalDeskTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.yellow)
                                    .shadow(color: Color.yellow.opacity(0.5), radius: 8)
                            }
                        }
                        .padding(24)
                        .background(
                            LinearGradient(
                                colors: [SignalDeskTheme.baseSurface, SignalDeskTheme.baseBg],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(SignalDeskTheme.baseBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    
                    // Creative Features Header
                    HStack {
                        Text("Creative features")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(SignalDeskTheme.textPrimary)
                            .tracking(-0.5)
                        
                        Spacer()
                        
                        Button("See All") {}
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SignalDeskTheme.accent)
                    }
                    .padding(.horizontal, 24)
                    
                    // Features Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        FeatureCard(
                            icon: "doc.text.fill",
                            title: "Smart Summary",
                            description: "Instant context analysis",
                            action: { onNavigateToFeature(.summary) }
                        )
                        
                        FeatureCard(
                            icon: "checklist",
                            title: "Action Tasks",
                            description: "Automated work pipeline",
                            action: { onNavigateToFeature(.tasks) }
                        )
                        
                        FeatureCard(
                            icon: "cpu.fill",
                            title: "Context Brain",
                            description: "Neural knowledge base",
                            action: { onNavigateToFeature(.contextStore) }
                        )
                        
                        FeatureCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Team Nodes",
                            description: "Live collaboration sync",
                            action: { onNavigateToWorkspace() }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for bottom bar
                }
            }
            .task {
                await projectStore.fetchProjects()
            }
        }
    }
    
    struct FeatureCard: View {
        let icon: String
        let title: String
        let description: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(SignalDeskTheme.baseSurface)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(SignalDeskTheme.baseBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(SignalDeskTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(SignalDeskTheme.accent)
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SignalDeskTheme.textPrimary)
                        .lineLimit(2)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(SignalDeskTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(height: 180)
                .background(SignalDeskTheme.baseSurface.opacity(0.6))
                .glassCard(cornerRadius: 24)
            }
            .buttonStyle(.plain)
        }
    }
}
