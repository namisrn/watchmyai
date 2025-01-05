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
                                    .cornerRadius(15)
                                
                                ForEach(viewModel.messages, id: \.id) { message in
                                    messageView(for: message)
                                        .id(message.id)
                                }
                            }
                            .onChange(of: viewModel.messages) { _ in
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
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Spacer()
                        }
                        ToolbarItem(placement: .bottomBar) {
                            TextField("", text: $viewModel.currentInput, prompt: Text("Start").foregroundColor(.blue))
                                .foregroundColor(.blue)
                                .frame(width: 65, height: 45)
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                                .submitLabel(.send)
                                .onSubmit {
                                    viewModel.sendMessage()
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("New Chat")
        }
        .onAppear {
            // ModelContext übergeben
            viewModel.modelContext = context
            viewModel.resetChat()
        }
        // NEU: Falls errorMessage gesetzt wird, zeigen wir einen Alert.
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            // Optional: Buttons etc.
        } message: {
            // Inhalt des Alerts
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .preferredColorScheme(.dark)
    }
    
    /// Ansicht für eine einzelne Nachricht
    private func messageView(for message: Message) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(
                    message.role == .user
                        ? Color.blue
                        : Color.gray.opacity(0.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundColor(.white)
                .padding(message.role == .user ? .leading : .trailing, 15)
                .lineLimit(nil)
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.vertical, 2)
        .transition(.slide)
    }
}
#Preview {
    NewChat()
}
