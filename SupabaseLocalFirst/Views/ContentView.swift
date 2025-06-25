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
                                    await deleteTodo(todo)
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
                        await recoverTodo(todo)
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
                        await createTodo(todo)
                    case .update(let todo):
                        await updateTodo(todo)
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
                    await createTodo(localTodo)
                case .pendingUpdate:
                    await updateTodo(localTodo)
                case .pendingDelete:
                    await deleteTodo(localTodo)
                case .pendingRecovery:
                    await recoverTodo(localTodo)
                case .synced:
                    break
                case .failed:
                    await resolveTodo(localTodo)
                }
            }
     
            isSyncing = false
        } catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    // Delete the local todos from storage after a given time period
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
        return try await client
            .from("todos")
            .select()
            .is("deleted_at", value: nil)
            .execute()
            .value
    }
    
    // Fetch single remote todo from supabase
    func fetchRemoteTodo(_ identifier: UUID) async -> Todo? {
        return try? await client
            .from("todos")
            .select()
            .eq("id", value: identifier)
            .single()
            .execute()
            .value
    }
    
    // Create new remote todo
    func createTodo(_ todo: Todo) async {
        todo.setSyncStatus(.pendingCreate)
        modelContext.insert(todo)
        
        guard isNetworkConnected else { return }
        
        do {
            _ = try await client
                .from("todos")
                .insert(todo, returning: .representation)
                .single()
                .execute()
                .value as Todo
            
            todo.setSyncStatus(.synced)
        } catch {
            todo.setSyncStatus(.failed)
            errorMessage = error.localizedDescription
        }
    }
    
    // Update todo
    func updateTodo(_ todo: Todo) async {
        guard todo.syncStatus == .synced || todo.syncStatus == .pendingUpdate else { return }
          
        todo.setSyncStatus(.pendingUpdate)
        
        guard isNetworkConnected else { return }
        
        do {
            _ = try await client
                .from("todos")
                .update(todo, returning: .representation)
                .eq("id", value: todo.identifier)
                .single()
                .execute()
                .value as Todo
            
            todo.setSyncStatus(.synced)
        } catch {
            todo.setSyncStatus(.failed)
            errorMessage = error.localizedDescription
        }
    }
    
    // Delete todo
    func deleteTodo(_ todo: Todo) async {
        todo.setSyncStatus(.pendingDelete)
        
        guard isNetworkConnected else { return }
        
        do {
            _ = try await client
                .from("todos")
                .update(["deleted_at": todo.deletedAt], returning: .representation)
                .eq("id", value: todo.identifier)
                .single()
                .execute()
                .value as Todo
            
            todo.setSyncStatus(.synced)
        } catch {
            todo.setSyncStatus(.failed)
            errorMessage = error.localizedDescription
        }
    }
    
    // Recover todo
    func recoverTodo(_ todo: Todo) async {
        guard todo.syncStatus == .synced || todo.syncStatus == .pendingDelete || todo.syncStatus == .failed else { return }
        
        todo.setSyncStatus(.pendingRecovery)
        
        guard isNetworkConnected else { return }
        
        do {
            _ = try await client
                .from("todos")
                .update(todo, returning: .representation)
                .eq("id", value: todo.identifier)
                .single()
                .execute()
                .value as Todo
            
            todo.setSyncStatus(.synced)
        } catch {
            todo.setSyncStatus(.failed)
            errorMessage = error.localizedDescription
        }
    }
    
    // Resolve todo
    func resolveTodo(_ todo: Todo) async {
        guard isNetworkConnected, todo.syncStatus == .failed else { return }
 
        // check if remote file exists
        if let remoteTodo = await fetchRemoteTodo(todo.identifier) {
            // if the remote todo is newer update local todo
            if remoteTodo.updatedAt > todo.updatedAt {
                todo.title = remoteTodo.title
                todo.isCompleted = remoteTodo.isCompleted
                todo.updatedAt = remoteTodo.updatedAt
                todo.setSyncStatus(.synced)
                return
            } else {
                todo.setSyncStatus(.pendingUpdate)
                await updateTodo(todo)
            }
        } else {
            await createTodo(todo)
        }
    }
}
