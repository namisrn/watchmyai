//
//  ViewModel.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel zur Verwaltung der Chatlogik und -zustände.
@MainActor
final class ViewModel: ObservableObject, Equatable {
    // Unique identifier for Equatable implementation
    private let id = UUID()
    
    // Equatable implementation
    nonisolated static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // UI state properties
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var chatOutput: String = "How can I help you?"
    @Published var userHasSentMessage: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var followUpQuestions: [String] = []
    
    // Verbesserte Ladezustände
    @Published var loadingStage: LoadingStage = .thinking
    @Published var loadingProgress: Double = 0.0
    
    // Ladezustand-Definitionen
    enum LoadingStage {
        case thinking, fetching, generating, processing
    }
    
    // Configuration options
    private let maxMessagesInMemory = 30 // Limit messages stored in memory
    private var saveTask: Task<Void, Never>? // For batched saving
    private var apiTask: Task<Void, Error>? // For cancellation
    
    // Services
    private let chatService = ChatService.shared
    private let conversationManager = ConversationManager.shared
    private var loadingCancellable: AnyCancellable?
    
    // SwiftData context
    var modelContext: ModelContext?
    var currentConversation: Conversations? = nil
    
    // Verbesserte Error-Typen
    enum ViewModelError: Error {
        case invalidInput(String)
        case networkError(ChatService.ChatError)
        case processingError(String)
        case savingError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidInput(let message):
                return "Ungültige Eingabe: \(message)"
            case .networkError(let error):
                return error.localizedDescription
            case .processingError(let message):
                return "Verarbeitungsfehler: \(message)"
            case .savingError(let message):
                return "Speicherfehler: \(message)"
            }
        }
    }
    
    init() {
        // Subscribe to loading stage changes from chat service
        loadingCancellable = chatService.loadingStagePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] stage in
                guard let self = self else { return }
                
                switch stage {
                case .thinking:
                    self.loadingStage = .thinking
                case .fetching:
                    self.loadingStage = .fetching
                case .generating:
                    self.loadingStage = .generating
                case .processing:
                    self.loadingStage = .processing
                case .completed, .error:
                    // These are handled separately
                    break
                }
                
                // Animate progress
                if stage != .completed && stage != .error {
                    self.animateLoadingProgress()
                }
            }
    }
    
    func setErrorMessage(_ msg: String) {
        self.errorMessage = msg
        self.showErrorAlert = true
    }
    
    // Thread-safe message updates
    private func updateMessages(adding message: Message) async {
        await MainActor.run {
            messages.append(message)
            userHasSentMessage = true
            isLoading = true
            
            if messages.count > maxMessagesInMemory {
                messages = Array(messages.suffix(maxMessagesInMemory))
            }
        }
    }
    
    // Verbesserte Fehlerbehandlung mit async/await
    func sendMessage() async throws(ViewModelError) {
        guard !currentInput.isEmpty else {
            throw ViewModelError.invalidInput("Leere Nachricht")
        }
        
        let userInput = currentInput
        currentInput = ""
        
        let newMessage = Message(
            id: UUID(),
            role: .user,
            content: userInput,
            createdAt: .now,
            isRead: true
        )
        
        await updateMessages(adding: newMessage)
        
        do {
            try await processMessageRequest(newMessage)
        } catch let error as ChatService.ChatError {
            throw ViewModelError.networkError(error)
        } catch {
            throw ViewModelError.processingError(error.localizedDescription)
        }
    }
    
    private func processMessageRequest(_ message: Message) async throws {
        apiTask?.cancel()
        loadingProgress = 0.0
        
        do {
            async let response = chatService.sendMessage(
                userMessage: message,
                conversationHistory: messages
            )
            
            async let questions = chatService.generateFollowUpQuestions(
                for: message.content
            )
            
            let (result, followUps) = try await (response, questions)
            
            if Task.isCancelled { return }
            
            await handleAPIResponse(content: result)
            self.followUpQuestions = followUps
            
        } catch {
            throw ViewModelError.processingError("Fehler bei der Nachrichtenverarbeitung")
        }
    }
    
    func retrySendingMessage(_ content: String) {
        guard !isLoading else { return }
        isLoading = true
        loadingProgress = 0.0
        
        Task {
            do {
                let result = try await chatService.retryMessage(
                    content: content,
                    conversationHistory: messages
                )
                
                if Task.isCancelled { return }
                
                await handleAPIResponse(content: result)
            } catch {
                await handleError(error)
                isLoading = false
            }
        }
    }
    
    private func handleAPIResponse(content: String) async {
        let receivedMessage = Message(
            id: UUID(),
            role: .assistant,
            content: content,
            createdAt: .now,
            isRead: false
        )
        
        await MainActor.run {
            messages.append(receivedMessage)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                isLoading = false
            }
        }
        
        await saveConversationBatched()
    }
    
    private func saveConversationBatched() async {
        saveTask?.cancel()
        
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            
            if Task.isCancelled { return }
            
            await saveConversationIfNeeded()
        }
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    // Animate loading progress for better user feedback
    private func animateLoadingProgress() {
        // Reset progress
        loadingProgress = 0.0
        
        // Animate progress over time
        Task {
            while isLoading && !Task.isCancelled {
                // Random increment between 0.01 and 0.03
                let increment = Double.random(in: 0.01...0.03)
                
                // Don't go over 0.95 until we're done
                if loadingProgress < 0.95 {
                    loadingProgress += increment
                }
                
                // Add randomness to animation
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.1...0.3) * 1_000_000_000))
            }
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
    
    /// Erzeugt oder aktualisiert eine Conversation in SwiftData und speichert.
    private func saveConversationIfNeeded() async {
        guard let context = modelContext else {
            print("No ModelContext available – skipping save.")
            return
        }
        
        guard !messages.isEmpty else { return }
        
        // Use the conversation manager to save
        currentConversation = await conversationManager.saveConversation(
            messages: messages,
            context: context,
            currentConversation: currentConversation
        )
    }
    
    /// Cleanup method to be called when the app goes to background or view disappears
    func cleanup() {
        // Cancel any ongoing API tasks
        apiTask?.cancel()
        apiTask = nil
        
        // Cancel any pending save operations
        saveTask?.cancel()
        saveTask = nil
        
        // Force save any pending changes
        Task {
            await saveConversationIfNeeded()
        }
        
        // Clean up Combine subscriptions
        loadingCancellable?.cancel()
        loadingCancellable = nil
    }
    
    // Improved message management
    var unreadMessageCount: Int {
        messages.count(where: { !$0.isRead })
    }
    
    var lastMessage: Message? {
        messages.last
    }
    
    var messagesByDate: [(Date, [Message])] {
        Dictionary(grouping: messages) { 
            Calendar.current.startOfDay(for: $0.createdAt)
        }
        .sorted { $0.key > $1.key }
    }
    
    /// Generiert dynamische Vorschläge basierend auf der Konversationshistorie
    func generateSuggestions() async throws -> [String] {
        // Wenn keine Nachrichten vorhanden sind, generiere allgemeine Vorschläge
        if messages.isEmpty {
            return [
                "What's the weather like?",
                "Tell me a joke",
                "What time is it?",
                "Set a reminder"
            ]
        }
        
        // Erstelle einen Kontext aus den letzten Nachrichten
        let recentMessages = messages.suffix(3)
        let context = recentMessages.map { $0.content }.joined(separator: "\n")
        
        let prompt = """
        Based on the following conversation context, generate 4 relevant and natural follow-up questions or statements that the user might want to ask or say next. Keep them short and conversational.
        
        Recent conversation:
        \(context)
        
        Generate only the suggestions, each on a new line, without numbers or bullets. Keep them short and natural.
        """
        
        do {
            let result = try await chatService.generateFollowUpQuestions(for: prompt)
            return result
        } catch {
            // Fallback zu allgemeinen Vorschlägen im Fehlerfall
            return [
                "What's the weather like?",
                "Tell me a joke",
                "What time is it?",
                "Set a reminder"
            ]
        }
    }
}
