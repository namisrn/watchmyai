//
//  ErrorHandler.swift
//  WatchAI Watch App
//
//  Created by Rafat Nami, Sasan on 08.01.25.
//

import Foundation

enum AppError: LocalizedError {
    case noApiKey
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "❌ Es wurde kein API-Key gefunden. Bitte überprüfen Sie Ihre Einstellungen."
        case .invalidURL:
            return "❌ Die API-URL ist ungültig. Bitte wenden Sie sich an den Support."
        case .networkError(let error):
            return "❌ Es ist ein Netzwerkfehler aufgetreten: \(error.localizedDescription). Bitte überprüfen Sie Ihre Verbindung."
        case .decodingError(let error):
            return "❌ Fehler beim Verarbeiten der Antwort: \(error.localizedDescription). Bitte versuchen Sie es erneut."
        case .unknownError:
            return "❌ Ein unbekannter Fehler ist aufgetreten. Bitte versuchen Sie es später erneut."
        }
    }
}

final class ErrorHandler {
    static func handle(error: AppError) {
        // Logging the error for future analysis
        Logger.logError(error)
    }
}
