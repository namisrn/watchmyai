//
//  Archive.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

struct Archive: View {
    @Environment(\.modelContext) var context
    @Query(sort: [SortDescriptor(\Conversations.lastModified, order: .reverse)])
    var sortedConversations: [Conversations]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedConversations) { conversation in
                    NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                        Text(conversation.title)
                    }
                }
                .onDelete(perform: deleteItems)
                
                // Roter Button zum Löschen aller Nachrichten
                Button(action: deleteAllMessages) {
                    Text("Delete All")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Archive")
        }
        .listStyle(.plain)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let conversation = sortedConversations[index]
            context.delete(conversation)
        }
    }
    
    private func deleteAllMessages() {
        sortedConversations.forEach { conversation in
            context.delete(conversation)
        }
    }
}

#Preview {
    Archive()
}
