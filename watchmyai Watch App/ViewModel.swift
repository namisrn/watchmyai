//
//  ViewModel.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation

class ViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var chatOutput: String = "How can I help you?"
    @Published var userHasSentMessage: Bool = false
    
    private let openAIService = OpenAIService.shared
    
    // Hauptfunktion zum Senden einer Nachricht
    func sendMessage() {
        
        // 1) UI-Status updaten
        isLoading = true
        
        // 2) Neue User-Nachricht erstellen
        let newMessage = Message(
            id: UUID(),
            role: .user,
            content: currentInput,
            createAt: Date()
        )
        
        // 3) Zur Chatliste hinzufügen und Eingabefeld leeren
        messages.append(newMessage)
        currentInput = ""
        userHasSentMessage = true
        
        // 4) Konversationshistorie für die API
        let conversationHistory = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let prompt = newMessage.content
        
        // 5) Asynchronen API-Call starten
        openAIService.fetchChatResponse(prompt: prompt, conversationHistory: conversationHistory) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let content):
                    let receivedMessage = Message(
                        id: UUID(),
                        role: .assistant,
                        content: content,
                        createAt: Date()
                    )
                    self.messages.append(receivedMessage)
                case .failure(let error):
                    print("Fehler beim Empfangen: \(error)")
                }
                self.isLoading = false
            }
        }
    }
    
    // Setzt den gesamten Chat zurück
    func resetChat() {
        chatOutput = "How can I help you?"
        currentInput = ""
        messages.removeAll()
        userHasSentMessage = false
        isLoading = false
    }
}

/// Rolle des Senders (User, Assistent)
enum SenderRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

/// Primitive Struktur für eine Chat-Nachricht
struct Message: Codable, Equatable {
    let id: UUID
    let role: SenderRole
    let content: String
    let createAt: Date
}
