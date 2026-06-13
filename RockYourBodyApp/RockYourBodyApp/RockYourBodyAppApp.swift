import SwiftUI
import FirebaseCore // <-- Adăugat pentru inițializarea Firebase
import GoogleSignIn // <-- Adăugat pentru Google Login

@main
struct RockYourBodyAppApp: App {
    // 2. Conectăm AppDelegate-ul de mai sus la ciclul de viață SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LoginView()
                // 3. Aici prindem momentul când browser-ul ne întoarce în aplicație după logare
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                // 4. Configurăm Google Sign-In folosind Client ID-ul din Firebase
                .onAppear {
                    setupGoogleSignIn()
                }
        }
    }
    
    private func setupGoogleSignIn() {
            // Extragem CLIENT_ID-ul pentru iOS automat din Firebase
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            
            // AICI E SECRETUL: Adăugăm Web Client ID-ul, exact ca în Android!
            let serverClientID = "1065768828965-h507f8ergvmr1397b5cpg1l9pavqdrld.apps.googleusercontent.com"
            
            // Configurăm GIDConfiguration cu ambele ID-uri
            let config = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
            GIDSignIn.sharedInstance.configuration = config
        }
}
