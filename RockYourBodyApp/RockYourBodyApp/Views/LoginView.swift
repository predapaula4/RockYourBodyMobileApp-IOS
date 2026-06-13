import SwiftUI
import GoogleSignIn // Obligatoriu pentru Google Login

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    // Stare pentru vizibilitatea parolei
    @State private var isPasswordVisible = false
    
    // Variabile de rutare (Login Clasic / Google Login)
    @State private var routeToClient = false
    @State private var routeToTrainer = false
    
    // Variabile pentru flow-ul de Google "NEW_USER"
    @State private var showRoleSelection = false
    @State private var googleEmail = ""
    @State private var googleFirstName = ""
    @State private var googleLastName = ""
    @State private var routeToRegisterGoogleClient = false
    @State private var routeToRegisterGoogleTrainer = false
    
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
                    
                    // Containerul inteligent pentru parolă
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
                    Text(errorMessage).foregroundColor(.red).font(.caption).multilineTextAlignment(.center)
                }
                
                // ---- BUTON LOGIN CLASIC ----
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
                
                // ---- BUTON GOOGLE LOGIN ----
                Button(action: executeGoogleLogin) {
                    HStack {
                        Image(systemName: "g.circle.fill") // Poți înlocui cu un logo Google din assets
                            .font(.title2)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                Spacer()
                
                // ---- RUTĂRI INVIZIBILE PENTRU DASHBOARD ----
                NavigationLink(destination: HomePageClientView(), isActive: $routeToClient) { EmptyView() }
                NavigationLink(destination: HomePageTrainerView(), isActive: $routeToTrainer) { EmptyView() }
                
                // ---- RUTĂRI PENTRU GOOGLE REGISTER FLOW ----
                // NOTĂ: Dacă RegisterClientView() acceptă parametri, trimite datele (googleEmail, etc.) aici
                NavigationLink(destination: RegisterClientView(), isActive: $routeToRegisterGoogleClient) { EmptyView() }
                NavigationLink(destination: RegisterTrainerView(), isActive: $routeToRegisterGoogleTrainer) { EmptyView() }
                
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
            // Dialogul pentru utilizatorii noi (NEW_USER)
            .confirmationDialog("Choose your role", isPresented: $showRoleSelection, titleVisibility: .visible) {
                Button("I am a Client") {
                    routeToRegisterGoogleClient = true
                }
                Button("I am a Trainer") {
                    routeToRegisterGoogleTrainer = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("We couldn't find an account for \(googleEmail). Please choose your user type to complete the registration.")
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Login Clasic
    private func executeLogin() {
        isLoading = true
        errorMessage = ""
        
        let request = LoginRequest(email: email, password: password)
        
        Task {
            do {
                let response = try await APIService.shared.loginMobile(requestData: request)
                UserDefaults.standard.set(email, forKey: "USER_EMAIL")
                
                await MainActor.run {
                    isLoading = false
                    if response.userType.lowercased() == "client" {
                        routeToClient = true
                    } else {
                        routeToTrainer = true
                    }
                }
                saveFirebaseToken(userEmail: email)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid credentials or network error."
                }
            }
        }
    }
    
    // MARK: - Google Login
    private func executeGoogleLogin() {
        guard let rootViewController = getRootViewController() else {
            errorMessage = "Could not find root view controller"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Asigură-te că se face Sign Out mai întâi, la fel ca pe Android, pentru a forța selectarea contului
        GIDSignIn.sharedInstance.signOut()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                isLoading = false
                errorMessage = "Google Sign-In cancelled or failed."
                print("Eroare Google: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user else {
                isLoading = false
                return
            }
            
            // Avem nevoie de idToken, îl preluăm folosind funcția nativă
            user.refreshTokensIfNeeded { user, error in
                guard error == nil, let user = user, let idToken = user.idToken?.tokenString else {
                    isLoading = false
                    errorMessage = "Failed to get Google idToken."
                    return
                }
                
                // Trimitem Token-ul către Backend-ul tău Spring Boot
                sendGoogleTokenToBackend(idToken: idToken)
            }
        }
    }
    
    private func sendGoogleTokenToBackend(idToken: String) {
        Task {
            do {
                let response = try await APIService.shared.googleLoginMobile(payload: ["idToken": idToken])
                
                await MainActor.run {
                    isLoading = false
                    guard let status = response["status"] as? String,
                          let fetchedEmail = response["email"] as? String else {
                        errorMessage = "Invalid response from server"
                        return
                    }
                    
                    if status == "EXISTS" {
                        // Utilizatorul există -> Îl logăm direct
                        let userType = response["userType"] as? String ?? "client"
                        UserDefaults.standard.set(fetchedEmail, forKey: "USER_EMAIL")
                        saveFirebaseToken(userEmail: fetchedEmail)
                        
                        if userType.lowercased() == "client" {
                            routeToClient = true
                        } else {
                            routeToTrainer = true
                        }
                    } else if status == "NEW_USER" {
                        // Utilizatorul e nou -> Salvăm datele și afișăm meniul pentru selecția tipului de cont
                        self.googleEmail = fetchedEmail
                        self.googleFirstName = response["firstName"] as? String ?? ""
                        self.googleLastName = response["lastName"] as? String ?? ""
                        
                        // Afișează dialogul Client/Trainer
                        self.showRoleSelection = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Backend authentication failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveFirebaseToken(userEmail: String) {
        Task { try? await APIService.shared.saveFcmToken(email: userEmail, token: "DUMMY_IOS_TOKEN") }
    }
    
    // MARK: - Helper pentru a prelua RootViewController-ul necesar pachetului Google
    private func getRootViewController() -> UIViewController? {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return screen.windows.first?.rootViewController
    }
}
