//
//  OpenAIService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 27.12.24.
//

import Alamofire
import Foundation
import WatchKit

final class OpenAIService {
    static let shared = OpenAIService()
    
    // Cache for storing recent responses
    private var responseCache = NSCache<NSString, NSString>()
    private let cacheDuration: TimeInterval = 60 * 30 // 30 minutes cache validity
    private var cacheTimes = [String: Date]()
    private let cacheLimit = 20 // Maximum number of cached items
    
    // Performance optimization: Add memory warning observer
    private var memoryWarningObserver: NSObjectProtocol?
    
    private init() {
        // Configure cache limits
        responseCache.countLimit = cacheLimit
        
        // Add memory warning observer
        #if os(watchOS)
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WKApplicationDidReceiveMemoryWarning"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
        #endif
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // Add method to clear cache when memory is low
    private func clearCache() {
        responseCache.removeAllObjects()
        cacheTimes.removeAll()
    }

    // Hauptfunktion zum Abrufen einer Chat-Antwort von OpenAI
    func fetchChatResponse(prompt: String, conversationHistory: [[String: String]]) async throws -> String {
        // Generate a cache key based on prompt and conversation history
        let cacheKey = generateCacheKey(prompt: prompt, conversationHistory: conversationHistory)
        
        // Check if we have a valid cached response
        if let cachedResponse = checkCache(for: cacheKey) {
            print("✅ Using cached response")
            return cachedResponse
        }
        
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
            "temperature": 0.7,
            "max_tokens": 150,
            "top_p": 0.9,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.5
        ]

        // API-Anfrage mit Alamofire
        let response = try await retryAsync(retries: 3) {
            try await AF.request(Constants.apiBaseURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .serializingDecodable(OpenAIResponse.self)
                .value
        }
        
        let responseText = response.choices.first?.message.content ?? ""
        
        // Cache the response
        cacheResponse(responseText, for: cacheKey)
        
        return responseText
    }

    // Private method to generate a cache key
    private func generateCacheKey(prompt: String, conversationHistory: [[String: String]]) -> String {
        // Simple cache key generation - combine the last few messages
        var keySources: [String] = []
        
        // Add the current prompt
        keySources.append(prompt)
        
        // Add the last message from history if available
        if let lastMessage = conversationHistory.last {
            if let content = lastMessage["content"] {
                keySources.append(content)
            }
        }
        
        // Combine and hash for the key
        let combined = keySources.joined(separator: "|||")
        return combined.hashValue.description
    }
    
    // Check if there's a valid cached response
    private func checkCache(for key: String) -> String? {
        let nsKey = key as NSString
        
        // Check if we have a cached item
        guard let cachedResponse = responseCache.object(forKey: nsKey) as String?,
              let cacheTime = cacheTimes[key] else {
            return nil
        }
        
        // Check if the cache is still valid
        let now = Date()
        if now.timeIntervalSince(cacheTime) > cacheDuration {
            // Cache expired
            responseCache.removeObject(forKey: nsKey)
            cacheTimes.removeValue(forKey: key)
            return nil
        }
        
        return cachedResponse
    }
    
    // Cache a response
    private func cacheResponse(_ response: String, for key: String) {
        let nsKey = key as NSString
        responseCache.setObject(response as NSString, forKey: nsKey)
        cacheTimes[key] = Date()
        
        // Clean up old cache entries if we exceed the limit
        if cacheTimes.count > cacheLimit {
            let oldestKeys = cacheTimes.sorted { $0.value < $1.value }
                .prefix(cacheTimes.count - cacheLimit)
                .map { $0.key }
            
            for key in oldestKeys {
                cacheTimes.removeValue(forKey: key)
                responseCache.removeObject(forKey: key as NSString)
            }
        }
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
                
                // Check for specific error types for better error handling
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        throw AppError.networkError(error)
                    case .timedOut:
                        throw AppError.timeoutError
                    default:
                        break
                    }
                }
                
                // Check for HTTP status codes
                if let afError = error as? AFError, 
                   let responseCode = afError.responseCode {
                    switch responseCode {
                    case 401:
                        throw AppError.authenticationError
                    case 429:
                        throw AppError.rateLimitExceeded
                    case 500...599:
                        throw AppError.serverError
                    default:
                        break
                    }
                }
                
                if attempts == retries {
                    throw error
                }
                
                // Exponential backoff
                try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts)) * 100_000_000))
            }
        }
        throw AppError.unknownError
    }
}
