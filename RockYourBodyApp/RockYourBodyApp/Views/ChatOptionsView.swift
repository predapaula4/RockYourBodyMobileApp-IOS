import SwiftUI

struct ChatOptionsView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    @State private var trainerEmail: String = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("Contact Trainer").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView().padding(.top, 50)
            } else {
                VStack(spacing: 16) {
                    // Buton In-App Chat
                    NavigationLink(destination: ChatView(myEmail: clientEmail, targetEmail: trainerEmail, isTrainer: false)) {
                        ChatOptionCard(title: "In-App Chat", subtitle: "Talk securely inside RockYourBody", icon: "message.fill", color: .cyan)
                    }
                    
                    // Buton WhatsApp
                    Button(action: openWhatsApp) {
                        ChatOptionCard(title: "WhatsApp", subtitle: "Fast messaging via WhatsApp", icon: "phone.bubble.left.fill", color: .green)
                    }
                }
                .padding()
            }
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadTrainerEmail() }
    }
    
    private func loadTrainerEmail() {
        Task {
            do {
                trainerEmail = try await APIService.shared.getTrainerEmail(clientEmail: clientEmail)
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
    
    private func openWhatsApp() {
        Task {
            do {
                // VERIFICĂ AICI: Ai pus 'try await' în fața metodei?
                let trainerProfile = try await APIService.shared.getTrainerProfile(email: trainerEmail)
                
                let phone = trainerProfile.fullPhoneNumber ?? trainerProfile.phoneNumber ?? ""
                
                guard !phone.isEmpty else { return }
                
                let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                if let url = URL(string: "https://wa.me/\(cleanPhone)"),
                   UIApplication.shared.canOpenURL(url) {
                    // Aici nu trebuie 'await', este apel sincron
                    await UIApplication.shared.open(url)
                    // Notă: În versiunile noi de iOS, open(url) poate necesita await în anumite contexte.
                    // Dacă îți dă eroare, folosește await.
                }
            } catch {
                print("Eroare deschidere whatsapp: \(error)")
            }
        }
    }
}

struct ChatOptionCard: View {
    let title: String; let subtitle: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title).foregroundColor(color).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}
