import SwiftUI
import HealthKit

struct HydrationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var totalWaterMl: Int = 0
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("Hydration Tracking").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            Image(systemName: "drop.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Hydration Today")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("\(totalWaterMl) ml")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#121212").ignoresSafeArea())
        .onAppear { loadHydrationData() }
    }
    
    private func loadHydrationData() {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    // Apple returnează în Litri, noi vrem Mililitri
                    self.totalWaterMl = Int(sum.doubleValue(for: HKUnit.literUnit(with: .milli)))
                }
            }
        }
        healthStore.execute(query)
    }
}
