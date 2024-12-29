//
//  OpenAIService.swift
//  watchmyai
//
//  Created by Rafat Nami, Sasan on 27.12.24.
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

/// Service zur Kommunikation mit der OpenAI API.
/// Singleton-Muster für zentralen Zugriff auf die API-Interaktionen.
final class OpenAIService {
    // MARK: - Singleton
    static let shared = OpenAIService()
    
    // MARK: - Private Eigenschaften
    
    /// OpenAI API-Schlüssel aus der `Config.plist`.
    private let apiKey: String = {
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let key = plist["OpenAI_Key"] as? String, !key.isEmpty else {
            fatalError("Error: ‘OpenAI_Key’ not found or invalid in Config.plist.")
        }
        return key
    }()
    
    /// Basis-URL der OpenAI API.
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    /// Gemeinsame URLSession-Instanz.
    private let urlSession: URLSession = .shared
    
    /// Private Initialisierung zur Erzwingung des Singleton-Musters.
    private init() {}
    
    // MARK: - Öffentliche Methoden
    
    /// Ruft eine Chat-Antwort von der OpenAI API ab.
    /// - Parameters:
    ///   - prompt: Benutzer-Eingabe.
    ///   - conversationHistory: Verlauf der Unterhaltung.
    ///   - completion: Abschluss-Handler mit dem Ergebnis als `String` oder einem `Error`.
    func fetchChatResponse(
        prompt: String,
        conversationHistory: [[String: String]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Sprache des Benutzers erkennen
        let languageCode = detectLanguage(for: prompt) ?? "en"
        
        // Nachrichten für den API-Request vorbereiten
        let messages = prepareMessages(prompt: prompt, conversationHistory: conversationHistory, languageCode: languageCode)
        
        // Request-Body erstellen
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.2,
            "max_tokens": 100,
            "top_p": 0.9
        ]
        
        // API-Request ausführen
        executeRequest(with: requestBody, completion: completion)
    }
    
    // MARK: - Private Methoden
    
    /// Erkennt die Sprache einer gegebenen Textnachricht.
    /// - Parameter text: Der zu analysierende Text.
    /// - Returns: Ein Sprachcode wie "en", "de", "fr", etc.
    private func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
    
    /// Bereitet die Nachrichten für den API-Request vor.
    /// - Parameters:
    ///   - prompt: Benutzer-Eingabe.
    ///   - conversationHistory: Verlauf der Unterhaltung.
    ///   - languageCode: Der erkannte Sprachcode der Benutzeranfrage.
    /// - Returns: Ein Array von Nachrichten im OpenAI-Format.
    private func prepareMessages(prompt: String, conversationHistory: [[String: String]], languageCode: String) -> [[String: String]] {
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
    
    /// Führt den Netzwerk-Request zur OpenAI API aus.
    /// - Parameters:
    ///   - requestBody: Der JSON-Body des Requests.
    ///   - completion: Abschluss-Handler mit dem Ergebnis.
    private func executeRequest(
        with requestBody: [String: Any],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: apiURL) else {
            completion(.failure(OpenAIServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(OpenAIServiceError.invalidRequestBody(error)))
            return
        }
        
        urlSession.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(OpenAIServiceError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(OpenAIServiceError.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decodedResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(OpenAIServiceError.noValidResponse))
                }
            } catch {
                completion(.failure(OpenAIServiceError.decodingError(error)))
            }
        }.resume()
    }
}

// MARK: - Fehlerdefinitionen

/// Fehler für den OpenAIService.
enum OpenAIServiceError: LocalizedError {
    case invalidURL
    case invalidRequestBody(Error)
    case networkError(Error)
    case noData
    case noValidResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
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
