import SwiftUI

struct BodyCompositionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    @State private var weight: Float? = nil
    @State private var bodyFat: Float? = nil
    
    var leanMass: Float { (weight ?? 0) * (1.0 - ((bodyFat ?? 0) / 100.0)) }
    var boneMass: Float { leanMass * 0.04 } // Algoritmul tău din dizertație
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomHeader(title: "Body Composition", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#00E676")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#00E676"))
                            .padding(.top, 32)
                        
                        Text(weight != nil ? String(format: "%.1f kg", weight!) : "-- kg")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Grid cu detalii
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            DetailCard(title: "Body Fat", value: bodyFat != nil ? String(format: "%.1f %%", bodyFat!) : "--", icon: "percent", color: .yellow)
                            DetailCard(title: "Weight", value: weight != nil ? String(format: "%.1f kg", weight!) : "--", icon: "figure", color: .green)
                            DetailCard(title: "Lean Mass", value: weight != nil ? String(format: "%.1f kg", leanMass) : "--", icon: "dumbbell.fill", color: .cyan)
                            DetailCard(title: "Bone Mass", value: weight != nil ? String(format: "%.1f kg", boneMass) : "--", icon: "link", color: .white)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
    }
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getBodyCompositionHistory(for: date) { w, fat in
            DispatchQueue.main.async { self.weight = w; self.bodyFat = fat }
        }
    }
}
