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
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
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
}
