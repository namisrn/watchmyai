//
//  Conversations.swift
//  watchmygpt
//
//  Created by Sasan Rafat Nami on 28.03.24.
//

import Foundation
import SwiftData

/// Represents a conversation with a title, creation date, last modification date, and associated messages.
@Model
class Conversations: Identifiable {
    // MARK: - Properties
    
    /// The title of the conversation.
    var title: String
    
    /// The date when the conversation was created.
    var createdDate: Date
    
    /// The date when the conversation was last modified.
    var lastModified: Date
    
    /// The list of messages in the conversation.
    @Relationship var messages: [Chat]
    
    // MARK: - Initializer
    
    /// Initializes a new conversation instance.
    ///
    /// - Parameters:
    ///   - title: The title of the conversation.
    ///   - createdDate: The date the conversation was created.
    ///   - lastModified: The date the conversation was last modified.
    ///   - messages: An array of messages associated with the conversation.
    init(
        title: String,
        createdDate: Date = Date(),
        lastModified: Date = Date(),
        messages: [Chat] = []
    ) {
        self.title = title
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.messages = messages
    }
    
    // MARK: - Helper Methods
    
    /// Updates the modification date to the current date.
    func updateLastModified() {
        self.lastModified = Date()
    }
}

/// Represents an individual chat message within a conversation.
@Model
class Chat: Identifiable {
    // MARK: - Properties
    
    /// The content of the chat message.
    var content: String
    
    /// The sender of the chat message.
    var sender: String
    
    // MARK: - Initializer
    
    /// Initializes a new chat instance.
    ///
    /// - Parameters:
    ///   - content: The text content of the message.
    ///   - sender: The name or identifier of the sender.
    init(content: String, sender: String) {
        self.content = content
        self.sender = sender
    }
}
