import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userMessage: String = ""
    @State private var chatHistory: [(text: String, isUser: Bool)] = [
        ("Hello! I am your AI Fitness Coach. How can I help you today?", false)
    ]
    @State private var isTyping = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#121212").ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        ForEach(0..<chatHistory.count, id: \.self) { index in
                            let chat = chatHistory[index]
                            HStack {
                                if chat.isUser { Spacer() }
                                Text(chat.text)
                                    .padding()
                                    .background(chat.isUser ? Color.cyan : Color(hex: "#1E1E1E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                if !chat.isUser { Spacer() }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        
                        if isTyping {
                            HStack {
                                Text("Bot is typing...")
                                    .italic()
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                Spacer()
                            }
                        }
                    }
                    
                    // Input Area
                    HStack {
                        TextField("Ask something...", text: $userMessage)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.cyan)
                                .padding()
                        }
                        .disabled(userMessage.isEmpty || isTyping)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func sendMessage() {
        let msg = userMessage
        chatHistory.append((text: msg, isUser: true))
        userMessage = ""
        isTyping = true
        
        Task {
            do {
                let reply = try await APIService.shared.askAIBot(message: msg)
                chatHistory.append((text: reply, isUser: false))
            } catch {
                chatHistory.append((text: "Sorry, I couldn't reach the server.", isUser: false))
            }
            isTyping = false
        }
    }
}
