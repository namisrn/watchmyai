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
            LazyVStack(spacing: 8) {
                ForEach(conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }), id: \.self) { message in
                    messageView(for: message)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func messageView(for message: Chat) -> some View {
        HStack {
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
        .padding(.vertical, 4)
        .transition(.slide)
    }
}

#Preview {
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
