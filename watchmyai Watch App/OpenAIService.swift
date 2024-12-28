//
//  OpenAIService.swift
//  watchmyai
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation

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
/// Dieser Service ist als Singleton implementiert, um zentralen Zugriff zu ermöglichen.
final class OpenAIService {
    // MARK: - Singleton
    static let shared = OpenAIService()
    
    // MARK: - Private Eigenschaften
    
    /// Lies den Key aus der Config.plist (Schlüssel: "OpenAI_API_Key").
    /// Falls der Schlüssel nicht existiert, wirf einen Fehler oder verwende einen leeren String.
    private let apiKey: String = {
        // Pfad zu "Config.plist" ermitteln
        guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              // Dictionary aus der Propertylist laden
              let plist = NSDictionary(contentsOfFile: filePath),
              // Wert mit dem Schlüssel "OpenAI_API_Key" auslesen
              let key = plist["OpenAI_API_Key"] as? String
        else {
            fatalError("Fehler: 'OpenAI_API_Key' wurde nicht in der Config.plist gefunden.")
        }
        return key
    }()
    
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let urlSession = URLSession.shared
    
    /// Initialisierung privat, um das Singleton-Muster zu erzwingen.
    private init() {}
    
    // MARK: - API-Aufruf (Text)
    func fetchChatResponse(
        prompt: String,
        conversationHistory: [[String: String]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var messages = [[String: String]]()
        messages.append(
            [
                "role": "system",
                "content": """
                Du bist ein freundlicher, hilfsbereiter Chat-Assistent. Beantworte bitte die Fragen kurz und prägnant.
                """
            ]
        )
        // Historie + neueste Benutzer-Eingabe anhängen
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": prompt])
        
        // Request-Body
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 500,
            "top_p": 0.8
        ]
        
        // URL erstellen
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        // Request erstellen
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // JSON-Body setzen
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Netzwerk-Aufruf
        urlSession.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "API Error",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Keine Daten erhalten"]
                )))
                return
            }
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decodedResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(
                        domain: "API Error",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Keine gültige Antwort erhalten"]
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - API-Aufruf (Audio) - Falls erwünscht
    func fetchAudioResponse(
        audioData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let base64Audio = audioData.base64EncodedString()
        let apiURL = "https://api.openai.com/v1/audio-process"
        
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "audio": base64Audio,
            "model": "gpt-4o-audio-preview"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        urlSession.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "API Error",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Keine Daten erhalten"]
                )))
                return
            }
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decodedResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "API Error", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
