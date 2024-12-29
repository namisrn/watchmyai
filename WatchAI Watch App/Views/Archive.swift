//
//  Archive.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

/// Ansicht zur Anzeige des Archivbildschirms.
struct Archive: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Conversations.lastModified, order: .reverse)])
    private var sortedConversations: [Conversations]
    
    var body: some View {
        NavigationStack {
            List {
                // Anzeige der archivierten Konversationen
                ForEach(sortedConversations) { conversation in
                    NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                        Text(conversation.title)
                            .font(.headline)
                            .lineLimit(1) // Beschränkung der Zeilen für lange Titel
                    }
                }
                .onDelete(perform: deleteItems)
                
                // Button: Alle Nachrichten löschen
                if !sortedConversations.isEmpty {
                    deleteAllButton()
                }
            }
            .navigationTitle("Archive")
            .listStyle(.plain)
        }
    }
    
    // MARK: - Private Views
    
    /// Erstellt den Button, um alle Konversationen zu löschen.
    private func deleteAllButton() -> some View {
        Button(action: deleteAllMessages) {
            Text("Delete All")
                .foregroundColor(.red)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
        }
        .listRowBackground(Color.clear) // Kein Hintergrund für den Button
    }
    
    // MARK: - Private Methods
    
    /// Löscht ausgewählte Konversationen.
    /// - Parameter offsets: Die zu löschenden Indizes.
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let conversation = sortedConversations[index]
            context.delete(conversation)
        }
    }
    
    /// Löscht alle Konversationen im Archiv.
    private func deleteAllMessages() {
        for conversation in sortedConversations {
            context.delete(conversation)
        }
    }
}

#Preview {
    Archive()
}
