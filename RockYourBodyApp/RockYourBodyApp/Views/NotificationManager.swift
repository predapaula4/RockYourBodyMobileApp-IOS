import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {} // Previne instanțierea multiplă
    
    // Cere utilizatorului permisiunea să îi trimiți notificări pe ecran
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permisiune de notificări acordată!")
            } else if let error = error {
                print("Eroare la cererea de permisiune pentru notificări: \(error.localizedDescription)")
            }
        }
    }
    
    // Programează reminderul de apă local în fundal (la fiecare 3 ore)
    func scheduleWaterReminder() {
        let center = UNUserNotificationCenter.current()
        
        // 1. Ștergem cererile vechi pendinte pentru a evita duplicarea alarmelor
        center.removeAllPendingNotificationRequests()
        
        // 2. Conținutul alertei
        let content = UNMutableNotificationContent()
        content.title = "Time to hydrate! 💧"
        content.body = "Don't forget to drink a glass of water to reach your daily goal."
        content.sound = .default
        
        // 3. Declanșator (Trigger): La fiecare 3 ore (3 ore * 60 min * 60 sec = 10800 secunde)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10800, repeats: true)
        
        // 4. Construirea cererii
        let request = UNNotificationRequest(identifier: "WaterReminder", content: content, trigger: trigger)
        
        // 5. Înregistrarea alertei în sistemul de operare iOS
        center.add(request) { error in
            if let error = error {
                print("Eroare la programarea notificării de apă: \(error.localizedDescription)")
            } else {
                print("Reminder de apă local programat cu succes!")
            }
        }
    }
    
    // Oprește reminderele dacă utilizatorul dorește asta sau face logout
    func cancelWaterReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
