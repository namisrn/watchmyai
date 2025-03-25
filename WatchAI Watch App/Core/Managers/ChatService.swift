//
//  ChatService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 18.03.25.
//

import Foundation
import Combine

/// Service für die Chat-Anfragen und -Antworten
@MainActor
final class ChatService {
    
    // Singleton-Instanz für einfachen Zugriff
    static let shared = ChatService()
    
    // Spezifische Error-Typen für bessere Fehlerbehandlung
    enum ChatError: Error {
        case invalidInput(String)
        case networkError(underlying: Error)
        case apiError(code: Int, message: String)
        case processingError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidInput(let message):
                return "Ungültige Eingabe: \(message)"
            case .networkError(let error):
                return "Netzwerkfehler: \(error.localizedDescription)"
            case .apiError(let code, let message):
                return "API-Fehler (\(code)): \(message)"
            case .processingError(let message):
                return "Verarbeitungsfehler: \(message)"
            }
        }
    }
    
    // Thread-safe properties mit Actor-Isolation
    private let loadingStageSubject = CurrentValueSubject<LoadingStage, Never>(.thinking)
    @Published private(set) var currentStage: LoadingStage = .thinking
    
    nonisolated var loadingStagePublisher: AnyPublisher<LoadingStage, Never> {
        loadingStageSubject.eraseToAnyPublisher()
    }
    
    // NLP-Verarbeitungseinstellungen
    var performNLPAnalysis: Bool = false
    
    private init() {}
    
    // Verbesserte Ladezustände mit Foundation-Unterstützung
    enum LoadingStage: String {
        case thinking = "Thinking"
        case fetching = "Fetching"
        case generating = "Generating"
        case processing = "Processing"
        case completed = "Completed"
        case error = "Error"
        
        var localizedDescription: String {
            NSLocalizedString(rawValue, comment: "Loading stage description")
        }
    }
    
    /// Sendet eine Chat-Nachricht und gibt die Antwort zurück
    func sendMessage(userMessage: Message, conversationHistory: [Message]) async throws -> String {
        guard !userMessage.content.isEmpty else {
            throw ChatError.invalidInput("Leere Nachricht")
        }
        
        updateLoadingStage(.thinking)
        
        if performNLPAnalysis {
            async let analysis = analyzeMessageContent(userMessage.content)
            _ = try? await analysis
        }
        
        let formattedHistory = conversationHistory.map { ["role": $0.role.rawValue, "content": $0.content] }
        updateLoadingStage(.fetching)
        
        do {
            let result = try await OpenAIService.shared.fetchChatResponse(
                prompt: userMessage.content,
                conversationHistory: formattedHistory
            )
            
            updateLoadingStage(.generating)
            try await Task.sleep(for: .milliseconds(500))
            updateLoadingStage(.completed)
            
            return result
        } catch let error as NSError {
            updateLoadingStage(.error)
            throw ChatError.networkError(underlying: error)
        }
    }
    
    /// Wiederholt eine Nachricht mit der gleichen Konversationshistorie
    func retryMessage(content: String, conversationHistory: [Message]) async throws -> String {
        let tempMessage = Message(
            id: UUID(),
            role: .user,
            content: content,
            createdAt: Date(),
            isRead: true
        )
        return try await sendMessage(userMessage: tempMessage, conversationHistory: conversationHistory)
    }
    
    /// Generiert Folgevorschläge mit verbesserter Fehlerbehandlung
    func generateFollowUpQuestions(for message: String) async throws -> [String] {
        guard !message.isEmpty else {
            throw ChatError.invalidInput("Leere Nachricht für Folgevorschläge")
        }
        
        let prompt = """
        Based on the API’s response, generate 3 relevant follow-up questions from the user’s perspective, using the same language as the user’s original input. The questions should feel natural and contextually appropriate, as if the user is continuing the conversation:
        Message: \(message)
        
        Generate only the questions, each on a new line, without numbers or bullets.
        """
        
        do {
            let result = try await OpenAIService.shared.fetchChatResponse(
                prompt: prompt,
                conversationHistory: []
            )
            
            return result.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .prefix(3)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } catch {
            throw ChatError.processingError("Fehler beim Generieren der Folgevorschläge")
        }
    }
    
    /// Thread-safe Aktualisierung des Ladezustands
    private func updateLoadingStage(_ stage: LoadingStage) {
        Task { @MainActor in
            currentStage = stage
            loadingStageSubject.send(stage)
        }
    }
    
    /// Analysiert den Nachrichteninhalt mit verbesserter Fehlerbehandlung
    func analyzeMessageContent(_ content: String) async throws -> [String: Any] {
        guard performNLPAnalysis else { return [:] }
        guard !content.isEmpty else {
            throw ChatError.invalidInput("Leere Nachricht für Analyse")
        }
        
        let prompt = """
        Analyze the following message and provide sentiment, key topics, and language:
        Message: \(content)
        """
        
        do {
            let result = try await OpenAIService.shared.fetchChatResponse(
                prompt: prompt,
                conversationHistory: []
            )
            return ["analysis": result]
        } catch {
            throw ChatError.processingError("Fehler bei der Inhaltsanalyse")
        }
    }
    
    /// Streamt eine Antwort mit verbesserter Fehlerbehandlung
    func streamResponse(for message: String) -> AsyncStream<Result<String, ChatError>> {
        AsyncStream { continuation in
            Task {
                do {
                    let response = try await sendMessage(
                        userMessage: Message(id: UUID(), role: .user, content: message, createdAt: .now),
                        conversationHistory: []
                    )
                    
                    for character in response {
                        continuation.yield(.success(String(character)))
                        try await Task.sleep(for: .milliseconds(100))
                    }
                } catch {
                    continuation.yield(.failure(.processingError("Streaming-Fehler")))
                }
                continuation.finish()
            }
        }
    }
} 
