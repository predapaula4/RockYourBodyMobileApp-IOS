import SwiftUI
import HealthKit

struct HeartRateView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var latestHR: Float = 0
    @State private var avgHR: Float = 0
    @State private var minHR: Float = 0
    @State private var maxHR: Float = 0
    @State private var restingHR: Float = 0
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("Heart Rate Monitor").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: CGFloat(latestHR / 220.0))
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(latestHR))")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    Text("BPM")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 30)
            
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    MetricCard(title: "Avg HR", value: "\(Int(avgHR))")
                    MetricCard(title: "Resting", value: "\(Int(restingHR))")
                }
                HStack(spacing: 20) {
                    MetricCard(title: "Min HR", value: "\(Int(minHR))")
                    MetricCard(title: "Max HR", value: "\(Int(maxHR))")
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .onAppear { loadHeartRateData() }
    }
    
    private func loadHeartRateData() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        // Query pentru Heart Rate (Min, Max, Avg, Latest)
        let hrQuery = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, _ in
            guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else { return }
            
            let values = hrSamples.map { Float($0.quantity.doubleValue(for: HKUnit(from: "count/min"))) }
            
            DispatchQueue.main.async {
                self.latestHR = values.last ?? 0
                self.minHR = values.min() ?? 0
                self.maxHR = values.max() ?? 0
                self.avgHR = values.reduce(0, +) / Float(values.count)
            }
        }
        
        // Query pentru Resting Heart Rate
        let restingQuery = HKSampleQuery(sampleType: restingType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                DispatchQueue.main.async {
                    self.restingHR = Float(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                }
            }
        }
        
        healthStore.execute(hrQuery)
        healthStore.execute(restingQuery)
    }
}

struct MetricCard: View {
    let title: String; let value: String
    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.title2).bold().foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}
