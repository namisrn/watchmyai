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
    case rateLimitExceeded
    case serverError
    case timeoutError
    case authenticationError
    case unknownError
    case batteryLow
    case storageFull
    case invalidResponse
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "❌ API key missing. Please add your OpenAI API key in settings."
        case .invalidURL:
            return "❌ The API URL is invalid. Please contact support."
        case .networkError(let error):
            return "❌ A network error occurred: \(error.localizedDescription). Please check your connection."
        case .decodingError(let error):
            return "❌ Error processing response: \(error.localizedDescription). Please try again."
        case .rateLimitExceeded:
            return "❌ Rate limit exceeded. Please try again in a moment."
        case .serverError:
            return "❌ The OpenAI server is experiencing issues. Please try again later."
        case .timeoutError:
            return "❌ Request timed out. Please check your connection and try again."
        case .authenticationError:
            return "❌ Authentication failed. Please check your API key."
        case .unknownError:
            return "❌ An unknown error occurred. Please try again later."
        case .batteryLow:
            return "⚠️ Battery is low. Some features may be limited."
        case .storageFull:
            return "⚠️ Storage is full. Please free up some space."
        case .invalidResponse:
            return "❌ Received invalid response. Please try again."
        case .modelNotAvailable:
            return "❌ The selected model is not available. Please try a different model."
        }
    }
    
    // Add recovery suggestions
    var recoverySuggestion: String? {
        switch self {
        case .noApiKey:
            return "Go to Settings > API Key to add your OpenAI API key."
        case .networkError:
            return "Check your internet connection and try again."
        case .batteryLow:
            return "Consider charging your device or reducing app usage."
        case .storageFull:
            return "Delete some old conversations or clear the app cache."
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again."
        default:
            return "Try again in a moment."
        }
    }
    
    // User-friendly short error message
    var shortMessage: String {
        switch self {
        case .noApiKey:
            return "API key missing"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network error"
        case .decodingError:
            return "Response error"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .timeoutError:
            return "Request timed out"
        case .authenticationError:
            return "Authentication error"
        case .unknownError:
            return "Unknown error"
        case .batteryLow:
            return "Low battery"
        case .storageFull:
            return "Storage full"
        case .invalidResponse:
            return "Invalid response"
        case .modelNotAvailable:
            return "Model unavailable"
        }
    }
}

final class ErrorHandler {
    static func handle(error: AppError) {
        // Logging the error for future analysis
        Logger.logError(error)
    }
}
