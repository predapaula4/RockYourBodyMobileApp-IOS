import SwiftUI
import PhotosUI

struct RegisterTrainerView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var age = ""
    @State private var gender = "M"
    @State private var countryCode = "+40"
    @State private var phoneNumber = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    let genders = ["M", "F"]
    let countryCodes = ["+40", "+1", "+44", "+49", "+33", "+34", "+39"]
    
    var body: some View {
        Form {
            Section(header: Text("Profile Photo")) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Text("Select Profile Photo").foregroundColor(.orange)
                        Spacer()
                        if let d = profileImageData, let uiImage = UIImage(data: d) {
                            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill").resizable().frame(width: 40, height: 40).foregroundColor(.gray)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { item in
                    if let item = item {
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                                await MainActor.run { self.profileImageData = compressedData }
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Account Details")) {
                TextField("Last Name", text: $lastName)
                TextField("First Name", text: $firstName)
                TextField("Email Address", text: $email).keyboardType(.emailAddress).autocapitalization(.none)
                SecureField("Password", text: $password)
            }
            
            Section(header: Text("Personal Details")) {
                TextField("Birth Date (yyyy-MM-dd)", text: $age)
                Picker("Gender", selection: $gender) { ForEach(genders, id: \.self) { Text($0) } }.pickerStyle(.segmented)
            }
            
            Section(header: Text("Phone Number")) {
                HStack {
                    Picker("", selection: $countryCode) { ForEach(countryCodes, id: \.self) { Text($0) } }.frame(width: 80)
                    TextField("Phone Number", text: $phoneNumber).keyboardType(.phonePad)
                }
            }
            
            if let err = errorMessage { Text(err).foregroundColor(.red).font(.caption) }
            
            Button(action: registerTrainer) {
                if isLoading { HStack { Spacer(); ProgressView(); Spacer() } }
                else { Text("Create Trainer Account").bold().frame(maxWidth: .infinity) }
            }
            .listRowBackground(Color.orange)
            .foregroundColor(.black)
            .disabled(isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty)
        }
        .navigationTitle("Trainer Registration")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
    
    private func registerTrainer() {
        isLoading = true
        errorMessage = nil
        
        // În Backend, "cod" va fi generat automat, deci trimitem o valoare goală sau o excludem din DTO
        let dto = TrainerFormDto(firstName: firstName, lastName: lastName, email: email, password: password, age: age.isEmpty ? "2000-01-01" : age, gender: gender, cod: "", phoneNumber: phoneNumber, fullPhoneNumber: countryCode + phoneNumber, countryCode: countryCode, profileImage: profileImageData)
        
        Task {
            do {
                try await APIService.shared.registerTrainer(trainer: dto)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = "Registration failed. Please check your data."
            }
        }
    }
}
