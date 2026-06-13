import SwiftUI
import PhotosUI

// ÎNLOCUIEȘTE EditProfileClientActivity.kt
struct EditProfileClientView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var profile: ClientProfileResponse? = nil
    @State private var fName = ""; @State private var lName = ""
    @State private var phone = ""; @State private var gender = "M"
    @State private var weight = ""; @State private var height = ""
    @State private var actLevel = ""; @State private var tCode = ""
    
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
                            Image(uiImage: uiImage).resizable().frame(width: 50, height: 50).clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle").font(.title)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                            profileImageBase64 = img.jpegData(compressionQuality: 0.7)?.base64EncodedString()
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
                TextField("Trainer Code", text: $tCode)
            }
            
            Button(action: saveChanges) {
                if isLoading { ProgressView() } else { Text("Save Changes").bold().frame(maxWidth: .infinity) }
            }.listRowBackground(Color.cyan).foregroundColor(.black)
        }
        .navigationTitle("Edit Profile")
        .preferredColorScheme(.dark)
        .onAppear { loadData() }
    }
    
    private func loadData() {
        Task {
            do {
                let p = try await APIService.shared.getClientProfileDetails(email: clientEmail)
                profile = p
                fName = p.firstName; lName = p.lastName; phone = p.phoneNumber; gender = p.gender
                weight = "\(p.weight)"; height = "\(p.height)"; actLevel = p.activityLevel ?? ""; tCode = p.trainerCode ?? ""
                profileImageBase64 = p.profileImageBase64
                isLoading = false
            } catch { isLoading = false }
        }
    }
    
    private func saveChanges() {
        guard let p = profile else { return }
        isLoading = true
        let updatedProfile = ClientProfileResponse(
            firstName: fName, lastName: lName, gender: gender, email: p.email, fullPhoneNumber: nil,
            phoneNumber: phone, weight: Float(weight) ?? p.weight, height: Float(height) ?? p.height,
            birthDate: p.birthDate, activityLevel: actLevel, trainerCode: tCode,
            goalDescription: p.goalDescription, goal: p.goal, profileImageBase64: profileImageBase64, age: p.age
        )
        Task {
            try? await APIService.shared.updateClientProfile(profile: updatedProfile)
            isLoading = false; dismiss()
        }
    }
}
