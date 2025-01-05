//
//  OpenAIService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 27.12.24.
//

import Foundation
import NaturalLanguage

/// Modell zur Decodierung der OpenAI API-Antwort.
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

/// Fehler für den OpenAIService.
enum OpenAIServiceError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidRequestBody(Error)
    case networkError(Error)
    case noData
    case noValidResponse
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "No API Key found in Secrets.plist."
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidRequestBody(let error):
            return "Failed to create the request body: \(error.localizedDescription)"
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .noData:
            return "No data was received from the server."
        case .noValidResponse:
            return "No valid response was received from the server."
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        }
    }
}

/// Service zur Kommunikation mit der OpenAI API.
final class OpenAIService {
    // MARK: - Singleton
    static let shared = OpenAIService()

    // MARK: - Private Eigenschaften
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let urlSession: URLSession = .shared

    private var apiKey: String? {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["OPENAI_API_KEY"] as? String {
            return key
        }
        return nil
    }

    private init() {}

    // MARK: - API-Request
    /// Asynchrone Methode, die die Chat-Antwort von OpenAI holt.
    func fetchChatResponse(
        prompt: String,
        conversationHistory: [[String: String]]
    ) async throws -> String {
        // 1) Hole API-Key aus Secrets.plist
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenAIServiceError.noApiKey
        }

        // 2) Sprache erkennen
        let languageCode = detectLanguage(for: prompt) ?? "en"

        // 3) Nachrichten vorbereiten
        let messages = prepareMessages(prompt: prompt, conversationHistory: conversationHistory, languageCode: languageCode)

        // 4) Request-Body erstellen
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 500,
            "top_p": 0.9
        ]

        // 5) URL prüfen und Request erstellen
        guard let url = URL(string: apiURL) else {
            throw OpenAIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIServiceError.invalidRequestBody(error)
        }

        // 6) Request ausführen
        let (data, _) = try await urlSession.data(for: request)
        guard !data.isEmpty else {
            throw OpenAIServiceError.noData
        }

        // 7) Antwort dekodieren
        do {
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            if let content = decodedResponse.choices.first?.message.content {
                return content
            } else {
                throw OpenAIServiceError.noValidResponse
            }
        } catch {
            throw OpenAIServiceError.decodingError(error)
        }
    }

    // MARK: - Private Hilfsmethoden
    /// Erkennen der Sprache eines gegebenen Textes.
    private func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    /// Nachrichten für den API-Request vorbereiten.
    private func prepareMessages(
        prompt: String,
        conversationHistory: [[String: String]],
        languageCode: String
    ) -> [[String: String]] {
        var messages: [[String: String]] = [
            [
                "role": "system",
                "content": "You are a friendly and helpful assistant. Always respond in the same language as the user input. The input language is \(languageCode)."
            ]
        ]
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": prompt])
        return messages
    }
}
