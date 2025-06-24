//
//  TodoDetailView.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI
import SwiftData

struct TodoDetailView: View {
    let todo: Todo
    
    var body: some View {
        List {
            Text(todo.title)
            
            Text("Completed: \(todo.isCompleted.description)")
            
            Section {
                LabeledContent("Sync Status") {
                    switch todo.syncStatus {
                    case .synced:
                        Text("Synced")
                    case .pendingCreate:
                        Text("Pending create...")
                    case .pendingUpdate:
                        Text("Pending update...")
                    case .pendingDelete:
                        Text("Pending delete...")
                    case .pendingRecovery:
                        Text("Pending recovery...")
                    case .failed:
                        Text("Failed...")
                    @unknown default:
                        Text("Unknown")
                    }
                    
                }
            }
        }
        .navigationTitle(todo.title)
    }
}

#Preview(traits: .previewData) {
    @Previewable @Query var todos: [Todo]
    TodoDetailView(todo: todos.first!)
}
