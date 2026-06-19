import SwiftUI
import GoogleSignIn

struct HomePageTrainerView: View {
    // 1. ADĂUGAT: Variabila de environment pentru a ne putea întoarce la Login
//    @Environment(\.dismiss) private var dismiss
//    
//    @State private var trainerEmail = UserDefaults.standard.string(forKey: "USER_EMAIL") ?? ""
    @AppStorage("USER_EMAIL") private var trainerEmail: String = ""
    @AppStorage("USER_TYPE") private var userType: String = ""
    @State private var dashboardData: ClientDashboardResponse? = nil
    @State private var trainerProfileImageBase64: String? = nil
    @State private var clients: [TrainerClientItem] = []
    @State private var searchText = ""
    @State private var isLoading = true
    
    // Stări pentru Notificări
    @State private var showNotificationDialog = false
    @State private var selectedClientEmail = ""
    @State private var notificationMessage = ""
    
    // Stări pentru Insigne
    @State private var availableBadges: [BadgeResponse] = []
    @State private var showBadgeSheet = false
    
    @State private var showLogoutAlert = false
    var filteredClients: [TrainerClientItem] {
        if searchText.isEmpty { return clients }
        return clients.filter { "\($0.firstName) \($0.lastName)".localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Bara de căutare modernă
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search client...", text: $searchText)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(hex: "#2C2C2C"))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                if isLoading {
                    Spacer(); ProgressView(); Spacer()
                } else if filteredClients.isEmpty {
                    Spacer()
                    Text("No clients found.").foregroundColor(.gray)
                    Spacer()
                } else {
                    List(filteredClients, id: \.email) { client in
                        let cName = "\(client.firstName) \(client.lastName)"
                        
                        DisclosureGroup {
                            // FĂRĂ VSTACK! Lăsăm elementele direct ca rânduri de Listă pentru a nu strica click-urile
                            
                            // ---- ACȚIUNI VIZUALIZARE ----
                            NavigationLink(destination: ViewMealsTrainerView(clientEmail: client.email, clientName: cName)) {
                                ModernActionRow(title: "View Meals", icon: "fork.knife", tint: .green)
                            }
                            NavigationLink(destination: ViewExercisesTrainerView(clientEmail: client.email, clientName: cName)) {
                                ModernActionRow(title: "View Exercises", icon: "figure.run", tint: .blue)
                            }
                            NavigationLink(destination: ViewBodyMeasuresTrainerView(clientEmail: client.email, clientName: cName)) {
                                ModernActionRow(title: "View Measures", icon: "ruler.fill", tint: .purple)
                            }
                            NavigationLink(destination: ClientReportsListView(clientEmail: client.email, trainerEmail: trainerEmail, clientName: cName)) {
                                ModernActionRow(title: "View PDF Reports", icon: "doc.text.fill", tint: .red)
                            }
                            
                            // ---- ACȚIUNI ADĂUGARE & INTERACȚIUNE ----
                            NavigationLink(destination: AddMealView(clientEmail: client.email, clientName: cName)) {
                                ModernActionRow(title: "Add Meal", icon: "plus.circle.fill", tint: .green)
                            }
                            NavigationLink(destination: AddExerciseView(clientEmail: client.email, clientName: cName)) {
                                ModernActionRow(title: "Add Exercise", icon: "dumbbell.fill", tint: .blue)
                            }
                            
                            // ACȚIUNE: Acordare Insignă
                            Button(action: {
                                selectedClientEmail = client.email
                                showBadgeSheet = true
                            }) {
                                ModernActionRow(title: "Award Badge", icon: "medal.fill", tint: .yellow)
                            }
                            
                            NavigationLink(destination: ChatView(myEmail: trainerEmail, targetEmail: client.email, isTrainer: true)) {
                                ModernActionRow(title: "Chat", icon: "message.fill", tint: .cyan)
                            }
                            
                            Button(action: {
                                selectedClientEmail = client.email
                                showNotificationDialog = true
                            }) {
                                ModernActionRow(title: "Send Push Notification", icon: "bell.fill", tint: .orange)
                            }
                            
                        } label: {
                            ClientProfileHeaderView(client: client, cName: cName)
                        }
                        .listRowBackground(Color(hex: "#1E1E1E"))
                        .tint(.orange) // Culoarea săgeții de expandare
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Trainer Dashboard")
            // 2. ADĂUGAT: Ascundem săgeata de Back
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // 3. ADĂUGAT: Butonul de Logout plasat în partea stângă (Leading)
                ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: { showLogoutAlert = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Logout")
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                
                // Poza de profil rămasă în partea dreaptă (Trailing)
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MyPersonalTrainerView(trainerEmail: trainerEmail)) {
                        if let b64 = trainerProfileImageBase64,
                           let data = Data(base64Encoded: cleanBase64(b64)),
                           let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40) // Ajustat puțin dimensiunea pentru a nu deforma bara
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.orange, lineWidth: 1.5))
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .background(Color(hex: "#121212").ignoresSafeArea())
            .preferredColorScheme(.dark)
            .onAppear {
                loadClients()
                loadBadges()
                loadTrainerProfile()
                triggerUpdateAccess()
            }
            .alert("Send Notification", isPresented: $showNotificationDialog) {
                TextField("Message...", text: $notificationMessage)
                Button("Send", action: sendPushNotification)
                Button("Cancel", role: .cancel) { notificationMessage = "" }
            }
            .sheet(isPresented: $showBadgeSheet) {
                BadgeSelectionView(
                    clientEmail: selectedClientEmail,
                    badges: availableBadges,
                    isPresented: $showBadgeSheet
                )
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Log Out", role: .destructive) {
                            logoutUser()
                        }
                    } message: {
                        Text("Are you sure you want to log out?")
                    }
        
    }
    
    private func loadClients() {
        Task {
            do {
                clients = try await APIService.shared.getTrainerClients(email: trainerEmail, search: nil)
                isLoading = false
            } catch { isLoading = false }
        }
    }
    
    private func loadBadges() {
        Task {
            do {
                availableBadges = try await APIService.shared.getAllSystemBadges()
            } catch {
                print("Failed to load badges: \(error)")
            }
        }
    }
    
    private func triggerUpdateAccess() {
        let request = UpdateAccessRequest(email: trainerEmail, userType: "trainer")
        Task { try? await APIService.shared.updateLastAccess(requestData: request) }
    }
    
    private func sendPushNotification() {
        guard !notificationMessage.isEmpty else { return }
        Task {
            try? await APIService.shared.sendCustomNotification(clientEmail: selectedClientEmail, message: notificationMessage)
            notificationMessage = ""
        }
    }
    
    private func cleanBase64(_ base64String: String) -> String {
        if base64String.contains(",") {
            return String(base64String.split(separator: ",").last ?? "")
        }
        return base64String
    }
    
    private func loadTrainerProfile() {
        Task {
            if let trainerData = try? await APIService.shared.getTrainerProfile(email: trainerEmail) {
                self.trainerProfileImageBase64 = trainerData.profileImageBase64
            }
        }
    }
    
    private func logoutUser() {
        trainerEmail = ""
        userType = ""
         GIDSignIn.sharedInstance.signOut()
   }
}

