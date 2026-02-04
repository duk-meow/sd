//
//  CreateProjectModal.swift
//  sigdesk
//
//  Created by KIET9 on 03/02/26.
//

import SwiftUI

struct CreateProjectModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Create Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        print("[CreateProjectModal] Create tapped — name: \"\(name)\"")
                        Task {
                            await projectStore.create(
                                name: name,
                                description: description.isEmpty ? nil : description
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
