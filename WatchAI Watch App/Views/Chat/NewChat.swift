//
//  NewChat.swift
//  watchmyai Watch App
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import WatchKit
import AVFoundation

struct NewChat: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = ViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.watchScreenSize) private var watchScreenSize
    @State private var showingInputOptions = false
    @State private var selectedQuickReply: String?
    @State private var isPresentingInputController = false

    // Optimierung: behalte eindeutige ID für View-Lebenszyklus-Identifikation
    private let viewId = UUID().uuidString
    
    // Error types for the view
    enum ChatViewError: Error {
        case dictationFailed
        case invalidInput
        case cancelled
        
        var localizedDescription: String {
            switch self {
            case .dictationFailed:
                return "Could not start dictation. Please try again."
            case .invalidInput:
                return "No text was detected. Please try speaking more clearly."
            case .cancelled:
                return "Dictation was cancelled."
            }
        }
    }
    
    // Quick reply options
    private let quickReplies = [
        "What's the weather?",
        "Tell me a joke",
        "Summarize this",
        "Thanks!"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 8) {
                                // Assistant welcome message
                                Text("How can I help you?")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(ChatBubble(isFromCurrentUser: false))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 40)
                                    .padding(.top, 4)
                                    .id("welcome")

                                ForEach(viewModel.messages) { message in
                                    messageView(for: message)
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .onAppear {
                                            if message.id == viewModel.messages.last?.id {
                                                scrollToInput(scrollView: scrollView)
                                            }
                                        }
                                }
                                
                                Spacer().frame(height: 6)
                                
                                HStack(spacing: 8) {
                                    if !viewModel.isLoading {
                                        Button(action: {
                                            Task {
                                                await presentDictationController()
                                            }
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        TextField(
                                            "",
                                            text: $viewModel.currentInput,
                                            prompt: Text("WatchMyAI").foregroundColor(.gray)
                                        )
                                        .background(Color.black)
                                        .frame(height: 45)
                                        .cornerRadius(20)
                                        .submitLabel(.send)
                                        .onSubmit {
                                            Task {
                                                do {
                                                    try await viewModel.sendMessage()
                                                } catch {
                                                    viewModel.setErrorMessage(error.localizedDescription)
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .buttonStyle(PlainButtonStyle())
                                        .accentColor(.blue)
                                        .onChange(of: viewModel.isLoading) { oldValue, newValue in
                                            if newValue {
                                                dismissKeyboard()
                                            }
                                        }
                                    } else {
                                        loadingIndicator
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.clear)
                                .id("inputField")
                                
                                if !viewModel.followUpQuestions.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Suggestions:")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(.leading, 8)
                                        
                                        ForEach(viewModel.followUpQuestions, id: \.self) { question in
                                            Button(action: {
                                                viewModel.currentInput = question
                                                Task {
                                                    do {
                                                        try await viewModel.sendMessage()
                                                    } catch {
                                                        viewModel.setErrorMessage(error.localizedDescription)
                                                    }
                                                }
                                            }) {
                                                Text(question)
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Color.blue.opacity(0.3))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                }
                                
                                Spacer().frame(height: 20)
                            }
                            .padding(.horizontal, 4)
                        }
                        .onChange(of: viewModel.messages) { oldValue, newValue in
                            if let lastMessage = newValue.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    scrollToInput(scrollView: scrollView)
                                }
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationTitle("Chat")
        }
        .onAppear {
            viewModel.modelContext = context
            viewModel.resetChat()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("Retry", role: .none) {
                if let lastMessage = viewModel.messages.last(where: { $0.role == .user }) {
                    viewModel.retrySendingMessage(lastMessage.content)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .preferredColorScheme(.dark)
        .registerViewModel(viewModel, id: viewId)
        .onTapGesture(count: 2) {
            Task {
                await presentDictationController()
            }
        }
    }

    private func presentDictationController() async {
        #if os(watchOS)
        guard let rootController = WKExtension.shared().rootInterfaceController else { return }
        
        do {
            // Generiere dynamische Vorschläge basierend auf der Konversationshistorie
            let suggestions = try await viewModel.generateSuggestions()
            
            let result = try await withCheckedThrowingContinuation { continuation in
                rootController.presentTextInputController(
                    withSuggestions: suggestions,
                    allowedInputMode: .plain
                ) { results in
                    if let results = results {
                        if let result = results.first as? String, !result.isEmpty {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: ChatViewError.invalidInput)
                        }
                    } else {
                        continuation.resume(throwing: ChatViewError.cancelled)
                    }
                }
            }
            
            viewModel.currentInput = result
            try await viewModel.sendMessage()
        } catch ChatViewError.cancelled {
            // Silently ignore cancellation
            return
        } catch ChatViewError.invalidInput {
            viewModel.setErrorMessage("No text was detected. Please try speaking more clearly.")
        } catch {
            viewModel.setErrorMessage(error.localizedDescription)
        }
        #endif
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(loadingStageColor)
                .frame(width: 8, height: 8)
            
            Text(loadingStageText)
                .font(.footnote)
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, 12)
    }
    
    private var loadingStageText: String {
        switch viewModel.loadingStage {
        case .thinking:
            return "Thinking..."
        case .fetching:
            return "Fetching..."
        case .generating:
            return "Generating..."
        case .processing:
            return "Processing..."
        }
    }
    
    private var loadingStageColor: Color {
        switch viewModel.loadingStage {
        case .thinking:
            return .blue
        case .fetching:
            return .green
        case .generating:
            return .orange
        case .processing:
            return .purple
        }
    }

    private func scrollToInput(scrollView: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            scrollView.scrollTo("inputField", anchor: .bottom)
        }
    }

    private func messageView(for message: Message) -> some View {
        HStack {
            if message.role == .assistant {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(ChatBubble(isFromCurrentUser: false))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .padding(.trailing, 20)
                    
                Spacer()
            } else {
                Spacer()
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(ChatBubble(isFromCurrentUser: true))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 2)
        .drawingGroup()
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

// Custom chat bubble shape
struct ChatBubble: Shape {
    var isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                               byRoundingCorners: [
                                   .topLeft,
                                   .topRight,
                                   isFromCurrentUser ? .bottomLeft : .bottomRight
                               ],
                               cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}
