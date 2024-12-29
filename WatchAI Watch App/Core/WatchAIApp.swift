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
    var container: ModelContainer?
    
    init() {
        do {
            let schema = Schema([Conversations.self, Chat.self])
            container = try ModelContainer(for: schema, configurations: [])
        } catch {
            container = nil
            print("Error initializing ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let safeContainer = container {
                Menu()
                    .modelContainer(safeContainer)
            } else {
                Text("Failed to initialize data storage.")
            }
        }
    }
}
