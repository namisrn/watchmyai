//
//  AppState.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 08.01.25.
//

import Foundation
import Combine

/// Class for managing global app state (e.g., errors, loading states)
class AppState: ObservableObject {
    @Published var isDataStorageFailed: Bool = false
    @Published var alertMessage: String? = nil
    
    // Additional global app state properties
    @Published var isOnboarded: Bool = true
    @Published var isApiKeyConfigured: Bool = false
}
