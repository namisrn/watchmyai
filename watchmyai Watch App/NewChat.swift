//
//  NewChat.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

struct NewChat: View {
    
    @Environment(\.modelContext) var context
    @ObservedObject var viewModel = ViewModel()
    @State private var conversation: Conversations?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer(minLength: 60)
                    
                    // Scrollview mit Chat-Verlauf
                    ScrollView {
                        ScrollViewReader { scrollView in
                            LazyVStack(spacing: 2) {
                                Text("How can I help you?")
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                
                                ForEach(viewModel.messages, id: \.id) { message in
                                    messageView(message: message)
                                        .id(message.id)
                                }
                            }
                            .onChange(of: viewModel.messages) {
                                // Code ohne Parameter
                                withAnimation {
                                    scrollView.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                                }
                            }
                        }
                        
                        // Lader
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.0)
                        }
                    }
                    .scenePadding()
                    
                    // Eingabefeld
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Spacer()
                        }
                        ToolbarItem(placement: .bottomBar) {
                            TextField("", text: $viewModel.currentInput, prompt: Text("Start").foregroundColor(.blue))
                                .foregroundColor(Color.blue)
                                .frame(width: 60)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .multilineTextAlignment(.center)
                                .submitLabel(.send)
                                .onSubmit {
                                    if !viewModel.currentInput.isEmpty {
                                        viewModel.sendMessage()
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // Beim Öffnen: Neuer Chat
            viewModel.resetChat()
            startNewConversation()
        }
        .onDisappear {
            // Beim Verlassen: Unterhaltung speichern
            saveConversation()
        }
        .preferredColorScheme(.dark)
        .navigationTitle("New Chat")
    }
    
    // Layout für jede Nachricht
    func messageView(message: Message) -> some View {
        HStack {
            if message.role == .user { Spacer() }
            
            Text(message.content)
                .padding()
                .background(
                    message.role == .user
                    ? Color.blue
                    : Color.gray.opacity(0.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white)
                .padding(message.role == .user ? .leading : .trailing, 15)
            
            if message.role == .assistant { Spacer() }
        }
        .padding(.vertical, 2)
        .transition(.slide)
    }
    
    // Titel aus der ersten Nachricht generieren (oder Platzhalter)
    private func generateTitleFromMessage() -> String {
        let maxTitleLength = 50
        let baseTitle = viewModel.messages.first?.content ?? "New Conversation"
        let title = String(baseTitle.prefix(maxTitleLength))
        return title
    }
    
    // Neue Konversation erstellen und ins Modell einfügen
    private func startNewConversation() {
        if viewModel.userHasSentMessage {
            let title = generateTitleFromMessage()
            let newConversation = Conversations(
                title: title,
                createdDate: Date(),
                lastModified: Date(),
                messages: []
            )
            self.conversation = newConversation
            context.insert(newConversation)
        }
    }
    
    // Konversation + Chatverlauf speichern
    private func saveConversation() {
        guard viewModel.userHasSentMessage else { return }
        
        if conversation == nil {
            let title = generateTitleFromMessage()
            let newConversation = Conversations(
                title: title,
                createdDate: Date(),
                lastModified: Date(),
                messages: []
            )
            self.conversation = newConversation
            context.insert(newConversation)
        }
        
        if let conversation = self.conversation {
            for vmMessage in viewModel.messages {
                let chatMessage = Chat(content: vmMessage.content, sender: vmMessage.role.rawValue)
                conversation.messages.append(chatMessage)
                context.insert(chatMessage)
            }
            do {
                try context.save()
            } catch {
                print("Fehler beim Speichern der Konversation: \(error)")
            }
        }
    }
}

#Preview {
    NewChat()
}
