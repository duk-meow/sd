//
//  sigdeskApp.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

@main
struct sigdeskApp: App {
    // Create single instances of all stores
    @StateObject private var authStore = AuthStore()
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var groupStore = GroupStore()
    @StateObject private var chatStore = ChatStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .environmentObject(projectStore)
                .environmentObject(groupStore)
                .environmentObject(chatStore)
        }
    }
}
