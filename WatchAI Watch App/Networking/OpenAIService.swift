//
//  OpenAIService.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 27.12.24.
//

import Foundation
import WatchKit
import Combine

final class OpenAIService {
    static let shared = OpenAIService()
    
    // Cache for storing recent responses
    private var responseCache = NSCache<NSString, NSString>()
    private let cacheDuration: TimeInterval = 60 * 30 // 30 minutes cache validity
    private var cacheTimes = [NSString: Date]()
    private let cacheLimit = 20 // Maximum number of cached items
    
    // Performance optimization: Add memory warning observer
    private var memoryWarningObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    
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
        let headers: [String: String] = [
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

        guard let url = URL(string: Constants.apiBaseURL) else {
            throw AppError.invalidURL
        }

        // API-Anfrage mit URLSession + Combine
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let publisher: AnyPublisher<OpenAIResponse, Error> = NetworkingService.shared.post(url: url, headers: headers, body: parameters)
            
            let cancellable = publisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        let responseText = response.choices.first?.message.content ?? ""
                        continuation.resume(returning: responseText)
                    }
                )
            
            // Store cancellable in a local variable to prevent deallocation
            let localCancellable = cancellable
            cancellables.insert(localCancellable)
        }
        
        // Cache the response
        cacheResponse(response, for: cacheKey)
        
        return response
    }

    // Private method to generate a cache key
    private func generateCacheKey(prompt: String, conversationHistory: [[String: String]]) -> NSString {
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
        return combined as NSString
    }
    
    // Check if there's a valid cached response
    private func checkCache(for key: NSString) -> String? {
        // Check if we have a cached item
        guard let cachedResponse = responseCache.object(forKey: key) else {
            return nil
        }
        
        // Check if we have a valid cache time
        guard let cacheTime = cacheTimes[key] else {
            responseCache.removeObject(forKey: key)
            return nil
        }
        
        // Check if the cache is still valid
        let now = Date()
        if now.timeIntervalSince(cacheTime) > cacheDuration {
            // Cache expired
            responseCache.removeObject(forKey: key)
            cacheTimes.removeValue(forKey: key)
            return nil
        }
        
        return cachedResponse as String
    }
    
    // Cache a response
    private func cacheResponse(_ response: String, for key: NSString) {
        let nsResponse = response as NSString
        
        // Store in cache
        responseCache.setObject(nsResponse, forKey: key)
        cacheTimes[key] = Date()
        
        // Clean up old cache entries if we exceed the limit
        if cacheTimes.count > cacheLimit {
            let oldestKeys = cacheTimes.sorted { $0.value < $1.value }
                .prefix(cacheTimes.count - cacheLimit)
                .map { $0.key }
            
            for key in oldestKeys {
                cacheTimes.removeValue(forKey: key)
                responseCache.removeObject(forKey: key)
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
    
    // Generate follow-up questions based on the response
    func generateFollowUpQuestions(for response: String) async throws -> [String] {
        let prompt = """
        Based on this response: "\(response)"
        Generate 3 very short follow-up questions (max 5-7 words each) that would help the user explore the topic further.
        Format: Return only the questions, one per line, without numbering or additional text.
        Keep questions extremely concise and focused.
        """
        
        guard let apiKey = APIKeyManager.shared.apiKey,
              let url = URL(string: Constants.apiBaseURL) else {
            throw AppError.noApiKey
        }
        
        let headers: [String: String] = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        let parameters: [String: Any] = [
            "model": Constants.defaultModel,
            "messages": [["role": "system", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 100,
            "top_p": 0.9
        ]
        
        let questionsText = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let publisher: AnyPublisher<OpenAIResponse, Error> = NetworkingService.shared.post(url: url, headers: headers, body: parameters)
            
            let cancellable = publisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        let text = response.choices.first?.message.content ?? ""
                        continuation.resume(returning: text)
                    }
                )
            
            // Store cancellable in a local variable to prevent deallocation
            let localCancellable = cancellable
            cancellables.insert(localCancellable)
        }
        
        return questionsText.components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { $0 }
    }
}
