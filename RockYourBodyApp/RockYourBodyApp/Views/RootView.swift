//import SwiftUI
//
//struct RootView: View {
//    // Verificăm dacă utilizatorul e deja logat
//    @State private var isLoggedIn = UserDefaults.standard.bool(forKey: "IS_LOGGED_IN")
//    @State private var userType = UserDefaults.standard.string(forKey: "USER_TYPE") ?? "client"
//
//    var body: some View {
//        Group {
//            if isLoggedIn {
//                if userType == "trainer" {
//                    HomePageTrainerView()
//                } else {
//                    HomePageClientView()
//                }
//            } else {
//                LoginView()
//            }
//        }
//        .onAppear {
//            // Ascultăm schimbările dacă este nevoie
//            self.isLoggedIn = UserDefaults.standard.bool(forKey: "IS_LOGGED_IN")
//        }
//    }
//}
