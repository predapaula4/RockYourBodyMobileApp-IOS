import SwiftUI
import UIKit
import UserNotifications
import FirebaseCore // <-- Am decomentat asta pentru a inițializa Firebase

// Echivalentul MyFirebaseMessagingService.kt
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate /* , MessagingDelegate */ {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Inițializăm Firebase aici, o singură dată
        FirebaseApp.configure()
        // Messaging.messaging().delegate = self
        
        // 2. Cerem permisiunea utilizatorului pentru a afișa notificări pe ecran
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("Permisiune Notificări: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        return true
    }
    
    // Funcția apelată când primim o notificare în timp ce aplicația e deschisă
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Notificare primită: \(userInfo)")
        
        // Afișăm notificarea pe ecran, chiar dacă suntem în aplicație
        completionHandler([[.banner, .sound]])
    }
}
