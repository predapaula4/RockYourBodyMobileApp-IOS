import SwiftUI
import FirebaseCore
import GoogleSignIn
import BackgroundTasks

@main
struct RockYourBodyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @AppStorage("USER_EMAIL") private var userEmail: String = ""
    @AppStorage("USER_TYPE") private var userType: String = ""
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        
        BackgroundSyncManager.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            if !userEmail.isEmpty {
                NavigationView {
                    if userType == "client" {
                        HomePageClientView()
                    } else {
                        HomePageTrainerView()
                    }
                }
                .navigationViewStyle(.stack)
            } else {
                LoginView()
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .onAppear {
                        setupGoogleSignIn()
                    }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background && !userEmail.isEmpty && userType == "client" {
                BackgroundSyncManager.shared.scheduleAppRefresh()
            }
        }
    }
    
    private func setupGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let serverClientID = "1065768828965-h507f8ergvmr1397b5cpg1l9pavqdrld.apps.googleusercontent.com"
        let config = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
        GIDSignIn.sharedInstance.configuration = config
    }
}

// MARK: - Clasă Dedicată pentru Background Tasks

class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()
    
    let syncTaskIdentifier = "com.rockyourbody.sync"
    
    private init() {}
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: syncTaskIdentifier, using: nil) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            self.handleBackgroundSync(task: appRefreshTask)
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: syncTaskIdentifier)

        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Nu am putut programa task-ul de fundal: \(error)")
        }
    }
    
    private func handleBackgroundSync(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        task.expirationHandler = {
            // Aici putem opri task-urile de rețea dacă nu s-au terminat
        }
        
        Task {
            do {
                let savedEmail = UserDefaults.standard.string(forKey: "USER_EMAIL") ?? ""
                guard !savedEmail.isEmpty else {
                    task.setTaskCompleted(success: false)
                    return
                }
                
                let requestData = await generateSyncRequestFromHealthKit(email: savedEmail)
                try await APIService.shared.syncWearableData(requestData: requestData)
                
                task.setTaskCompleted(success: true)
            } catch {
                print("Eroare la sync pe fundal: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func generateSyncRequestFromHealthKit(email: String) async -> DailyActivitySyncRequest {
        let hkManager = HealthKitManager.shared
        hkManager.fetchAllData()
        
        // Așteptăm 2 secunde ca HealthKitManager să populeze variabilele
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return DailyActivitySyncRequest(
            email: email,
            date: formatter.string(from: Date()),
            steps: hkManager.todaySteps,
            caloriesBurned: hkManager.totalCalories,
            activeCalories: hkManager.activeCalories,
            distanceMeters: hkManager.distanceMeters,
            floorsClimbed: hkManager.floorsClimbed,
            sleepMinutes: hkManager.sleepMinutes,
            avgHeartRate: hkManager.avgHeartRate,
            maxHeartRate: hkManager.maxHeartRate,
            minHeartRate: hkManager.minHeartRate,
            latestHeartRate: hkManager.latestHeartRate,
            restingHeartRate: hkManager.restingHeartRate,
            waterMl: hkManager.waterMl,
            bodyFat: hkManager.bodyFat,
            weight: hkManager.weight,
            oxygenSaturation: hkManager.oxygenSaturation,
            systolicBP: hkManager.systolicBP,
            diastolicBP: hkManager.diastolicBP,
            activityIntensityMinutes: hkManager.activityIntensityMinutes,
            avgSpeed: hkManager.avgSpeed,
            avgCadence: hkManager.avgCadence,
            vo2Max: hkManager.vo2Max,
            elevationGained: 0,
            wheelchairPushes: nil,
            powerWatts: hkManager.powerWatts,
            exerciseSessionsCount: hkManager.exerciseSessionsCount,
            totalSleepMinutes: hkManager.sleepMinutes,
            deepSleepMin: hkManager.deepSleepMin,
            remSleepMin: hkManager.remSleepMin,
            lightSleepMin: hkManager.lightSleepMin,
            awakeMin: hkManager.awakeMin
        )
    }
}