// Sub-componentă pentru butoane stil iOS Settings
struct ModernActionRow: View {
    let title: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tint.opacity(0.2))
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 14, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sub-componentă pentru afișarea și selectarea insignelor
struct BadgeSelectionView: View {
    let clientEmail: String
    let badges: [BadgeResponse]
    @Binding var isPresented: Bool
    
    @State private var isAwarding = false
    
    var body: some View {
        NavigationView {
            List(badges, id: \.code) { badge in
                Button(action: { awardBadge(badgeCode: badge.code) }) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: badge.imageUrl)) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(badge.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(badge.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
                .listRowBackground(Color(hex: "#1E1E1E"))
                .disabled(isAwarding)
            }
            .listStyle(.plain)
            .navigationTitle("Award a Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(.orange)
                }
            }
            .background(Color(hex: "#121212").ignoresSafeArea())
        }
    }
    
    private func awardBadge(badgeCode: String) {
        isAwarding = true
        Task {
            do {
                try await APIService.shared.awardBadgeFromMobile(clientEmail: clientEmail, badgeCode: badgeCode)
                isAwarding = false
                isPresented = false // Închide fereastra după succes
            } catch {
                isAwarding = false
                print("Eroare la acordarea insignei: \(error)")
            }
        }
    }
}

struct ClientProfileHeaderView: View {
    let client: TrainerClientItem
    let cName: String
    
    // Stări locale pentru datele aduse din API
    @State private var streak: Int = 0
    @State private var fullPhone: String = ""
    @State private var profileImage: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. Afișarea pozei de profil
            let b64 = profileImage ?? client.profileImageBase64
            if let b64 = b64,
               let data = Data(base64Encoded: cleanBase64(b64), options: .ignoreUnknownCharacters),
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.orange.opacity(0.8), lineWidth: 1.5))
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            // 2. Afișarea Numelui, Streak-ului și Telefonului
            VStack(alignment: .leading, spacing: 4) {
                Text(cName).font(.headline).foregroundColor(.white)
                
                Text("🔥 Streak: \(streak) Days")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.orange)
                
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill").font(.caption2).foregroundColor(.gray)
                    Text(fullPhone).font(.subheadline).foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            self.fullPhone = client.phoneNumber
            loadExtraClientData()
        }
    }
    
    private func loadExtraClientData() {
        Task {
            async let profileReq = try? APIService.shared.getClientProfile(email: client.email)
            async let dashboardReq = try? APIService.shared.getClientDashboard(email: client.email)
            
            let profile = await profileReq
            let dashboard = await dashboardReq
            
            if let p = profile {
                self.fullPhone = p.fullPhoneNumber ?? client.phoneNumber
            }
            
            if let d = dashboard {
                self.streak = d.streak
                self.profileImage = d.profileImage
            }
        }
    }
    
    private func cleanBase64(_ base64String: String) -> String {
        var cleaned = base64String
        if cleaned.contains(",") {
            cleaned = String(cleaned.split(separator: ",").last ?? "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
