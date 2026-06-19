import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    // Metrici curente
    @Published var todaySteps: Int = 0
    @Published var activeCalories: Float = 0
    @Published var basalCalories: Float = 0
    var totalCalories: Float { activeCalories + basalCalories }
    @Published var distanceMeters: Float = 0
    @Published var floorsClimbed: Double = 0
    
    @Published var sleepMinutes: Int = 0
    @Published var deepSleepMin: Int = 0
    @Published var remSleepMin: Int = 0
    @Published var lightSleepMin: Int = 0
    @Published var awakeMin: Int = 0
    
    @Published var avgHeartRate: Float = 0
    @Published var minHeartRate: Float = 0
    @Published var maxHeartRate: Float = 0
    @Published var latestHeartRate: Float = 0
    @Published var restingHeartRate: Float = 0
    
    @Published var waterMl: Int = 0
    @Published var bodyFat: Float? = nil
    @Published var weight: Float? = nil
    @Published var oxygenSaturation: Float? = nil
    @Published var systolicBP: Float? = nil
    @Published var diastolicBP: Float? = nil
    
    @Published var activityIntensityMinutes: Int = 0
    @Published var avgSpeed: Float? = nil
    @Published var avgCadence: Float? = nil
    @Published var vo2Max: Float? = nil
    @Published var powerWatts: Float? = nil
    @Published var exerciseSessionsCount: Int = 0
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // Definim absolut toate metricile pe care vrem să le citim
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
                HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
            ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success)
            }
        }
    }
    
    // Funcție unificată pentru a trage toate datele
    func fetchAllData(for date: Date = Date()) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        fetchSum(for: .stepCount, unit: HKUnit.count(), predicate: predicate) { self.todaySteps = Int($0) }
        fetchSum(for: .activeEnergyBurned, unit: HKUnit.kilocalorie(), predicate: predicate) { self.activeCalories = Float($0) }
        fetchSum(for: .basalEnergyBurned, unit: HKUnit.kilocalorie(), predicate: predicate) { self.basalCalories = Float($0) }
        fetchSum(for: .distanceWalkingRunning, unit: HKUnit.meter(), predicate: predicate) { self.distanceMeters = Float($0) }
        fetchSum(for: .flightsClimbed, unit: HKUnit.count(), predicate: predicate) { self.floorsClimbed = $0 }
        fetchSum(for: .appleExerciseTime, unit: HKUnit.minute(), predicate: predicate) { self.activityIntensityMinutes = Int($0) }
        fetchSum(for: .dietaryWater, unit: HKUnit.literUnit(with: .milli), predicate: predicate) { self.waterMl = Int($0) }
        
        fetchLatest(for: .bodyMass, unit: HKUnit.gramUnit(with: .kilo), predicate: predicate) { self.weight = Float($0) }
        fetchLatest(for: .bodyFatPercentage, unit: HKUnit.percent(), predicate: predicate) { self.bodyFat = Float($0 * 100) }
        fetchLatest(for: .oxygenSaturation, unit: HKUnit.percent(), predicate: predicate) { self.oxygenSaturation = Float($0 * 100) }
        fetchLatest(for: .vo2Max, unit: HKUnit(from: "ml/kg*min"), predicate: predicate) { self.vo2Max = Float($0) }
        fetchLatest(for: .restingHeartRate, unit: HKUnit(from: "count/min"), predicate: predicate) { self.restingHeartRate = Float($0) }
        
        fetchHeartRateStats(predicate: predicate)
        fetchSleepData(predicate: predicate)
        fetchLatest(for: .walkingSpeed, unit: HKUnit.meter().unitDivided(by: HKUnit.second()), predicate: predicate) { self.avgSpeed = Float($0) }
                fetchLatest(for: .cyclingPower, unit: HKUnit.watt(), predicate: predicate) { self.powerWatts = Float($0) }
                
                // Numărul de antrenamente (Workouts)
                let workoutQuery = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                    DispatchQueue.main.async { self.exerciseSessionsCount = samples?.count ?? 0 }
                }
                healthStore.execute(workoutQuery)
    }
    
    private func fetchSum(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
            DispatchQueue.main.async { completion(sum) }
        }
        healthStore.execute(query)
    }
    
    private func fetchSum2(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date, completion: @escaping (Double) -> Void) {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                return completion(0.0)
            }
            
            // Aici rezolvăm eroarea: transformăm data în predicate înainte să o trimitem către HealthKit
            let predicate = createPredicate(for: date)
            
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                completion(sum)
            }
            healthStore.execute(query)
        }
    private func fetchLatest(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate, completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                DispatchQueue.main.async { completion(sample.quantity.doubleValue(for: unit)) }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRateStats(predicate: NSPredicate) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMax, .discreteMin]) { _, result, _ in
            let unit = HKUnit(from: "count/min")
            DispatchQueue.main.async {
                self.avgHeartRate = Float(result?.averageQuantity()?.doubleValue(for: unit) ?? 0)
                self.minHeartRate = Float(result?.minimumQuantity()?.doubleValue(for: unit) ?? 0)
                self.maxHeartRate = Float(result?.maximumQuantity()?.doubleValue(for: unit) ?? 0)
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchSleepData(predicate: NSPredicate) {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            var total = 0, deep = 0, rem = 0, light = 0, awake = 0
            
            for sample in samples {
                let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += minutes; total += minutes
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += minutes; total += minutes
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue: light += minutes; total += minutes // "Light" in HealthKit is Core
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: light += minutes; total += minutes
                case HKCategoryValueSleepAnalysis.awake.rawValue: awake += minutes
                default: break
                }
            }
            DispatchQueue.main.async {
                self.sleepMinutes = total
                self.deepSleepMin = deep
                self.remSleepMin = rem
                self.lightSleepMin = light
                self.awakeMin = awake
            }
        }
        healthStore.execute(query)
    }
    
    // Adaugă această metodă în HealthKitManager.swift pentru a suporta interfața de Oxigen
    func fetchOxygenSaturation(for date: Date) async throws -> Double {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Oxygen Saturation tip indisponibil"])
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: oxygenType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let sample = samples?.first as? HKQuantitySample {
                    // Saturația de oxigen în HealthKit vine ca valoare zecimală (ex: 0.98 pentru 98%)
                    let percentageValue = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                    continuation.resume(returning: percentageValue)
                } else {
                    // Dacă nu există date pentru ziua respectivă, returnăm 0.0
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func createPredicate(for date: Date) -> NSPredicate {
            let start = Calendar.current.startOfDay(for: date)
            // Setăm finalul zilei la 23:59:59
            let end = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start)!
            return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        }
    
    // 1. Pași, Calorii, Distanță
    func getStepsHistory(for date: Date, completion: @escaping (Int, Double, Double) -> Void) {
        fetchSum2(for: .stepCount, unit: .count(), date: date) { steps in
            self.fetchSum2(for: .activeEnergyBurned, unit: .kilocalorie(), date: date) { activeCals in
                self.fetchSum2(for: .basalEnergyBurned, unit: .kilocalorie(), date: date) { basalCals in
                    self.fetchSum2(for: .distanceWalkingRunning, unit: .meter(), date: date) { distance in
                        completion(Int(steps), activeCals + basalCals, distance / 1000.0)
                    }
                }
            }
        }
    }

    // 2. Apă (Fetch & Save)
    func getWaterHistory(for date: Date, completion: @escaping (Int) -> Void) {
        fetchSum2(for: .dietaryWater, unit: .literUnit(with: .milli), date: date) { ml in
            completion(Int(ml))
        }
    }

    func addWater(amountMl: Int, for date: Date, completion: @escaping (Bool) -> Void) {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return completion(false) }
        
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(amountMl))
        
        // Dacă adaugă pentru azi, punem ora curentă. Dacă adaugă pentru istoric, punem ora 12:00
        var saveDate = Date()
        if !Calendar.current.isDateInToday(date) {
            saveDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        }
        
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: saveDate, end: saveDate)
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // 3. Somn Detaliat
    func getSleepHistory(for date: Date, completion: @escaping (Int, Int, Int, Int, Int, String) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let start = Calendar.current.date(byAdding: .hour, value: -18, to: Calendar.current.startOfDay(for: date))!
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date))!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                completion(0, 0, 0, 0, 0, "--:-- - --:--"); return
            }
            
            var total = 0, deep = 0, rem = 0, light = 0, awake = 0
            let firstStart = sleepSamples.first!.startDate
            let lastEnd = sleepSamples.last!.endDate
            
            for sample in sleepSamples {
                let minutes = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
                if #available(iOS 16.0, *) {
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: deep += minutes; total += minutes
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue: rem += minutes; total += minutes
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue: light += minutes; total += minutes
                    case HKCategoryValueSleepAnalysis.awake.rawValue: awake += minutes
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: total += minutes
                    default: break
                    }
                } else {
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue { total += minutes }
                }
            }
            
            let formatter = DateFormatter(); formatter.dateFormat = "hh:mm a"
            let timeString = "\(formatter.string(from: firstStart)) - \(formatter.string(from: lastEnd))"
            
            completion(total, deep, rem, light, awake, timeString)
        }
        healthStore.execute(query)
    }
    
    // 4. Body Composition History
        func getBodyCompositionHistory(for date: Date, completion: @escaping (Float?, Float?) -> Void) {
            let predicate = createPredicate(for: date)
            fetchLatest(for: .bodyMass, unit: HKUnit.gramUnit(with: .kilo), predicate: predicate) { weight in
                self.fetchLatest(for: .bodyFatPercentage, unit: HKUnit.percent(), predicate: predicate) { fat in
                    completion(weight > 0 ? Float(weight) : nil, fat > 0 ? Float(fat * 100) : nil)
                }
            }
        }
        
        // 5. Blood Pressure History
        func getBloodPressureHistory(for date: Date, completion: @escaping (Float?, Float?) -> Void) {
            let predicate = createPredicate(for: date)
            fetchLatest(for: .bloodPressureSystolic, unit: .millimeterOfMercury(), predicate: predicate) { sys in
                self.fetchLatest(for: .bloodPressureDiastolic, unit: .millimeterOfMercury(), predicate: predicate) { dia in
                    completion(sys > 0 ? Float(sys) : nil, dia > 0 ? Float(dia) : nil)
                }
            }
        }

        // 6. Advanced Metrics History
        func getAdvancedMetricHistory(type: AdvancedMetricType, date: Date, completion: @escaping (Double) -> Void) {
            let predicate = createPredicate(for: date)
            
            switch type {
            case .vo2Max:
                fetchLatest(for: .vo2Max, unit: HKUnit(from: "ml/kg*min"), predicate: predicate, completion: completion)
            case .power:
                fetchLatest(for: .cyclingPower, unit: HKUnit.watt(), predicate: predicate, completion: completion)
            case .cyclingCadence:
                // Observație: iOS nu are un identificator nativ de Cycling Cadence în QuantityType ușor accesibil ca pașii.
                // Returnăm 0.0 sau trebuie extras din Workout-uri de tip cycling.
                completion(0.0)
            case .exercise:
                let workoutQuery = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                    completion(Double(samples?.count ?? 0))
                }
                healthStore.execute(workoutQuery)
            }
        }
    
    // 7. Performance Metrics History (Distance, Floors, Speed, etc.)
        func getPerformanceMetricHistory(type: PerformanceMetricType, date: Date, completion: @escaping (Double) -> Void) {
            let predicate = createPredicate(for: date)
            
            switch type {
            case .distance:
                fetchSum2(for: .distanceWalkingRunning, unit: .meter(), date: date) { val in completion(val / 1000.0) } // Transformăm în km
            case .floors:
                fetchSum2(for: .flightsClimbed, unit: .count(), date: date, completion: completion)
            case .speed:
                fetchLatest(for: .walkingSpeed, unit: HKUnit.meter().unitDivided(by: .second()), predicate: predicate, completion: completion)
            case .elevation:
                // HealthKit nu contorizează elevația în afara workout-urilor mereu, așa că o aproximăm (1 etaj = ~3 metri)
                fetchSum2(for: .flightsClimbed, unit: .count(), date: date) { floors in completion(floors * 3.0) }
            case .intensity:
                fetchSum2(for: .appleExerciseTime, unit: .minute(), date: date, completion: completion)
            case .cadence:
                // Cadența medie necesită un query complex pe workout-uri, momentan returnăm 0 ca fallback
                completion(0.0)
            }
        }
    
    // 7. Heart Rate History (Latest, Avg, Min, Max, Resting)
        func getHeartRateHistory(for date: Date, completion: @escaping (Float, Float, Float, Float, Float) -> Void) {
            let predicate = createPredicate(for: date)
            guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
                  let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
                completion(0, 0, 0, 0, 0)
                return
            }
            
            var latest: Float = 0
            var avg: Float = 0
            var min: Float = 0
            var max: Float = 0
            var resting: Float = 0
            
            // Folosim un DispatchGroup pentru a rula 3 interogări în paralel și a le aștepta pe toate
            let dispatchGroup = DispatchGroup()
            
            // 1. Statistici: Avg, Min, Max
            dispatchGroup.enter()
            let statsQuery = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMax, .discreteMin]) { _, result, _ in
                let unit = HKUnit(from: "count/min")
                if let result = result {
                    avg = Float(result.averageQuantity()?.doubleValue(for: unit) ?? 0)
                    min = Float(result.minimumQuantity()?.doubleValue(for: unit) ?? 0)
                    max = Float(result.maximumQuantity()?.doubleValue(for: unit) ?? 0)
                }
                dispatchGroup.leave()
            }
            healthStore.execute(statsQuery)
            
            // 2. Latest HR pentru acea zi
            dispatchGroup.enter()
            let latestQuery = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    latest = Float(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                }
                dispatchGroup.leave()
            }
            healthStore.execute(latestQuery)
            
            // 3. Resting HR
            dispatchGroup.enter()
            let restingQuery = HKSampleQuery(sampleType: restingType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    resting = Float(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                }
                dispatchGroup.leave()
            }
            healthStore.execute(restingQuery)
            
            // Returnăm toate datele doar când s-au terminat toate cele 3 interogări
            dispatchGroup.notify(queue: .main) {
                completion(latest, avg, min, max, resting)
            }
        }
}
