//
//  AddEditTodoView.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI
import SwiftData

struct AddEditTodoView: View {
    enum TodoAction {
        case create(Todo)
        case update(Todo)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var todo: Todo?
    
    @State private var title: String
    @State private var isCompleted: Bool
    
    var action: (TodoAction) -> Void
    
    init(todo: Todo? = nil, perform action: @escaping (TodoAction) -> Void) {
        self.todo = todo
        
        _title = State(initialValue: todo?.title ?? "")
        _isCompleted = State(initialValue: todo?.isCompleted ?? false)
        
        self.action = action
    }
    
    var body: some View {
        Form {
            TextField("Enter a title...", text: $title, axis: .vertical)
            
            if isUpdate {
                Section {
                    Toggle("Completed", isOn: $isCompleted)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onDone){
                    Text("Done")
                }
            }
        }
        .navigationTitle(isUpdate ? "Update" : "Create")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func onDone() {
        if title.isEmpty {
            dismiss()
        } else {
            isUpdate ? updateTodo() : createTodo()
            dismiss()
        }
    }
    
    var isUpdate: Bool {
        todo != nil
    }
    
    func createTodo() {
        let newTodo = Todo(title: title)
        action(.create(newTodo))
    }
    
    func updateTodo() {
        if let todo {
            todo.title = title
            todo.isCompleted = isCompleted
            action(.update(todo))
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @Query var todos: [Todo]
    AddEditTodoView(todo: todos.first!) { _ in }
}


