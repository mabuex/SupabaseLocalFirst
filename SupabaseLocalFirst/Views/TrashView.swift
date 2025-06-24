//
//  TrashView.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI
import SwiftData

struct TrashView: View {
    let client = Supabase.shared.client
    
    @Query private var todos: [Todo]
    
    var onRecover: (Todo) -> Void
    
    init(perform onRecover: @escaping (Todo) -> Void) {
        _todos = Query(filter: #Predicate {
            $0.deletedAt != nil
        }, sort: \.createdAt, order: .reverse, animation: .bouncy)
        
        self.onRecover = onRecover
    }
    
    var body: some View {
        List {
            if todos.isEmpty {
                ContentUnavailableView("Trash is empty", systemImage: "trash.slash")
            } else {
                ForEach(todos) { todo in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(todo.title)
                            
                            Group {
                                Text("Deleted: ") +
                                Text(todo.deletedAt ?? Date(), format: .dateTime)
                            }
                            .foregroundStyle(.red)
                            .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button("Recover", systemImage: "arrow.uturn.backward") {
                            onRecover(todo)
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .navigationTitle("Trash")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TrashView() { _ in }
}
