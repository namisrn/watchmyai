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
    
    func sendMessage() {
        guard !currentInput.isEmpty else { return }
        isLoading = true
        
        let userInput = currentInput
        currentInput = ""

        // Create and add the new message
        let newMessage = Message(
            id: UUID(),
            role: .user,
            content: userInput,
            createdAt: Date()
        )
        
        messages.append(newMessage)
        userHasSentMessage = true
        
        // Limit the number of messages in memory
        if messages.count > maxMessagesInMemory {
            messages = Array(messages.suffix(maxMessagesInMemory))
        }
        
        processMessageRequest(newMessage)
    }

    // Wiederholungsfunktion für Nachrichten
    func retrySendingMessage(_ content: String) {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Cancel any existing API task
        apiTask?.cancel()
        
        // Reset loading progress
        loadingProgress = 0.0
        
        // Create a new task for the API call
        apiTask = Task {
            do {
                let result = try await chatService.retryMessage(
                    content: content,
                    conversationHistory: messages
                )
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                await handleAPIResponse(content: result)
            } catch {
                await handleError(error)
                // Bei Fehler den Ladezustand zurücksetzen
                isLoading = false
            }
            
            // Loading wird jetzt in handleAPIResponse zurückgesetzt
        }
    }

    // Separated message processing logic for reuse
    private func processMessageRequest(_ message: Message) {
        // Cancel any existing API task
        apiTask?.cancel()
        
        // Reset loading progress
        loadingProgress = 0.0
        
        // Create a new task for the API call
        apiTask = Task {
            do {
                let result = try await chatService.sendMessage(
                    userMessage: message,
                    conversationHistory: messages
                )
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                await handleAPIResponse(content: result)
            } catch {
                await handleError(error)
                // Bei Fehler den Ladezustand zurücksetzen
                isLoading = false
            }
            
            // Loading wird jetzt in handleAPIResponse zurückgesetzt
        }
    }
    
    // Handle API errors
    private func handleError(_ error: Error) async {
        if !Task.isCancelled {
            // Verbesserte Fehlermeldungen
            if let appError = error as? AppError {
                switch appError {
                case .noApiKey:
                    self.errorMessage = "API key missing. Please add your OpenAI API key in settings."
                case .rateLimitExceeded:
                    self.errorMessage = "Rate limit exceeded. Please try again in a moment."
                case .networkError:
                    self.errorMessage = "Network error. Please check your connection and try again."
                case .serverError:
                    self.errorMessage = "OpenAI server error. Please try again later."
                case .timeoutError:
                    self.errorMessage = "Request timed out. Please check your connection."
                case .authenticationError:
                    self.errorMessage = "Authentication error. Please check your API key."
                case .unknownError:
                    self.errorMessage = "Unknown error occurred. Please try again."
                default:
                    self.errorMessage = "Error: \(appError.localizedDescription)"
                }
            } else {
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
            
            self.showErrorAlert = true
            print("Error receiving response: \(error.localizedDescription)")
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
    
    private func handleAPIResponse(content: String) async {
        let receivedMessage = Message(
            id: UUID(),
            role: .assistant,
            content: content,
            createdAt: Date()
        )
        
        // Nachricht zur Liste hinzufügen - löst den UI-Update aus
        await MainActor.run {
            messages.append(receivedMessage)
            // Kurze Verzögerung, damit der Scroll-Animation nach dem Update ausgelöst wird
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms Verzögerung
                isLoading = false
            }
        }
        
        // Use batched saving instead of saving immediately
        saveConversationBatched()
    }
    
    // Batched saving implementation
    private func saveConversationBatched() {
        // Cancel any existing save task
        saveTask?.cancel()
        
        // Create a new save task with a delay
        saveTask = Task { @MainActor in
            // Add a delay to batch multiple rapid saves
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            if Task.isCancelled { return }
            
            await saveConversationIfNeeded()
        }
    }
    
    // Cleanup method to be called when the app goes to background
    func cleanup() {
        apiTask?.cancel()
        apiTask = nil
        
        // Force save any pending changes
        saveTask?.cancel()
        saveTask = nil
        
        Task {
            await saveConversationIfNeeded()
        }
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
}
