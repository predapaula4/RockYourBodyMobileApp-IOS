import SwiftUI

struct MyPersonalClientView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var profile: ClientProfileResponse? = nil
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("My Profile").font(.headline).foregroundColor(.white)
                Spacer()
                NavigationLink(destination: EditProfileClientView(clientEmail: clientEmail)) {
                    Image(systemName: "pencil").foregroundColor(.cyan).font(.title3)
                }
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            
            ScrollView {
                if isLoading {
                    ProgressView().padding(.top, 100)
                } else if let p = profile {
                    VStack(spacing: 20) {
                        // Imagine Profile & Nume
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
                        
                        // Detalii
                        VStack(spacing: 16) {
                            ProfileDataRow(title: "Phone", value: p.fullPhoneNumber ?? p.phoneNumber)
                            ProfileDataRow(title: "Gender", value: p.gender)
                            ProfileDataRow(title: "Age", value: "\(p.age) years")
                            ProfileDataRow(title: "Weight", value: "\(p.weight) kg")
                            ProfileDataRow(title: "Height", value: "\(p.height) cm")
                            ProfileDataRow(title: "Activity", value: p.activityLevel ?? "N/A")
                            ProfileDataRow(title: "Goal", value: p.goal ?? "N/A")
                            ProfileDataRow(title: "Trainer Code", value: p.trainerCode ?? "No Trainer")
                        }
                        .padding()
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadProfile() }
    }
    
    private func loadProfile() {
        Task {
            do {
                profile = try await APIService.shared.getClientProfileDetails(email: clientEmail)
                isLoading = false
            } catch { isLoading = false }
        }
    }
}

struct ProfileDataRow: View {
    let title: String; let value: String
    var body: some View {
        HStack {
            Text(title).foregroundColor(.gray)
            Spacer()
            Text(value).bold().foregroundColor(.white)
        }
        Divider().background(Color.gray.opacity(0.3))
    }
}
