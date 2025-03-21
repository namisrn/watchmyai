//
//  APIKeyManager.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 08.01.25.
//

import Foundation

/// Utility-Klasse zur Verwaltung des API-Keys.
final class APIKeyManager {
    static let shared = APIKeyManager()

    private(set) var apiKey: String?

    private init() {}

    func loadAPIKey() throws {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String, !key.isEmpty else {
            throw APIKeyManagerError.noAPIKey
        }
        self.apiKey = key
    }
}

/// Fehler für den APIKeyManager.
enum APIKeyManagerError: LocalizedError {
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "❌ Kein gültiger API-Key in Secrets.plist gefunden."
        }
    }
}
