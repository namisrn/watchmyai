//
//  NewChat.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

struct NewChat: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = ViewModel()
    @State private var conversation: Conversations?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer(minLength: 60)

                    // ScrollView mit Chat-Verlauf
                    ScrollView {
                        ScrollViewReader { scrollView in
                            LazyVStack(spacing: 2) {
                                Text("How can I help you?")
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)

                                ForEach(viewModel.messages, id: \.id) { message in
                                    messageView(for: message)
                                        .id(message.id)
                                }
                            }
                            .onChange(of: viewModel.messages) {
                                withAnimation {
                                    scrollView.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                                }
                            }
                        }

                        // Ladespinner
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
                                .foregroundColor(.blue)
                                .frame(width: 65, height: 45)
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
            viewModel.resetChat()
            initializeNewConversation()
        }
        .onDisappear {
            saveConversation()
        }
        .preferredColorScheme(.dark)
        .navigationTitle("New Chat")
    }

    /// Erstellt eine Ansicht für eine einzelne Nachricht
    private func messageView(for message: Message) -> some View {
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

    /// Generiert den Titel basierend auf der ersten Nachricht oder einem Platzhalter
    private func generateTitle() -> String {
        let maxTitleLength = 50
        let baseTitle = viewModel.messages.first?.content ?? "New Conversation"
        return String(baseTitle.prefix(maxTitleLength))
    }

    /// Initialisiert eine neue Konversation und fügt sie dem Modell hinzu
    private func initializeNewConversation() {
        guard viewModel.userHasSentMessage else { return }

        let title = generateTitle()
        let newConversation = Conversations(
            title: title,
            createdDate: Date(),
            lastModified: Date(),
            messages: []
        )
        self.conversation = newConversation
        context.insert(newConversation)
    }

    /// Speichert die Konversation und den Chatverlauf
    private func saveConversation() {
        guard viewModel.userHasSentMessage else { return }

        if conversation == nil {
            let title = generateTitle()
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
                print("Error saving the conversation: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NewChat()
}
