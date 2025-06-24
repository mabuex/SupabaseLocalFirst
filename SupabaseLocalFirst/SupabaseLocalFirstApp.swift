//
//  SupabaseLocalFirstApp.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import SwiftUI
import SwiftData

@main
struct SupabaseLocalFirstApp: App {
    let container: ModelContainer
    
    @State private var networkMonitor = NetworkMonitor()
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: Todo.self, configurations: config)
        } catch {
            fatalError("Failed to create model container.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(\.isNetworkConnected, networkMonitor.isConnected)
        }
    }
}
