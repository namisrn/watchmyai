//
//  WatchAIApp.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 28.12.24.
//

import SwiftUI
import SwiftData

@main
struct WatchAI_Watch_AppApp: App {
    @StateObject private var appState = AppState()
    var container: ModelContainer?

    init() {
        do {
            let schema = Schema([Conversations.self, Chat.self])
            container = try ModelContainer(for: schema, configurations: [])

            if let apiKey = loadAPIKeyFromPlist(), !apiKey.isEmpty {
                print("API-Key erfolgreich geladen.")
            } else {
                print("Fehler: Kein API-Key vorhanden.")
            }
        } catch {
            container = nil
            print("Error initializing ModelContainer: \(error)")
        }
    }

    /// Lädt den API-Key aus der Secrets.plist-Datei.
    private func loadAPIKeyFromPlist() -> String? {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let apiKey = dict["OPENAI_API_KEY"] as? String {
            return apiKey
        }
        return nil
    }

    var body: some Scene {
        WindowGroup {
            if let safeContainer = container {
                Menu()
                    .environmentObject(appState)
                    .modelContainer(safeContainer)
            } else {
                Text("Failed to initialize data storage.")
                    .environmentObject(appState)
            }
        }
    }
}

/// Einfache Klasse zur Verwaltung globaler App-States (z.B. Fehler).
final class AppState: ObservableObject {
    @Published var isDataStorageFailed: Bool = false
    @Published var alertMessage: String? = nil
}
