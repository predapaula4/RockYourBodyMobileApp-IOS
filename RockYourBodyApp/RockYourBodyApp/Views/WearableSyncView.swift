import SwiftUI

struct WearableSyncView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    let trainerEmail: String
    
    @ObservedObject private var hkManager = HealthKitManager.shared
    @State private var isSyncing = false
    @State private var syncMessage: String? = nil
    
    // --- Stări pentru Export PDF ---
    @State private var showExportOptions = false
    @State private var showDatePickerSheet = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isExporting = false
    @State private var exportMessage: String? = nil
    
    var leanMass: Float { (hkManager.weight ?? 0) * (1.0 - ((hkManager.bodyFat ?? 0) / 100.0)) }
    var boneMass: Float { leanMass * 0.04 }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Card Pași & Calorii
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(hkManager.todaySteps) steps").font(.system(size: 32, weight: .bold)).foregroundColor(Color(hex: "#50F4B5"))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total burned (BMR+Active)").font(.caption).foregroundColor(.gray)
                            Text("\(Int(hkManager.totalCalories)) kcal").font(.headline).foregroundColor(Color(hex: "#FF5252"))
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text("Active Calories").font(.caption).foregroundColor(.gray)
                            Text("\(Int(hkManager.activeCalories)) kcal").font(.headline).foregroundColor(Color(hex: "#F09819"))
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    ProgressView(value: min(Double(hkManager.todaySteps), 6000), total: 6000)
                        .tint(Color(hex: "#50F4A1"))
                }
                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)
                
                // Card Smart Scale (Greutate, Grăsime)
                VStack(spacing: 16) {
                    HStack {
                        ScaleMetricView(title: "Weight", value: hkManager.weight != nil ? String(format: "%.1f kg", hkManager.weight!) : "-- kg")
                        ScaleMetricView(title: "Body Fat", value: hkManager.bodyFat != nil ? String(format: "%.1f %%", hkManager.bodyFat!) : "-- %")
                    }
                    HStack {
                        ScaleMetricView(title: "Lean Mass", value: hkManager.weight != nil ? String(format: "%.1f kg", leanMass) : "-- kg")
                        ScaleMetricView(title: "Bone Mass", value: hkManager.weight != nil ? String(format: "%.1f kg", boneMass) : "-- kg")
                    }
                }
                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)
                
                // NOU: Card Vitals (Oxigen, VO2 Max, Tensiune, Resting HR)
                VStack(spacing: 16) {
                    HStack {
                        ScaleMetricView(title: "Blood Oxygen", value: hkManager.oxygenSaturation != nil ? String(format: "%.1f %%", hkManager.oxygenSaturation!) : "-- %")
                        ScaleMetricView(title: "VO2 Max", value: hkManager.vo2Max != nil ? String(format: "%.1f", hkManager.vo2Max!) : "--")
                    }
                    HStack {
                        ScaleMetricView(title: "Resting HR", value: hkManager.restingHeartRate > 0 ? "\(Int(hkManager.restingHeartRate)) bpm" : "-- bpm")
                        ScaleMetricView(title: "Blood Pressure", value: (hkManager.systolicBP != nil && hkManager.diastolicBP != nil) ? "\(Int(hkManager.systolicBP!))/\(Int(hkManager.diastolicBP!))" : "--/--")
                    }
                }
                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)

                // Grid Somn / Heart Rate
                HStack(spacing: 8) {
                    VStack(alignment: .leading) {
                        Text("Sleep").font(.caption).foregroundColor(.gray)
                        Text("\(hkManager.sleepMinutes / 60)h \(hkManager.sleepMinutes % 60)m").font(.title3).bold().foregroundColor(Color(hex: "#8C66FF"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding().background(Color(hex: "#1E1E1E")).cornerRadius(20)
                    
                    VStack(alignment: .leading) {
                        Text("Avg Heart Rate").font(.caption).foregroundColor(.gray)
                        Text(hkManager.avgHeartRate > 0 ? "\(Int(hkManager.avgHeartRate)) bpm" : "-- bpm").font(.title3).bold().foregroundColor(Color(hex: "#FF5252"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding().background(Color(hex: "#1E1E1E")).cornerRadius(20)
                }.padding(.horizontal)
                
                // Card Performance
                VStack(spacing: 16) {
                    HStack {
                        PerformanceMetricView(title: "Distance", value: String(format: "%.2f km", hkManager.distanceMeters / 1000.0))
                        PerformanceMetricView(title: "Floors", value: "\(Int(hkManager.floorsClimbed))")
                    }
                    HStack {
                        PerformanceMetricView(title: "Active Mins", value: "\(hkManager.activityIntensityMinutes) min")
                        PerformanceMetricView(title: "Water", value: "\(hkManager.waterMl) ml")
                    }
                }
                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)
                
                // NOU: Card Advanced Performance (Viteză, Cadență, Elevație)
                                VStack(spacing: 16) {
                                    HStack {
                                        PerformanceMetricView(title: "Avg Speed", value: hkManager.avgSpeed != nil ? String(format: "%.1f m/s", hkManager.avgSpeed!) : "-- m/s")
                                        PerformanceMetricView(title: "Step Cadence", value: hkManager.avgCadence != nil ? "\(Int(hkManager.avgCadence!)) rpm" : "-- rpm")
                                    }
                                    HStack {
                                        PerformanceMetricView(title: "Elevation", value: "-- m") // HealthKit măsoară asta prin Floors, dar poți lăsa placeholder dacă ai nevoie în Sync
                                        PerformanceMetricView(title: "Exercises", value: "\(hkManager.exerciseSessionsCount) sessions")
                                    }
                                }
                                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)
                                
                                // NOU: Card Cycling & Power
                                VStack(spacing: 16) {
                                    HStack {
                                        PerformanceMetricView(title: "Power", value: hkManager.powerWatts != nil ? "\(Int(hkManager.powerWatts!)) W" : "-- W")
                                        PerformanceMetricView(title: "Cycle Cadence", value: hkManager.avgCadence != nil ? "\(Int(hkManager.avgCadence!)) rpm" : "-- rpm") // iOS folosește un singur tip de cadență generală pe ceas
                                    }
                                }
                                .padding().background(Color(hex: "#1E1E1E")).cornerRadius(24).padding(.horizontal)
                
                // ---- BUTOANE SYNC & PDF EXPORT ----
                VStack(spacing: 12) {
                    if let msg = syncMessage {
                        Text(msg).font(.subheadline).foregroundColor(msg.contains("failed") ? .red : .green)
                    }
                    
                    Button(action: performSync) {
                        if isSyncing {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding().background(Color.orange).cornerRadius(16)
                        } else {
                            Text("Sync Extracted Data to Server")
                                .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.orange).cornerRadius(16)
                        }
                    }.disabled(isSyncing)
                    
                    if let expMsg = exportMessage {
                        Text(expMsg).font(.subheadline).foregroundColor(expMsg.contains("Error") ? .red : .green)
                    }
                    
                    Button(action: { showExportOptions = true }) {
                        if isExporting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(16)
                        } else {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Generate & Send PDF Report")
                            }
                            .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(16)
                        }
                    }.disabled(isExporting)
                }
                .padding()
            }
            .padding(.top, 16)
        }
        .navigationTitle("Wearable Activity")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .onAppear {
            hkManager.requestAuthorization { authorized in
                if authorized { hkManager.fetchAllData() }
            }
        }
        .confirmationDialog("What should the PDF report contain?", isPresented: $showExportOptions, titleVisibility: .visible) {
            Button("Today only") { exportData(type: .today) }
            Button("Select a custom date range") { showDatePickerSheet = true }
            Button("All data (Full history)") { exportData(type: .all) }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showDatePickerSheet) {
            NavigationView {
                Form {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    Button(action: {
                        showDatePickerSheet = false
                        exportData(type: .custom)
                    }) {
                        Text("Generate Report")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical)
                }
                .navigationTitle("Select report interval")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { showDatePickerSheet = false }.foregroundColor(.red)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func performSync() {
        isSyncing = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let request = DailyActivitySyncRequest(
            email: clientEmail, date: formatter.string(from: Date()), steps: hkManager.todaySteps,
            caloriesBurned: hkManager.totalCalories, activeCalories: hkManager.activeCalories,
            distanceMeters: hkManager.distanceMeters, floorsClimbed: hkManager.floorsClimbed,
            sleepMinutes: hkManager.sleepMinutes, avgHeartRate: hkManager.avgHeartRate,
            maxHeartRate: hkManager.maxHeartRate, minHeartRate: hkManager.minHeartRate,
            latestHeartRate: hkManager.latestHeartRate, restingHeartRate: hkManager.restingHeartRate,
            waterMl: hkManager.waterMl, bodyFat: hkManager.bodyFat, weight: hkManager.weight,
            oxygenSaturation: hkManager.oxygenSaturation, systolicBP: hkManager.systolicBP,
            diastolicBP: hkManager.diastolicBP, activityIntensityMinutes: hkManager.activityIntensityMinutes,
            avgSpeed: hkManager.avgSpeed, avgCadence: hkManager.avgCadence, vo2Max: hkManager.vo2Max,
            elevationGained: 0, wheelchairPushes: nil, powerWatts: hkManager.powerWatts,
            exerciseSessionsCount: hkManager.exerciseSessionsCount, totalSleepMinutes: hkManager.sleepMinutes,
            deepSleepMin: hkManager.deepSleepMin, remSleepMin: hkManager.remSleepMin,
            lightSleepMin: hkManager.lightSleepMin, awakeMin: hkManager.awakeMin
        )
        
        Task {
            do {
                try await APIService.shared.syncWearableData(requestData: request)
                isSyncing = false
                syncMessage = "Sync successful!"
            } catch {
                isSyncing = false
                syncMessage = "Sync failed: network error."
            }
        }
    }
    
    enum ExportType { case today, custom, all }

    private func exportData(type: ExportType) {
        isExporting = true
        exportMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var startStr: String? = nil
        var endStr: String? = nil
        
        switch type {
        case .today:
            let today = formatter.string(from: Date())
            startStr = today
            endStr = today
        case .custom:
            startStr = formatter.string(from: startDate)
            endStr = formatter.string(from: endDate)
        case .all:
            startStr = nil
            endStr = nil
        }
        
        Task {
            do {
                try await APIService.shared.exportToTrainer(clientEmail: clientEmail, trainerEmail: trainerEmail, startDate: startStr, endDate: endStr)
                isExporting = false
                exportMessage = "Report sent successfully to your trainer!"
            } catch {
                isExporting = false
                exportMessage = "Error: No data available for the selected period."
            }
        }
    }
}

struct ScaleMetricView: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.headline).foregroundColor(Color(hex: "#00E676"))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PerformanceMetricView: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.headline).foregroundColor(.white)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
