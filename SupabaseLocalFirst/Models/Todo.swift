//
//  Todo.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import Foundation
import SwiftData

@Model
final class Todo: Identifiable, Hashable {
    @Attribute(.unique) var identifier: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
  
    private var syncStatusRawValue: Int = SyncStatus.pendingCreate.rawValue
    
    var syncStatus: SyncStatus {
        return SyncStatus(rawValue: syncStatusRawValue)!
    }
    
    // Create new todo
    init(title: String) {
        let date = Date()
        
        self.identifier = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = date
        self.updatedAt = date
    }
    
    func setSyncStatus(_ status: SyncStatus) {
        if status == .pendingUpdate {
            self.updatedAt = Date()
        }
        
        if status == .pendingDelete {
            self.deletedAt = Date()
        }
        
        if status == .pendingRecovery {
            self.deletedAt = nil
        }
        
        self.syncStatusRawValue = status.rawValue
    }
}

extension Todo {
    enum SyncStatus: Int {
        case synced
        case pendingCreate
        case pendingUpdate
        case pendingDelete
        case pendingRecovery
        case failed
        
        var image: String {
            switch self {
            case .synced:
                "checkmark.arrow.trianglehead.counterclockwise"
            case .pendingCreate:
                "square.and.arrow.down.badge.clock"
            case .pendingUpdate:
                "square.and.arrow.up.badge.clock"
            case .pendingDelete:
                "arrow.up.trash"
            case .pendingRecovery:
                "clock.arrow.trianglehead.counterclockwise.rotate.90"
            case .failed:
                "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
            }
        }
    }
}

extension Todo {
    static let previewTodos: [Todo] = [
        .init(title: "Buy milk"),
        .init(title: "Learn SwiftUI"),
        .init(title: "Go for a walk")
    ]
}

