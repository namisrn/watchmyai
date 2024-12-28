//
//  watchmyaiApp.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

@main
struct watchmyai_Watch_AppApp: App {
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
