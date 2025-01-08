//
//  Archive.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

struct Archive: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Conversations.lastModified, order: .reverse)])
    private var sortedConversations: [Conversations]
    
    var body: some View {
        NavigationStack {
            List {
                if sortedConversations.isEmpty {
                    Text("No archived conversations")
                        .foregroundColor(.gray)
                } else {
                    ForEach(sortedConversations) { conversation in
                        NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                            Text(conversation.title)
                                .font(.headline)
                                .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteItems)
                    
                    // Button: Alle Nachrichten löschen
                    deleteAllButton()
                }
            }
            .navigationTitle("Archive")
            .listStyle(.plain)
        }
    }
    
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
        .listRowBackground(Color.clear)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let conversation = sortedConversations[index]
            context.delete(conversation)
        }
    }
    
    private func deleteAllMessages() {
        for conversation in sortedConversations {
            context.delete(conversation)
        }
    }
}

#Preview {
    Archive()
}
