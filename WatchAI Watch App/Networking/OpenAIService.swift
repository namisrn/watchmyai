//
//  OpenAIService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 27.12.24.
//

import Alamofire
import Foundation

final class OpenAIService {
    static let shared = OpenAIService()

    private init() {}

    // Hauptfunktion zum Abrufen einer Chat-Antwort von OpenAI
    func fetchChatResponse(prompt: String, conversationHistory: [[String: String]]) async throws -> String {
        guard let apiKey = APIKeyManager.shared.apiKey else {
            throw AppError.noApiKey
        }

        // Header für die Anfrage
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        // Parameter für den Request-Body
        let parameters: [String: Any] = [
            "model": Constants.defaultModel,
            "messages": prepareMessages(prompt: prompt, conversationHistory: conversationHistory),
            "temperature": 0.2,
            "max_tokens": 256,
            "top_p": 0.8
        ]

        // API-Anfrage mit Alamofire
        let response = try await retryAsync(retries: 3) {
            try await AF.request(Constants.apiBaseURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .serializingDecodable(OpenAIResponse.self)
                .value
        }

        return response.choices.first?.message.content ?? ""
    }

    // Hilfsfunktion zur Vorbereitung der Nachrichtenstruktur
    private func prepareMessages(prompt: String, conversationHistory: [[String: String]]) -> [[String: String]] {
        var messages: [[String: String]] = [
            ["role": "system", "content": "You are a friendly assistant. Always address the user informally and keep the tone friendly and warm. Provide clear, concise answers that are as short as possible while still being helpful."]
        ]
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": prompt])
        return messages
    }


    // Hilfsfunktion für eine Retry-Policy
    private func retryAsync<T>(retries: Int, task: @escaping () async throws -> T) async throws -> T {
        var attempts = 0
        while attempts < retries {
            do {
                return try await task()
            } catch {
                attempts += 1
                if attempts == retries {
                    throw error
                }
            }
        }
        throw AppError.unknownError
    }
}
