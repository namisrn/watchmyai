//
//  WatchAIApp.swift
//  WatchAI Watch App
//
//  Created by Sasan Rafat Nami on 28.12.24.
//

import SwiftUI
import SwiftData
import WatchKit
import OSLog
@main
struct WatchAIApp: App {
    @StateObject private var appState = AppState()
    private let container: ModelContainer
    
    // Lifecycle management
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModelRegistry: [String: ViewModel] = [:]
    
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
                // Register view models for lifecycle management
                .onPreferenceChange(ViewModelRegistryKey.self) { registry in
                    self.viewModelRegistry = registry
                }
        }
        // Handle app lifecycle events for better battery management
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                print("🔄 App entering background - cleaning up resources")
                performBackgroundTasks()
            case .inactive:
                print("🔄 App becoming inactive")
                saveActiveState()
            case .active:
                print("🔄 App becoming active")
            @unknown default:
                break
            }
        }
    }
    
    // Handle background tasks
    private func performBackgroundTasks() {
        // Clean up and save all view models
        for (_, viewModel) in viewModelRegistry {
            viewModel.cleanup()
        }
        
        // Force in-memory data to be saved to disk
        do {
            try container.mainContext.save()
        } catch {
            print("❌ Error saving context: \(error.localizedDescription)")
        }
    }
    
    // Save current state when app becomes inactive
    private func saveActiveState() {
        // Save active conversations
        do {
            try container.mainContext.save()
        } catch {
            print("❌ Error saving context: \(error.localizedDescription)")
        }
    }
}

// Preference key to track view models for lifecycle management
struct ViewModelRegistryKey: PreferenceKey {
    static var defaultValue: [String: ViewModel] = [:]
    
    static func reduce(value: inout [String: ViewModel], nextValue: () -> [String: ViewModel]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

// Extension to make registration of view models easier
extension View {
    func registerViewModel(_ viewModel: ViewModel, id: String) -> some View {
        preference(key: ViewModelRegistryKey.self, value: [id: viewModel])
    }
}
