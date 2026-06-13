import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    
    let myEmail: String
    let targetEmail: String
    let isTrainer: Bool
    
    @State private var messages: [ChatMessageOverviewItem] = []
    @State private var messageText: String = ""
    @State private var isLoading = true
    
    // Timer pentru auto-refresh la fiecare 3 secunde
    let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        // ADAUGAT: VStack principal pentru a ține chat-ul și bara de input împreună
        VStack(spacing: 0) {
            
            // Zona de mesaje cu Auto-Scroll
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages, id: \.idMessage) { msg in
                            ChatBubbleRow(message: msg, currentUserEmail: myEmail)
                                .id(msg.idMessage)
                        }
                    }
                    .padding()
                }
                // Rezolvare Auto-Scroll la apariția mesajelor noi
                .onChange(of: messages.count) { oldValue, newValue in
                    scrollToBottom(proxy: proxy)
                }
                // Scroll automat și când se deschide prima dată chatul cu mesaje
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .padding(12)
                    .background(Color(hex: "#2C2C2C"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.orange)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            
        } // ÎNCHIDERE VStack principal
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Chat") // Adaugă titlul nativ
        .navigationBarTitleDisplayMode(.inline) // Face titlul mic și centrat, lângă butonul de Back
        .onAppear { loadMessages() }
        .onReceive(timer) { _ in
            loadMessages() // Auto-refresh periodic
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMsg = messages.last {
            withAnimation {
                proxy.scrollTo(lastMsg.idMessage, anchor: .bottom)
            }
        }
    }
    
    private func loadMessages() {
        let trainerEmailForQuery = isTrainer ? myEmail : targetEmail
        let clientEmailForQuery = isTrainer ? targetEmail : myEmail
        
        Task { @MainActor in // Obligatoriu pe MainActor pentru a actualiza UI-ul în siguranță
            do {
                let fetchedMessages = try await APIService.shared.getChatMessages(trainerEmail: trainerEmailForQuery, clientEmail: clientEmailForQuery)
                
                // Optimizare: Actualizăm lista DOAR dacă s-a schimbat ceva (previne flicker-ul)
                if fetchedMessages.count != self.messages.count {
                    self.messages = fetchedMessages
                }
                isLoading = false
            } catch {
                print("Eroare la preluarea mesajelor: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func sendMessage() {
            let content = messageText.trimmingCharacters(in: .whitespaces)
            guard !content.isEmpty else { return }
            
            let request = ChatMessageRequest(senderEmail: myEmail, receiverEmail: targetEmail, content: content)
            messageText = "" // Golim input-ul imediat pentru o experiență fluidă
            
            Task { @MainActor in
                do {
                    // 1. Trimitem mesajul text în baza de date
                    try await APIService.shared.sendMessageMobile(requestData: request)
                    
                    // 2. NOU: Trimitem automat și o notificare Push către telefonul destinatarului
                    // Personalizăm titlul în funcție de cine trimite mesajul
                    let senderRole = isTrainer ? "Trainer" : "Client"
                    let notificationText = "New message from \(senderRole): \(content)"
                    
                    // Folosim funcția de notificare existentă (pe care o foloseai la butonul manual din Android)
                    // Folosim try? pentru ca, dacă pică notificarea, să nu blocheze reîncărcarea chat-ului
                    try? await APIService.shared.sendCustomNotification(clientEmail: targetEmail, message: notificationText)
                    
                    // 3. Reîncărcăm mesajele pentru a vedea ce tocmai am trimis
                    let trainerEmailForQuery = isTrainer ? myEmail : targetEmail
                    let clientEmailForQuery = isTrainer ? targetEmail : myEmail
                    
                    let fetchedMessages = try await APIService.shared.getChatMessages(trainerEmail: trainerEmailForQuery, clientEmail: clientEmailForQuery)
                    self.messages = fetchedMessages
                } catch {
                    print("Failed to send message: \(error.localizedDescription)")
                }
            }
        }
}

// Sub-componentă pentru bula de mesaj
struct ChatBubbleRow: View {
    let message: ChatMessageOverviewItem
    let currentUserEmail: String
    
    // Corecție logică: dacă emailul trimis coincide cu al meu, sunt eu
    var isMe: Bool {
        if let senderEmail = message.senderEmail {
            return senderEmail == currentUserEmail
        }
        return message.senderId == "trainer1"
    }
    
    // --- CONVERSIE FUS ORAR (TIMEZONE) ---
    var localTime: String {
        let inputString = message.formattedTimestamp
        let formatter = DateFormatter()
        
        // Încercăm formatele comune pe care backend-ul (Java/Spring) le poate trimite
        let possibleFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "dd/MM/yyyy HH:mm",
            "dd-MM-yyyy HH:mm",
            "HH:mm:ss",
            "HH:mm"
        ]
        
        // Presupunem că serverul trimite ora în format UTC (Coordinated Universal Time)
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        for format in possibleFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: inputString) {
                
                // Dacă am parsat cu succes, transformăm în fusul orar local al telefonului (ex: România EEST UTC+3)
                formatter.timeZone = TimeZone.current
                
                // Afișăm doar Ora și Minutul (sau putem adăuga și ziua dacă dorim)
                if format == "HH:mm" || format == "HH:mm:ss" {
                    formatter.dateFormat = "HH:mm"
                } else {
                    formatter.dateFormat = "HH:mm" // Poți schimba în "dd MMM, HH:mm" dacă vrei să vezi și ziua
                }
                
                return formatter.string(from: date)
            }
        }
        
        // Dacă nu reușește conversia (format neașteptat din server), returnează stringul original
        return inputString
    }
    
    var body: some View {
        HStack {
            if isMe { Spacer() }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Text(message.message)
                    .padding(12)
                    .background(isMe ? Color.orange : Color(hex: "#2C2C2C"))
                    .foregroundColor(isMe ? .black : .white)
                    .cornerRadius(16)
                
                // Folosim "localTime" în loc de "message.formattedTimestamp"
                Text(localTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isMe { Spacer() }
        }
    }
}
