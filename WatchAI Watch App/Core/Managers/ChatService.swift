//
//  ChatService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 18.03.25.
//

import Foundation
import Combine

/// Service für die Chat-Anfragen und -Antworten
final class ChatService {
    
    // Singleton-Instanz für einfachen Zugriff
    static let shared = ChatService()
    
    // Event-Publisher für Ladezustände
    private let loadingStageSubject = PassthroughSubject<LoadingStage, Never>()
    var loadingStagePublisher: AnyPublisher<LoadingStage, Never> {
        loadingStageSubject.eraseToAnyPublisher()
    }
    
    // NLP-Verarbeitungseinstellungen
    var performNLPAnalysis: Bool = false
    
    private init() {}
    
    // Definiert die möglichen Ladezustände
    enum LoadingStage {
        case thinking, fetching, generating, processing, completed, error
    }
    
    /// Sendet eine Chat-Nachricht und gibt die Antwort zurück
    func sendMessage(userMessage: Message, conversationHistory: [Message]) async throws -> String {
        // Update loading stage
        loadingStageSubject.send(.thinking)
        
        // Perform NLP analysis if enabled
        if performNLPAnalysis {
            Task {
                await performNLPAnalysis(for: userMessage.content)
            }
        }
        
        // Format conversation history for API
        let formattedHistory = conversationHistory.map { ["role": $0.role.rawValue, "content": $0.content] }
        
        // Update loading stage
        loadingStageSubject.send(.fetching)
        
        do {
            // Get response from OpenAI
            let result = try await OpenAIService.shared.fetchChatResponse(
                prompt: userMessage.content,
                conversationHistory: formattedHistory
            )
            
            // Update loading stage
            loadingStageSubject.send(.generating)
            
            // Small delay to allow UI to show the generating stage
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Complete the process
            loadingStageSubject.send(.completed)
            
            return result
        } catch {
            // Update loading stage to error
            loadingStageSubject.send(.error)
            throw error
        }
    }
    
    /// Wiederholt eine Anfrage mit demselben Inhalt
    func retryMessage(content: String, conversationHistory: [Message]) async throws -> String {
        // Create a new message with the same content
        let retryMessage = Message(
            id: UUID(),
            role: .user,
            content: content,
            createdAt: Date()
        )
        
        // Send the message
        return try await sendMessage(userMessage: retryMessage, conversationHistory: conversationHistory)
    }
    
    // Separate method for NLP analysis to run asynchronously
    private func performNLPAnalysis(for text: String) async {
        // Sentiment-Analyse
        let sentiment = NLProcessor.analyzeSentiment(for: text)
        print("📊 Sentiment: \(sentiment)")

        // Entity Extraction
        let entities = NLProcessor.extractEntities(from: text)
        print("🧩 Entities: \(entities)")

        // Spracherkennung
        let language = NLProcessor.detectLanguage(for: text)
        print("🌐 Language detected: \(language)")

        // Keyword Extraction
        let keywords = NLProcessor.extractKeywords(from: text)
        print("🔑 Keywords: \(keywords)")
    }
} 