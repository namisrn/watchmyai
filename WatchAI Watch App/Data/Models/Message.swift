//
//  Message.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 04.01.25.
//

import Foundation

/// Mögliche Rollen einer Chat-Nachricht.
enum SenderRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

/// Darstellung einer Chat-Nachricht (für das ViewModel/UI).
struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let role: SenderRole
    let content: String
    let createdAt: Date
    var isRead: Bool
    
    init(id: UUID = UUID(), role: SenderRole, content: String, createdAt: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
