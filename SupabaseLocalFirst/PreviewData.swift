//
//  PreviewData.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/24/25.
//

import SwiftUI
import SwiftData

struct PreviewData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Todo.self, configurations: config)
        
        PreviewData.createPreviewData(into: container.mainContext)
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
    }
    
    static func createPreviewData(into modelContext: ModelContext) {
        Task { @MainActor in
            let previewTodos: [Todo] = Todo.previewTodos
            let previewData: [any PersistentModel] = previewTodos
            previewData.forEach {
                modelContext.insert($0)
            }
            
            try? modelContext.save()
        }
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var previewData: Self = .modifier(PreviewData())
}
