//
//  WatchAIApp.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 28.12.24.
//

import SwiftUI
import SwiftData

@main
struct WatchAIApp: App {
    @StateObject private var appState = AppState()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Conversations.self, Chat.self,
                configurations: ModelConfiguration()
            )
            try APIKeyManager.shared.loadAPIKey()
            print("✅ API-Key erfolgreich geladen.")
        } catch {
            fatalError("❌ Fehler beim Initialisieren der App: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Menu()
                .environmentObject(appState)
                .modelContainer(container)
        }
    }
}
