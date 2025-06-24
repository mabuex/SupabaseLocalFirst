//
//  ContentView.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let client = Supabase.shared.client
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    
    @Query private var todos: [Todo]
    
    @State private var selection: Todo?
    @State private var showAddTodoSheet = false
    @State private var errorMessage: String?
    @State private var editTodo: Todo?
    @State private var isSyncing = false
    
    init() {
        _todos = Query(filter: #Predicate {
            $0.deletedAt == nil
        }, sort: \.createdAt, order: .reverse, animation: .bouncy)
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if isSyncing {
                    ProgressView()
                        .controlSize(.large)
                } else if todos.isEmpty {
                    ContentUnavailableView("No Todos", systemImage: "list.bullet", description: Text("Tap the \(Image(systemName: "plus.circle.fill")) icon to add a new todo"))
                } else {
                    ForEach(todos) { todo in
                        NavigationLink(value: todo) {
                            HStack {
                                if todo.isCompleted {
                                    Image(systemName: "checkmark")
                                }
                                
                                Text(todo.title)
                                
                                Spacer()
                                
                                Image(systemName: todo.syncStatus.image)
                            }
                        }
                        .swipeActions(allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                Task {
                                    // Delete
                                }
                            }
                            
                            Button("Edit", systemImage: "pencil") {
                                editTodo = todo
                            }
                        }
                    }
                }
            }
            .toolbar {
                toolbarContent
            }
            .navigationTitle("Todos")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            if let selection {
                NavigationStack {
                    TodoDetailView(todo: selection)
                }
            }
        }
        .sheet(item: $editTodo) { todo in
            sheetContent(todo)
        }
        .sheet(isPresented: $showAddTodoSheet) {
            sheetContent()
        }
        .onAppear {
            deleteTodos()
        }
        .task {
            await syncTodos()
        }
        .errorAlert(errorMessage: $errorMessage)
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Sync", systemImage: "arrow.trianglehead.2.counterclockwise") {
                if isNetworkConnected {
                    Task {
                        await syncTodos()
                    }
                } else {
                    errorMessage = "No internet connection."
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Add New Todo", systemImage: "plus.circle.fill") {
                showAddTodoSheet.toggle()
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                TrashView { todo in
                    Task {
                        
                    }
                }
            } label: {
                Label("Trash", systemImage: "trash.fill")
            }
        }
    }
    
    func sheetContent(_ todo: Todo? = nil) -> some View {
        NavigationStack {
            AddEditTodoView(todo: todo) { action in
                Task {
                    switch action {
                    case .create(let todo):
                        print(todo)
                    case .update(let todo):
                        print(todo)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    func syncTodos() async {
        guard !isSyncing, isNetworkConnected else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let remoteTodos = try await fetchRemoteTodos()
            
            // Sync local todos
            for remoteTodo in remoteTodos {
                if let localTodo = todos.first(where: { $0.identifier == remoteTodo.identifier }) {
                    // Update
                    if remoteTodo.updatedAt > localTodo.updatedAt {
                        localTodo.title = remoteTodo.title
                        localTodo.isCompleted = remoteTodo.isCompleted
                        localTodo.updatedAt = remoteTodo.updatedAt
                        localTodo.setSyncStatus(.synced)
                    }
                } else {
                    // New
                    remoteTodo.setSyncStatus(.synced)
                    modelContext.insert(remoteTodo)
                }
            }
            
            // Sync remote todos
            for localTodo in todos where localTodo.syncStatus != .synced {
                switch localTodo.syncStatus {
                case .pendingCreate:
                    print(localTodo)
                case .pendingUpdate:
                    print(localTodo)
                case .pendingDelete:
                    print(localTodo)
                case .pendingRecovery:
                    print(localTodo)
                case .synced:
                    print(localTodo)
                case .failed:
                    print(localTodo)
                }
            }
     
            isSyncing = false
        } catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    // Delete the local todos from storage after a time period
    func deleteTodos() {
        // Calculate the cutoff date: 5 days ago
        let deleteDate = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        
        // Fetch todos that were deleted more than 5 days ago
        var descriptor = FetchDescriptor<Todo>()
        descriptor.predicate = #Predicate {
            $0.deletedAt != nil && $0.deletedAt! < deleteDate
        }
        
        // Permanently delete them from the local store
        if let deletedTodos = try? modelContext.fetch(descriptor) {
            deletedTodos.forEach {
                modelContext.delete($0)
            }
        }
    }
}

// MARK: - Remote
extension ContentView {
    // Fetch all the remote todos from supabase
    func fetchRemoteTodos() async throws -> [Todo] {
        return []
    }
}

