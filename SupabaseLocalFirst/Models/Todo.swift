//
//  Todo.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/23/25.
//

import Foundation
import SwiftData

@Model
final class Todo: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case title
        case isCompleted
        case createdAt
        case updatedAt
        case deletedAt
    }
    
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
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.identifier = try container.decode(UUID.self, forKey: .identifier)
        self.title = try container.decode(String.self, forKey: .title)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(identifier, forKey: .identifier)
        try container.encode(title, forKey: .title)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(deletedAt, forKey: .deletedAt)
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
