import SwiftUI
import PhotosUI

struct EditProfileClientView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var profile: ClientProfileResponse? = nil
    @State private var fName = ""
    @State private var lName = ""
    @State private var phone = ""
    @State private var gender = "M"
    @State private var weight = ""
    @State private var height = ""
    @State private var actLevel = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImageBase64: String? = nil
    @State private var isLoading = true
    
    var body: some View {
        Form {
            Section(header: Text("Profile Details").foregroundColor(.gray)) {
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Text("Update Photo").foregroundColor(.cyan)
                        Spacer()
                        if let b64 = profileImageBase64, let d = Data(base64Encoded: b64), let uiImage = UIImage(data: d) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle").font(.title)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { item in
                    if let item = item {
                        print("📸 [LOG]: S-a selectat o nouă imagine din galerie.")
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                                
                                let base64String = compressedData.base64EncodedString()
                                print("✅ [LOG]: Imaginea a fost procesată și convertită în Base64 cu succes!")
                                print("📊 [LOG]: Dimensiunea string-ului Base64: \(base64String.count) caractere.")
                                
                                await MainActor.run {
                                    self.profileImageBase64 = base64String
                                }
                            } else {
                                print("❌ [LOG EROARE]: Eroare la extragerea sau conversia imaginii din PhotosPicker.")
                            }
                        }
                    }
                }
                
                TextField("First Name", text: $fName)
                TextField("Last Name", text: $lName)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
                TextField("Gender (M/F)", text: $gender)
                TextField("Weight (kg)", text: $weight)
                TextField("Height (cm)", text: $height)
                TextField("Activity Level", text: $actLevel)
            }
            
            Button(action: saveChanges) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Save Changes").bold().frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.cyan)
            .foregroundColor(.black)
        }
        .navigationTitle("Edit Profile")
        .preferredColorScheme(.dark)
        .onAppear { loadData() }
    }
    
    private func loadData() {
        print("🔄 [LOG]: Se încarcă datele profilului pentru clientul: \(clientEmail)")
        Task {
            if let p = try? await APIService.shared.getClientProfileDetails(email: clientEmail) {
                print("✅ [LOG]: Datele au fost încărcate cu succes de la server.")
                await MainActor.run {
                    profile = p
                    fName = p.firstName
                    lName = p.lastName
                    phone = p.phoneNumber
                    gender = p.gender
                    weight = "\(p.weight)"
                    height = "\(p.height)"
                    actLevel = p.activityLevel ?? ""
                    profileImageBase64 = p.profileImageBase64
                    isLoading = false
                }
            } else {
                print("❌ [LOG EROARE]: Nu s-au putut încărca datele de profil (posibil request-ul a returnat nil sau a eșuat).")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func saveChanges() {
        guard let p = profile else {
            print("⚠️ [LOG]: Salvarea a fost anulată deoarece 'profile' este nil.")
            return
        }
        isLoading = true
        print("💾 [LOG]: Se pregătesc datele pentru salvare...")
        
        var dataMap: [String: Any] = [
            "email": p.email,
            "firstName": fName,
            "lastName": lName,
            "phoneNumber": phone,
            "gender": gender,
            "weight": Float(weight) ?? p.weight,
            "height": Float(height) ?? p.height,
            "activityLevel": actLevel,
            "profileImageBase64": profileImageBase64 ?? "",
            "age": p.age
        ]
        
        if let trainerCode = p.trainerCode { dataMap["trainerCode"] = trainerCode }
        if let goal = p.goal { dataMap["goal"] = goal }
        if let goalDesc = p.goalDescription { dataMap["goalDescription"] = goalDesc }
        if let birthDate = p.birthDate { dataMap["birthDate"] = birthDate }
        
        // Logăm cheile și tipurile trimise, dar ascundem conținutul uriaș al Base64-ului din consolă
        var logMap = dataMap
        logMap["profileImageBase64"] = (profileImageBase64 != nil && !(profileImageBase64!.isEmpty)) ? "String prezent (dimensiune: \(profileImageBase64!.count))" : "String gol/nil"
        print("📦 [LOG]: Pachetul (dataMap) pregătit pentru trimitere: \n\(logMap)")
        
        Task {
            do {
                print("🚀 [LOG]: Se execută apelul către APIService.shared.updateClientProfile...")
                try await APIService.shared.updateClientProfile(requestData: dataMap)
                print("✅ [LOG]: Apelul către API s-a finalizat cu succes! Se închide ecranul.")
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("🛑 [LOG EROARE FATALĂ]: Apelul API a eșuat!")
                print("🛑 [LOG DETALII EROARE]: \(error)")
                print("🛑 [LOG DESCRIERE LOCALIZATĂ]: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
