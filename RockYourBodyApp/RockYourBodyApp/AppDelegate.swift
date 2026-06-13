import SwiftUI
import UIKit
import UserNotifications
// import FirebaseCore
// import FirebaseMessaging

// Echivalentul MyFirebaseMessagingService.kt
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate /* , MessagingDelegate */ {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Inițializăm Firebase (decomentează după ce instalăm Firebase)
        // FirebaseApp.configure()
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
    
    // Funcția apelată când Firebase ne dă un Token nou de Push (Echivalent: onNewToken)
    /*
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token iOS: \(String(describing: fcmToken))")
        // Aici trimitem token-ul către backend dacă e nevoie
    }
    */
    
    // Funcția apelată când primim o notificare în timp ce aplicația e deschisă (Echivalent: onMessageReceived)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Notificare primită: \(userInfo)")
        
        // Afișăm notificarea pe ecran, chiar dacă suntem în aplicație
        completionHandler([[.banner, .sound]])
    }
}
