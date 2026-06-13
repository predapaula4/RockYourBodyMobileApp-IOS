import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    // NOU: Stare pentru vizibilitatea parolei
    @State private var isPasswordVisible = false
    
    // Variabile de rutare
    @State private var routeToClient = false
    @State private var routeToTrainer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                Text("Rock Your Body")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.orange)
                    .padding(.bottom, 20)
                
                VStack(spacing: 16) {
                    TextField("Email Address", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    // NOU: Containerul inteligent pentru parolă
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .foregroundColor(.white)
                        } else {
                            SecureField("Password", text: $password)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(hex: "#1E1E1E"))
                    .cornerRadius(12)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).font(.caption)
                }
                
                Button(action: executeLogin) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Spacer()
                
                // Link-uri invizibile pentru rutare
                NavigationLink(destination: HomePageClientView(), isActive: $routeToClient) { EmptyView() }
                NavigationLink(destination: HomePageTrainerView(), isActive: $routeToTrainer) { EmptyView() }
                
                VStack(spacing: 10) {
                    NavigationLink(destination: RegisterClientView()) {
                        Text("Don't have an account? Sign up as a Client")
                            .font(.footnote)
                            .foregroundColor(.cyan)
                    }
                    NavigationLink(destination: RegisterTrainerView()) {
                        Text("Are you a fitness coach? Register here")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(hex: "#121212").ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
        // Ascunde săgeata nativă dacă ajungi aici prin "Back" de pe alt ecran
        .navigationBarBackButtonHidden(true)
    }
    
    private func executeLogin() {
        isLoading = true
        errorMessage = ""
        
        let request = LoginRequest(email: email, password: password)
        
        Task {
            do {
                let response = try await APIService.shared.loginMobile(requestData: request)
                
                // Salvăm utilizatorul în sistem
                UserDefaults.standard.set(email, forKey: "USER_EMAIL")
//                UserDefaults.standard.set(true, forKey: "IS_LOGGED_IN") // Flag explicit
//                UserDefaults.standard.synchronize()
                // Opțional: Dacă backend-ul ar returna JWT, s-ar salva aici:
                // UserDefaults.standard.set(response.token, forKey: "JWT_TOKEN")
                
                isLoading = false
                
                if response.userType.lowercased() == "client" {
                    routeToClient = true
                } else {
                    routeToTrainer = true
                }
                
                // Salvăm Token-ul Firebase pentru Push Notifications
                saveFirebaseToken(userEmail: email)
                
            } catch {
                isLoading = false
                errorMessage = "Invalid credentials or network error."
            }
        }
    }
    
    private func saveFirebaseToken(userEmail: String) {
        // În Swift, un token real se ia din Messaging.messaging().fcmToken
        // Pentru test, trimitem un dummy token sau lăsăm metoda pregătită
        Task { try? await APIService.shared.saveFcmToken(email: userEmail, token: "DUMMY_IOS_TOKEN") }
    }
}
