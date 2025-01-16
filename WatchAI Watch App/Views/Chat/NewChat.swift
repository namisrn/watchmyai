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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.watchScreenSize) private var watchScreenSize

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
                                    .background(colorForBackground())
                                    .cornerRadius(15)
                                    .font(.headline)
                                    .dynamicTypeSize(.large)
                                    .foregroundColor(colorForText())

                                // Nachrichtenverlauf
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
                                .scaleEffect(1.2)
                        }
                    }
                    .scenePadding()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Spacer()
                        }
                        ToolbarItem(placement: .bottomBar) {
                            if viewModel.isLoading {
                                Text("Please wait...")
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal)
                                    .frame(height: textFieldHeight(for: watchScreenSize))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }else {
                                // TextField, wenn isLoading false ist
                                TextField(
                                    "",
                                    text: $viewModel.currentInput,
                                    prompt: Text("Start").foregroundColor(.blue)
                                )
                                .frame(height: textFieldHeight(for: watchScreenSize))
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .multilineTextAlignment(.center)
                                .submitLabel(.send)
                                .onSubmit {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.sendMessage()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("New Chat")
        }
        .onAppear {
            viewModel.modelContext = context
            viewModel.resetChat()
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .preferredColorScheme(.dark)
    }

    // Ansicht für eine einzelne Nachricht mit Font-Size-Animation
    private func messageView(for message: Message) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .padding()
                .background(backgroundColor(for: message.role))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundColor(.white)
                .padding(message.role == .user ? .leading : .trailing, 15)
                .font(.body)
                .dynamicTypeSize(.medium)

            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // Dynamische Hintergrundfarbe basierend auf dem Modus
    private func backgroundColor(for role: SenderRole) -> Color {
        switch role {
        case .user:
            return colorScheme == .dark ? .blue.opacity(0.8) : .blue.opacity(0.6)
        case .assistant:
            return colorScheme == .dark ? .gray.opacity(0.3) : .gray.opacity(0.2)
        }
    }

    // Dynamische Textfarbe basierend auf dem Modus
    private func colorForText() -> Color {
        colorScheme == .dark ? .white : .black
    }

    // Dynamische Hintergrundfarbe für Begrüßungstext
    private func colorForBackground() -> Color {
        colorScheme == .dark ? .gray.opacity(0.2) : .gray.opacity(0.1)
    }

    // Dynamische Textfeldhöhe basierend auf Bildschirmgröße
    private func textFieldHeight(for size: WatchScreenSize) -> CGFloat {
        switch size {
        case .small:
            return 40
        case .medium:
            return 45
        case .large:
            return 50
        }
    }
}

#Preview {
    NewChat()
}

enum WatchScreenSize {
    case small, medium, large
}

struct WatchScreenSizeKey: EnvironmentKey {
    static let defaultValue: WatchScreenSize = .medium
}

extension EnvironmentValues {
    var watchScreenSize: WatchScreenSize {
        get { self[WatchScreenSizeKey.self] }
        set { self[WatchScreenSizeKey.self] = newValue }
    }
}
