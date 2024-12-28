//
//  ConversationDetailView.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    let conversation: Conversations
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(conversation.messages, id: \.self) { message in
                    messageView(message: message)
                }
            }
        }
        .navigationTitle(conversation.title)
    }
    
    private func messageView(message: Chat) -> some View {
        HStack {
            // Benutzer-Nachrichten rechts, Assistent-Nachrichten links
            if message.sender == SenderRole.user.rawValue {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(
                    message.sender == SenderRole.user.rawValue
                        ? Color.blue
                        : Color.gray.opacity(0.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white)
                .padding(message.sender == SenderRole.user.rawValue ? .leading : .trailing, 15)
            
            if message.sender == SenderRole.assistant.rawValue {
                Spacer()
            }
        }
        .padding(.vertical, 2)
        .transition(.slide)
    }
}

#Preview {
    // Beispiel: Dummy-Konversation für die Vorschau
    let dummyConversation = Conversations(
        title: "Test Preview",
        createdDate: Date(),
        lastModified: Date(),
        messages: [
            Chat(content: "Hallo, wie kann ich dir helfen?", sender: SenderRole.assistant.rawValue),
            Chat(content: "Ich habe eine Frage...", sender: SenderRole.user.rawValue)
        ]
    )
    
    return ConversationDetailView(conversation: dummyConversation)
}
