import SwiftUI

struct MyPersonalTrainerView: View {
    @Environment(\.dismiss) var dismiss
    let trainerEmail: String
    
    @State private var profile: TrainerProfileResponse? = nil
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("Trainer Profile").font(.headline).foregroundColor(.white)
                Spacer()
                NavigationLink(destination: EditProfileTrainerView(trainerEmail: trainerEmail)) {
                    Image(systemName: "pencil").foregroundColor(.orange).font(.title3)
                }
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            
            ScrollView {
                if isLoading {
                    ProgressView().padding(.top, 100)
                } else if let p = profile {
                    VStack(spacing: 20) {
                        VStack {
                            if let b64 = p.profileImageBase64, let data = Data(base64Encoded: b64), let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFill().frame(width: 120, height: 120).clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill").resizable().frame(width: 120, height: 120).foregroundColor(.gray)
                            }
                            Text("\(p.firstName) \(p.lastName)").font(.title).bold().foregroundColor(.white).padding(.top, 8)
                            Text(p.email).foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ProfileDataRow(title: "Phone", value: p.fullPhoneNumber ?? p.phoneNumber ?? "N/A")
                            ProfileDataRow(title: "Gender", value: p.gender ?? "N/A")
                            ProfileDataRow(title: "Age / DOB", value: p.age ?? "N/A")
                            ProfileDataRow(title: "Trainer Code", value: p.cod)
                        }
                        .padding()
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        Button(action: { showDeleteAlert = true }) {
                            Text("Delete Account")
                                .bold().frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadProfile() }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you absolutely sure you want to delete your trainer account? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { deleteAccount() },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func loadProfile() {
        Task {
            do {
                profile = try await APIService.shared.getTrainerProfile(email: trainerEmail)
                isLoading = false
            } catch { isLoading = false }
        }
    }
    
    private func deleteAccount() {
        Task {
            try? await APIService.shared.deleteTrainer(email: trainerEmail)
            UserDefaults.standard.removeObject(forKey: "USER_EMAIL")
            // Aici s-ar face triggerul de navigare globală spre Logout, sau apelăm o logică din App struct
        }
    }
}
