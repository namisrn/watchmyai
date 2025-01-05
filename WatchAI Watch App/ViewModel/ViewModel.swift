//
//  ViewModel.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel zur Verwaltung der Chatlogik und -zustände.
@MainActor
final class ViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var chatOutput: String = "How can I help you?"
    @Published var userHasSentMessage: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    
    
    func setErrorMessage(_ msg: String) {
        self.errorMessage = msg
        self.showErrorAlert = true
    }
    
    private let openAIService = OpenAIService.shared
    
    /// Wir brauchen optionalen Zugriff auf ModelContext (SwiftData), um
    /// direkt hier im ViewModel speichern zu können, falls gewünscht.
    var modelContext: ModelContext?
    var currentConversation: Conversations? = nil
    
    func sendMessage() {
        guard !currentInput.isEmpty else { return }
        isLoading = true
        
        let newMessage = Message(
            id: UUID(),
            role: .user,
            content: currentInput,
            createdAt: Date()
        )
        
        messages.append(newMessage)
        currentInput = ""
        userHasSentMessage = true
        
        // conversationHistory für den API-Request
        let conversationHistory = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        
        Task {
            do {
                let result = try await openAIService.fetchChatResponse(
                    prompt: newMessage.content,
                    conversationHistory: conversationHistory
                )
                handleAPIResponse(content: result)
            } catch {
                // Wenn ein Fehler passiert, zeigen wir ihn an
                self.errorMessage = error.localizedDescription
                print("Error receiving response: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    func resetChat() {
        chatOutput = "How can I help you?"
        currentInput = ""
        messages.removeAll()
        userHasSentMessage = false
        isLoading = false
        errorMessage = nil
    }
    
    private func handleAPIResponse(content: String) {
        let receivedMessage = Message(
            id: UUID(),
            role: .assistant,
            content: content,
            createdAt: Date()
        )
        messages.append(receivedMessage)
        
        // Nach jeder erfolgreichen Antwort speichern wir die Daten,
        // damit bei plötzlichem App-Verlassen nichts verloren geht.
        saveConversationIfNeeded()
    }
    
    /// Erzeugt oder aktualisiert eine Conversation in SwiftData und speichert.
    private func saveConversationIfNeeded() {
        guard let context = modelContext else {
            print("No ModelContext available – skipping save.")
            return
        }
        
        // Falls noch keine Conversation existiert, erstellen wir eine.
        if currentConversation == nil {
            let title = generateTitle()
            let newConversation = Conversations(
                title: title,
                createdDate: Date(),
                lastModified: Date(),
                messages: []
            )
            self.currentConversation = newConversation
            context.insert(newConversation)
        }
        
        // Füge die neuen Messages in das SwiftData-Modell ein
        guard let conversation = currentConversation else { return }
        conversation.updateLastModified()
        conversation.title = generateTitle()
        
        // Leere zuerst die vorhandenen messages und füge dann erneut hinzu
        conversation.messages.removeAll()
        
        for vmMessage in messages {
            let chatMessage = Chat(content: vmMessage.content, sender: vmMessage.role.rawValue)
            conversation.messages.append(chatMessage)
            context.insert(chatMessage)
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving the conversation: \(error.localizedDescription)")
        }
    }
    
    private func generateTitle() -> String {
        let maxTitleLength = 50
        let baseTitle = messages.first?.content ?? "New Conversation"
        return String(baseTitle.prefix(maxTitleLength))
    }
}
