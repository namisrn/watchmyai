//
//  ViewModel.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation

/// ViewModel zur Verwaltung der Chatlogik und -zustände.
final class ViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var chatOutput: String = "How can I help you?"
    @Published var userHasSentMessage: Bool = false

    private let openAIService = OpenAIService.shared

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

        let conversationHistory = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        openAIService.fetchChatResponse(prompt: newMessage.content, conversationHistory: conversationHistory) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleAPIResponse(result: result)
            }
        }
    }

    func resetChat() {
        chatOutput = "How can I help you?"
        currentInput = ""
        messages.removeAll()
        userHasSentMessage = false
        isLoading = false
    }

    private func handleAPIResponse(result: Result<String, Error>) {
        switch result {
        case .success(let content):
            let receivedMessage = Message(
                id: UUID(),
                role: .assistant,
                content: content,
                createdAt: Date()
            )
            messages.append(receivedMessage)
        case .failure(let error):
            print("Error receiving response: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

enum SenderRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let role: SenderRole
    let content: String
    let createdAt: Date
}
