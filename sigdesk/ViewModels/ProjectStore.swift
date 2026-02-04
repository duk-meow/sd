//
//  ProjectStore.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var activeProjectId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let projectService = ProjectService.shared
    
    var activeProject: Project? {
        projects.first { $0.id == activeProjectId }
    }
    
    func fetchProjects() async {
        print("[Project] Fetching projects...")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            projects = try await projectService.getAll()
            print("[Project] Fetched \(projects.count) project(s)")
            for p in projects {
                print("[Project]   — id: \(p.id), name: \(p.name)")
            }
            
            // Restore active project from storage or select first
            if let savedId = UserDefaults.standard.string(forKey: "activeProjectId"),
               projects.contains(where: { $0.id == savedId }) {
                activeProjectId = savedId
                print("[Project] Restored active project: \(savedId)")
            } else if let first = projects.first {
                setActiveProject(id: first.id)
                print("[Project] Set active project: \(first.id) (\(first.name))")
            }
        } catch {
            print("[Project] Fetch failed: \(error.localizedDescription)")
            errorMessage = "Failed to fetch projects: \(error.localizedDescription)"
        }
    }
    
    func create(name: String, description: String?) async {
        print("[Project] Creating project: name=\"\(name)\", description=\(description ?? "nil")")
        do {
            let project = try await projectService.create(name: name, description: description)
            print("[Project] Created successfully: id=\(project.id), name=\(project.name)")
            projects.append(project)
            setActiveProject(id: project.id)
        } catch {
            print("[Project] Create failed: \(error.localizedDescription)")
            errorMessage = "Failed to create project: \(error.localizedDescription)"
        }
    }
    
    func update(id: String, name: String?, description: String?) async {
        do {
            let updated = try await projectService.update(id: id, name: name, description: description)
            if let index = projects.firstIndex(where: { $0.id == id }) {
                projects[index] = updated
            }
        } catch {
            errorMessage = "Failed to update project: \(error.localizedDescription)"
        }
    }
    
    func delete(id: String) async {
        do {
            try await projectService.delete(id: id)
            projects.removeAll { $0.id == id }
            if activeProjectId == id {
                activeProjectId = projects.first?.id
            }
        } catch {
            errorMessage = "Failed to delete project: \(error.localizedDescription)"
        }
    }
    
    func join(projectId: String) async {
        do {
            let project = try await projectService.join(projectId: projectId)
            projects.append(project)
            setActiveProject(id: project.id)
        } catch {
            errorMessage = "Failed to join project: \(error.localizedDescription)"
        }
    }
    
    func setActiveProject(id: String) {
        activeProjectId = id
        UserDefaults.standard.set(id, forKey: "activeProjectId")
    }
}
