//
//  ContentView.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStore: AuthStore
    
    var body: some View {
        SwiftUI.Group {
            if authStore.isLoading {
                // Loading state while checking authentication
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            } else if authStore.isAuthenticated {
                // User is authenticated - show dashboard
                DashboardView()
            } else {
                // User is not authenticated - show auth screens
                AuthContainerView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore())
}
