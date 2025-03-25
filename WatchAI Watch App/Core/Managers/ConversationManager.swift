//
//  ConversationManager.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 18.03.25.
//

import Foundation
import SwiftData
import OSLog

/// Manager for persistence operations with conversations
@MainActor
final class ConversationManager {
    // Singleton instance for easy access
    static let shared = ConversationManager()
    
    // Logger for diagnostic information
    private let logger = Logger()
    
    private init() {}
    
    /// Saves a conversation with the specified messages
    /// - Parameters:
    ///   - messages: The messages to save
    ///   - context: The SwiftData context
    ///   - currentConversation: Optional existing conversation to update
    /// - Returns: The saved conversation
    func saveConversation(
        messages: [Message],
        context: ModelContext,
        currentConversation: Conversations?
    ) async -> Conversations {
        // If no conversation exists yet, create one
        var conversation = currentConversation
        if conversation == nil {
            let title = await generateTitle(from: messages)
            let newConversation = Conversations(
                title: title,
                createdDate: Date(),
                lastModified: Date(),
                messages: []
            )
            conversation = newConversation
            context.insert(newConversation)
        }
        
        // Ensure we have a conversation
        guard let conversation = conversation else {
            fatalError("Could not create or access conversation")
        }
        
        // Update the conversation
        conversation.updateLastModified()
        conversation.title = await generateTitle(from: messages)
        
        // First remove existing message connections
        conversation.messages.removeAll()
        
        // Add each message to the conversation
        for vmMessage in messages.sorted(by: { $0.createdAt < $1.createdAt }) {
            let chatMessage = Chat(
                content: vmMessage.content,
                sender: vmMessage.role.rawValue,
                createdAt: vmMessage.createdAt
            )
            conversation.messages.append(chatMessage)
            context.insert(chatMessage)
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving conversation: \(error)")
        }
        
        return conversation
    }
    
    /// Loads all conversations from the context
    /// - Parameter context: The SwiftData context
    /// - Returns: Array of conversations
    func loadConversations(context: ModelContext) async throws -> [Conversations] {
        let descriptor = FetchDescriptor<Conversations>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Deletes a conversation from the context
    /// - Parameters:
    ///   - conversation: The conversation to delete
    ///   - context: The SwiftData context
    func deleteConversation(_ conversation: Conversations, context: ModelContext) async throws {
        context.delete(conversation)
        try context.save()
    }
    
    /// Generates a title for the conversation based on the first message
    /// - Parameter messages: The messages
    /// - Returns: The generated title
    private func generateTitle(from messages: [Message]) async -> String {
        let maxTitleLength = 50
        let baseTitle = messages.first?.content ?? "New Conversation"
        return String(baseTitle.prefix(maxTitleLength))
    }
    
    // Add conversation cleanup and optimization
    func cleanupOldConversations(context: ModelContext) {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<Conversations>(
            predicate: #Predicate<Conversations> { conversation in
                conversation.lastModified < thirtyDaysAgo
            }
        )
        
        do {
            let oldConversations = try context.fetch(descriptor)
            for conversation in oldConversations {
                context.delete(conversation)
            }
            try context.save()
            os_log("Cleaned up %d old conversations", log: OSLog.default, type: .info, oldConversations.count)
        } catch {
            os_log("Error cleaning up old conversations: %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
    
    // Add conversation export functionality
    func exportConversation(_ conversation: Conversations) -> String {
        var exportText = "Conversation: \(conversation.title)\n"
        exportText += "Date: \(conversation.createdDate)\n\n"
        
        for message in conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }) {
            exportText += "\(message.sender): \(message.content)\n"
            exportText += "Time: \(message.createdAt)\n\n"
        }
        
        return exportText
    }
    
    /// Searches conversations for a given query string
    /// - Parameters:
    ///   - query: The search query
    ///   - context: The SwiftData context
    /// - Returns: Array of matching conversations
    func searchConversations(query: String, context: ModelContext) -> [Conversations] {
        // First get all conversations
        let descriptor = FetchDescriptor<Conversations>()
        
        do {
            let allConversations = try context.fetch(descriptor)
            
            // Filter conversations in memory
            return allConversations.filter { conversation in
                // Check title
                if conversation.title.lowercased().contains(query.lowercased()) {
                    return true
                }
                
                // Check messages
                return conversation.messages.contains { message in
                    message.content.lowercased().contains(query.lowercased())
                }
            }
        } catch {
            os_log("Error searching conversations: %@", log: OSLog.default, type: .error, error.localizedDescription)
            return []
        }
    }
    
    /// Optimiert the conversations in the context
    func optimizeConversations(context: ModelContext) async throws {
        let conversations = try await loadConversations(context: context)
        
        for conversation in conversations {
            // Remove duplicate messages
            let uniqueMessages = Array(Set(conversation.messages))
            conversation.messages = uniqueMessages
            
            // Update the last modified date
            conversation.updateLastModified()
        }
        
        try context.save()
    }
} 
