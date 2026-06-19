import SwiftUI

struct HeartRateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    // Stări pentru date
    @State private var latestHR: Float = 0
    @State private var avgHR: Float = 0
    @State private var minHR: Float = 0
    @State private var maxHR: Float = 0
    @State private var restingHR: Float = 0
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea() // Același fundal uniform
            
            VStack(spacing: 0) {
                CustomHeader(title: "Heart Rate History", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#FF5252")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        Text(Calendar.current.isDateInToday(selectedDate) ? "Heart Rate Today" : "Heart Rate: \(formatDate(selectedDate))")
                            .font(.title2).bold().foregroundColor(.white).padding(.top, 24)
                        
                        // Circular Progress pentru Latest HR
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "#FF5252").opacity(0.2), lineWidth: 16)
                                .frame(width: 220, height: 220)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(latestHR / 220.0, 1.0)))
                                .stroke(Color(hex: "#FF5252"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 220, height: 220)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: latestHR)
                            
                            VStack {
                                Image(systemName: "heart.fill").font(.title).foregroundColor(Color(hex: "#FF5252"))
                                Text("\(Int(latestHR))")
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("BPM")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Metric Cards (Avg, Resting, Min, Max) așezate în Grid
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                DetailCard(title: "Avg HR", value: "\(Int(avgHR)) bpm", icon: "waveform.path.ecg", color: .orange)
                                DetailCard(title: "Resting", value: "\(Int(restingHR)) bpm", icon: "bed.double.fill", color: .blue)
                            }
                            HStack(spacing: 16) {
                                DetailCard(title: "Min HR", value: "\(Int(minHR)) bpm", icon: "arrow.down.heart.fill", color: .green)
                                DetailCard(title: "Max HR", value: "\(Int(maxHR)) bpm", icon: "arrow.up.heart.fill", color: .red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
    }
    
    // MARK: - Logică
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getHeartRateHistory(for: date) { latest, avg, min, max, resting in
            DispatchQueue.main.async {
                self.latestHR = latest
                self.avgHR = avg
                self.minHR = min
                self.maxHR = max
                self.restingHR = resting
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd MMM"; return f.string(from: date)
    }
}
