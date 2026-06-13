import SwiftUI

struct ChatOptionsView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    @State private var trainerEmail: String = ""
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 24) {
            
            if isLoading {
                ProgressView().padding(.top, 50)
            } else {
                VStack(spacing: 16) {
                    // Buton In-App Chat
                    NavigationLink(destination: ChatView(myEmail: clientEmail, targetEmail: trainerEmail, isTrainer: false)) {
                        ChatOptionCard(title: "In-App Chat",
                                       subtitle: "Talk securely inside RockYourBody",
                                       icon: "message.fill",
                                       color: .cyan,
                                       isSystemIcon: true)
                    }
                    
                    // Buton WhatsApp cu sigla custom (ai nevoie de imaginea whatsapp_logo in Assets)
                    Button(action: openWhatsApp) {
                        ChatOptionCard(title: "WhatsApp",
                                       subtitle: "Fast messaging via WhatsApp",
                                       icon: "whatsapp_logo", // Numele pozei din Assets
                                       color: .green,
                                       isSystemIcon: false)
                    }
                }
                .padding()
            }
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        // ADĂUGĂM BARA NATIVĂ AICI:
        .navigationTitle("Contact Trainer")
        .navigationBarTitleDisplayMode(.inline)
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
                let trainerProfile = try await APIService.shared.getTrainerProfile(email: trainerEmail)
                let phone = trainerProfile.fullPhoneNumber ?? trainerProfile.phoneNumber ?? ""
                guard !phone.isEmpty else { return }
                let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                if let url = URL(string: "https://wa.me/\(cleanPhone)") {
                    if await UIApplication.shared.canOpenURL(url) {
                        await UIApplication.shared.open(url)
                    }
                }
            } catch {
                print("Eroare deschidere whatsapp: \(error)")
            }
        }
    }
}

// CARD MODIFICAT PENTRU A SUPORTA ICOANE SYSTEM SAU IMAGINI CUSTOM
struct ChatOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSystemIcon: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if isSystemIcon {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 40)
            } else {
                // Afișează imaginea "whatsapp_logo" din Assets
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
            }
            
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
