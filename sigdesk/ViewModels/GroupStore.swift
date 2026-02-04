//
//  GroupStore.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GroupStore: ObservableObject {
    @Published var groups: [Group] = []
    @Published var activeGroupId: String?
    @Published var onlineUsers: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let groupService = GroupService.shared
    private let socketService = SocketIOService.shared
    
    var activeGroup: Group? {
        groups.first { $0.id == activeGroupId }
    }
    
    func getGroupsByProject(projectId: String) -> [Group] {
        groups.filter { $0.projectId == projectId }
    }
    
    func fetchGroups(projectId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let fetchedGroups = try await groupService.getByProject(projectId: projectId)
            
            // Replace groups for this project
            groups.removeAll { $0.projectId == projectId }
            groups.append(contentsOf: fetchedGroups)
            
            // Auto-select first group or "general"
            if activeGroupId == nil || !fetchedGroups.contains(where: { $0.id == activeGroupId }) {
                if let general = fetchedGroups.first(where: { $0.name.lowercased() == "general" }) {
                    setActiveGroup(id: general.id)
                } else if let first = fetchedGroups.first {
                    setActiveGroup(id: first.id)
                }
            }
        } catch {
            errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
        }
    }
    
    func create(projectId: String, name: String, description: String?) async {
        do {
            let group = try await groupService.create(projectId: projectId, name: name, description: description)
            groups.append(group)
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
        }
    }
    
    func createDM(projectId: String, targetMemberId: String, currentUserId: String) async {
        // Check if DM already exists
        if let existing = groups.first(where: { g in
            g.type == "dm" && g.members.contains(targetMemberId) && g.members.contains(currentUserId)
        }) {
            setActiveGroup(id: existing.id)
            return
        }
        
        do {
            let dmName = "dm-\(Int(Date().timeIntervalSince1970))"
            let group = try await groupService.create(
                projectId: projectId,
                name: dmName,
                description: "Direct Message",
                type: "dm",
                isPrivate: true,
                members: [currentUserId, targetMemberId]
            )
            groups.append(group)
            setActiveGroup(id: group.id)
        } catch {
            errorMessage = "Failed to create DM: \(error.localizedDescription)"
        }
    }
    
    func update(id: String, name: String?, description: String?) async {
        do {
            let updated = try await groupService.update(groupId: id, name: name, description: description)
            if let index = groups.firstIndex(where: { $0.id == id }) {
                groups[index] = updated
            }
        } catch {
            errorMessage = "Failed to update group: \(error.localizedDescription)"
        }
    }
    
    func delete(id: String) async {
        do {
            try await groupService.delete(groupId: id)
            groups.removeAll { $0.id == id }
            if activeGroupId == id {
                activeGroupId = groups.first?.id
            }
        } catch {
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
        }
    }
    
    func setActiveGroup(id: String) {
        // Leave previous group
        if let previousId = activeGroupId {
            socketService.leaveGroup(groupId: previousId)
        }
        
        // Join new group
        activeGroupId = id
        socketService.joinGroup(groupId: id)
    }
}
