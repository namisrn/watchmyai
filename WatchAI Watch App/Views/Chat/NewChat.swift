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
                // Optimierte ScrollView mit verbessertem Lazy Loading
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Nachrichten mit optimiertem Lazy Loading
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

                                // Optimiertes Message Rendering mit Lazy Loading
                                ForEach(viewModel.messages) { message in
                                    messageView(for: message)
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        // Optimierung: Lazy Loading für Nachrichten
                                        .onAppear {
                                            // Nachricht wird nur geladen, wenn sie sichtbar wird
                                            if message.id == viewModel.messages.last?.id {
                                                scrollToInput(scrollView: scrollView)
                                            }
                                        }
                                }
                                
                                // Abstand zwischen letzter Nachricht und Eingabefeld
                                Spacer().frame(height: 6)
                                
                                // Eingabebereich in der gleichen ScrollView
                                HStack(spacing: 8) {
                                    // Input buttons
                                    if !viewModel.isLoading {
                                        // Dictation button
                                        Button(action: {
                                            // Starte die watchOS-Diktierfunktion
                                            presentDictationController()
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        // iMessage-style input field
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
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                viewModel.sendMessage()
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .buttonStyle(PlainButtonStyle())
                                        .accentColor(.blue)
                                        // Optimierung: Tastatur sofort ausblenden nach Submit
                                        .onChange(of: viewModel.isLoading) { oldValue, newValue in
                                            if newValue {
                                                dismissKeyboard()
                                            }
                                        }
                                    } else {
                                        // Verbesserter Ladeindikator
                                        loadingIndicator
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.clear)
                                .id("inputField")
                                
                                // Zusätzlicher Raum am Ende für besseres Scrollen
                                Spacer().frame(height: 20)
                            }
                            .padding(.horizontal, 4)
                        }
                        .onChange(of: viewModel.messages) { oldValue, newValue in
                            // Optimierte Scroll-Logik
                            if let lastMessage = newValue.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            // Initiales Scrollen zum Eingabefeld
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
            // Optimierung: Ressourcen freigeben, wenn View verschwindet
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
        // Registriere das ViewModel für das Lebenszyklusmanagement
        .registerViewModel(viewModel, id: viewId)
        // Einfache Methode für Textdiktat - nutzt direkt die nativen Diktieroption auf der Apple Watch
        .onTapGesture(count: 2) {
            // Doppeltippen für schnelle Diktierfunktion als Alternative
            presentDictationController()
        }
    }

    // Funktion zum Zeigen des nativen Diktier-Dialogs
    private func presentDictationController() {
        #if os(watchOS)
        DispatchQueue.main.async {
            if let rootController = WKExtension.shared().rootInterfaceController {
                rootController.presentTextInputController(
                    withSuggestions: ["How are you", "Tell me a joke", "What time is it"],
                    allowedInputMode: .plain
                ) { results in
                    if let result = results?.first as? String, !result.isEmpty {
                        DispatchQueue.main.async {
                            self.viewModel.currentInput = result
                            self.viewModel.sendMessage()
                        }
                    }
                }
            }
        }
        #endif
    }

    // Funktion zum Ausblenden der Tastatur
    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    // Verbesserter Ladeindikator
    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            // Einfacher Punktindikator mit passender Farbe je nach Ladezustand
            Circle()
                .fill(loadingStageColor)
                .frame(width: 8, height: 8)
            
            // Kurzer, prägnanter Text
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
    
    // Bestimme Text basierend auf Ladezustand
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
    
    // Bestimme Farbe basierend auf Ladezustand
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

    // Optimierte Scroll-Funktion
    private func scrollToInput(scrollView: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            scrollView.scrollTo("inputField", anchor: .bottom)
        }
    }

    // Optimierte Message View mit Caching
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
        // Optimierung: View-Caching für bessere Performance
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
