import SwiftUI

struct StepsChartView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    // Stări pentru date
    @State private var steps: Int = 0
    @State private var calories: Double = 0.0
    @State private var distanceKm: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Activity History", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#FF8000")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        Text(Calendar.current.isDateInToday(selectedDate) ? "Activity Today" : "Activity: \(formatDate(selectedDate))")
                            .font(.title2).bold().foregroundColor(.white).padding(.top, 24)
                        
                        // Progress Circular Pași
                        ZStack {
                            Circle().stroke(Color(hex: "#FF8000").opacity(0.2), lineWidth: 16).frame(width: 220, height: 220)
                            Circle()
                                .trim(from: 0.0, to: min(CGFloat(Double(steps) / 10000.0), 1.0))
                                .stroke(Color(hex: "#FF8000"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 220, height: 220)
                                .rotationEffect(Angle(degrees: -90))
                            
                            VStack {
                                Image(systemName: "figure.walk").font(.title).foregroundColor(.white)
                                Text("\(steps)").font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                                Text("steps").font(.subheadline).foregroundColor(.gray)
                            }
                        }
                        
                        // Detalii Calorii & Distanță
                        HStack(spacing: 16) {
                            DetailCard(title: "Calories", value: "\(Int(calories)) kcal", icon: "flame.fill", color: .red)
                            DetailCard(title: "Distance", value: String(format: "%.2f km", distanceKm), icon: "location.fill", color: .blue)
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
        HealthKitManager.shared.getStepsHistory(for: date) { stps, cals, dist in
            DispatchQueue.main.async {
                self.steps = stps
                self.calories = cals
                self.distanceKm = dist
            }
        }
    }
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd MMM"; return f.string(from: date)
    }
}
