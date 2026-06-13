import SwiftUI
import PhotosUI // Import obligatoriu pentru selectorul de poze

struct EditProfileTrainerView: View {
    @Environment(\.dismiss) var dismiss
    let trainerEmail: String
    
    @State private var fName = ""
    @State private var lName = ""
    @State private var phone = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImageBase64: String? = nil
    @State private var isLoading = true
    
    var body: some View {
        Form {
            Section(header: Text("Trainer Details").foregroundColor(.gray)) {
                // ---- SELECTORUL DE IMAGINE IMPLEMENTAT ----
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Text("Update Profile Photo").foregroundColor(.orange)
                        Spacer()
                        if let b64 = profileImageBase64, let d = Data(base64Encoded: b64), let uiImage = UIImage(data: d) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { item in
                    if let item = item {
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               // Compresie la 70% calitate pentru a corespunde perfect cu Android
                               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                                await MainActor.run {
                                    self.profileImageBase64 = compressedData.base64EncodedString()
                                }
                            }
                        }
                    }
                }
                
                TextField("First Name", text: $fName)
                TextField("Last Name", text: $lName)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
            }
            
            Button(action: saveChanges) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Save Changes").bold().frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.orange)
            .foregroundColor(.black)
        }
        .preferredColorScheme(.dark)
        .onAppear { loadData() }
    }
    
    private func loadData() {
        Task {
            let p = try? await APIService.shared.getTrainerProfile(email: trainerEmail)
            fName = p?.firstName ?? ""
            lName = p?.lastName ?? ""
            phone = p?.phoneNumber ?? ""
            profileImageBase64 = p?.profileImageBase64
            isLoading = false
        }
    }
    
    private func saveChanges() {
        isLoading = true
        let dataMap = [
            "email": trainerEmail,
            "firstName": fName,
            "lastName": lName,
            "phoneNumber": phone,
            "profileImageBase64": profileImageBase64 ?? ""
        ]
        Task {
            try? await APIService.shared.updateTrainerProfile(requestData: dataMap)
            isLoading = false
            dismiss()
        }
    }
}
